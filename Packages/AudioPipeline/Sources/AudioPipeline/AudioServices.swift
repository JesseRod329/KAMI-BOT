import AVFoundation
import CoreAgent
import Foundation

public enum AudioPipelineError: Error, Equatable {
    case timeout
    case maxRetriesExceeded
    case microphoneDenied
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

public final class MicrophonePermissionManager: @unchecked Sendable {
    public init() {}

    public func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public func hasPermission() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
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
public final class AVSpeechSynthesizerService: @unchecked Sendable, TextToSpeechService {
    private let synthesizer: AVSpeechSynthesizer

    public init() {
        self.synthesizer = AVSpeechSynthesizer()
    }

    public func speak(_ text: String) async throws {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.42
        synthesize(utterance)

        // Keep this async call cooperative for testability.
        try await Task.sleep(nanoseconds: 120_000_000)
    }

    public func stop() async {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func synthesize(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }
}
