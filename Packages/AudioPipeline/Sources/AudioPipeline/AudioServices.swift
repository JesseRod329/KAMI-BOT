import AVFoundation
import CoreAgent
import Foundation

public enum AudioPipelineError: Error, Equatable {
    case timeout
    case maxRetriesExceeded
    case microphoneDenied
}

public enum MicrophonePermissionState: Sendable, Equatable {
    case authorized
    case denied
    case restricted
    case undetermined
}

public protocol MicrophonePermissionProviding: Sendable {
    func currentPermission() -> MicrophonePermissionState
    func requestPermission() async -> MicrophonePermissionState
}

public actor PorcupineWakeWordService: WakeWordService {
    private let keyword: String
    private let debounceSeconds: TimeInterval
    private var isRunning = false
    private var lastDetection: Date?
    private let stream: AsyncStream<WakeWordEvent>
    private let continuation: AsyncStream<WakeWordEvent>.Continuation

    public init(keyword: String, debounceSeconds: TimeInterval = 0.8) {
        self.keyword = keyword
        self.debounceSeconds = debounceSeconds

        var localContinuation: AsyncStream<WakeWordEvent>.Continuation?
        self.stream = AsyncStream<WakeWordEvent> { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation!
    }

    public func start() async throws {
        isRunning = true
    }

    public func stop() async {
        isRunning = false
    }

    public func events() async -> AsyncStream<WakeWordEvent> {
        stream
    }

    public func emitDetection(now: Date = Date()) {
        guard isRunning else {
            return
        }

        if let lastDetection, now.timeIntervalSince(lastDetection) < debounceSeconds {
            return
        }

        lastDetection = now
        continuation.yield(WakeWordEvent(keyword: keyword, detectedAt: now))
    }
}

public final class SystemMicrophonePermissionProvider: @unchecked Sendable, MicrophonePermissionProviding {
    public init() {}

    public func currentPermission() -> MicrophonePermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .undetermined
        @unknown default:
            .undetermined
        }
    }

    public func requestPermission() async -> MicrophonePermissionState {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted ? .authorized : .denied)
            }
        }
    }
}

public actor AudioStartupCoordinator {
    private let permissionProvider: MicrophonePermissionProviding

    public init(permissionProvider: MicrophonePermissionProviding) {
        self.permissionProvider = permissionProvider
    }

    public func prepareAudioInput() async throws {
        let current = permissionProvider.currentPermission()
        switch current {
        case .authorized:
            return
        case .undetermined:
            let requested = await permissionProvider.requestPermission()
            guard requested == .authorized else {
                throw AudioPipelineError.microphoneDenied
            }
        case .denied, .restricted:
            throw AudioPipelineError.microphoneDenied
        }
    }
}

public actor WhisperSpeechToTextService: SpeechToTextService {
    private var mockQueue: [String]

    public init(initialMockQueue: [String] = []) {
        self.mockQueue = initialMockQueue
    }

    public func enqueueMockTranscription(_ value: String) {
        mockQueue.append(value)
    }

    public func transcribeNextUtterance(timeout: TimeInterval) async throws -> String {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !mockQueue.isEmpty {
                return mockQueue.removeFirst()
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw AudioPipelineError.timeout
    }

    public func transcribeWithRetry(timeout: TimeInterval, retries: Int) async throws -> String {
        var attempts = 0
        while attempts <= retries {
            do {
                return try await transcribeNextUtterance(timeout: timeout)
            } catch AudioPipelineError.timeout {
                attempts += 1
            }
        }
        throw AudioPipelineError.maxRetriesExceeded
    }
}

@MainActor
protocol SpeechSynthesizing: AnyObject {
    var isSpeaking: Bool { get }
    func speak(_ utterance: AVSpeechUtterance)
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
}

@MainActor
final class SystemSpeechSynthesizerAdapter: SpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()

    var isSpeaking: Bool { synthesizer.isSpeaking }

    func speak(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        synthesizer.stopSpeaking(at: boundary)
    }
}

@MainActor
public final class AVSpeechSynthesizerService: @unchecked Sendable, TextToSpeechService {
    private let synthesizer: SpeechSynthesizing
    public private(set) var interruptionCount = 0

    public init() {
        self.synthesizer = SystemSpeechSynthesizerAdapter()
    }

    init(synthesizer: SpeechSynthesizing) {
        self.synthesizer = synthesizer
    }

    public func speak(_ text: String) async throws {
        if synthesizer.isSpeaking {
            _ = synthesizer.stopSpeaking(at: .immediate)
            interruptionCount += 1
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.12
        utterance.postUtteranceDelay = 0.02
        synthesizer.speak(utterance)

        // Keep this async call cooperative for testability.
        try await Task.sleep(nanoseconds: 120_000_000)
    }

    public func stop() async {
        _ = synthesizer.stopSpeaking(at: .immediate)
    }
}
