import Foundation
import AVFoundation
import XCTest
@testable import AudioPipeline

private final class MockPermissionProvider: @unchecked Sendable, MicrophonePermissionProviding {
    var current: MicrophonePermissionState
    var requested: MicrophonePermissionState

    init(current: MicrophonePermissionState, requested: MicrophonePermissionState) {
        self.current = current
        self.requested = requested
    }

    func currentPermission() -> MicrophonePermissionState {
        current
    }

    func requestPermission() async -> MicrophonePermissionState {
        requested
    }
}

final class AudioPipelineTests: XCTestCase {
    func testWakeWordDebounceSuppressesDuplicates() async {
        let service = PorcupineWakeWordService(keyword: "BMO", debounceSeconds: 1.0)
        try? await service.start()

        let stream = await service.events()
        let task = Task<[String], Never> {
            var output: [String] = []
            for await event in stream {
                output.append(event.keyword)
                if output.count == 2 {
                    break
                }
            }
            return output
        }

        let t0 = Date()
        await service.emitDetection(now: t0)
        await service.emitDetection(now: t0.addingTimeInterval(0.2))
        await service.emitDetection(now: t0.addingTimeInterval(1.2))

        let result = await task.value
        XCTAssertEqual(result.count, 2)
    }

    func testSTTTimeoutAndRetryPolicy() async {
        let service = WhisperSpeechToTextService()

        do {
            _ = try await service.transcribeWithRetry(timeout: 0.05, retries: 1)
            XCTFail("Expected maxRetriesExceeded")
        } catch AudioPipelineError.maxRetriesExceeded {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        await service.enqueueMockTranscription("hello bmo")
        do {
            let transcription = try await service.transcribeWithRetry(timeout: 0.2, retries: 1)
            XCTAssertEqual(transcription, "hello bmo")
        } catch {
            XCTFail("Unexpected retry failure: \(error)")
        }
    }

    func testAudioStartupCoordinatorRejectsDeniedPermission() async {
        let provider = MockPermissionProvider(current: .denied, requested: .denied)
        let coordinator = AudioStartupCoordinator(permissionProvider: provider)

        do {
            try await coordinator.prepareAudioInput()
            XCTFail("Expected microphoneDenied error")
        } catch AudioPipelineError.microphoneDenied {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAudioStartupCoordinatorRequestsPermissionWhenUndetermined() async {
        let provider = MockPermissionProvider(current: .undetermined, requested: .authorized)
        let coordinator = AudioStartupCoordinator(permissionProvider: provider)

        do {
            try await coordinator.prepareAudioInput()
        } catch {
            XCTFail("Expected permission flow to succeed: \(error)")
        }
    }

    @MainActor
    func testTTSSpeakInterruptsActiveUtterance() async {
        let synth = MockSpeechSynthesizer(initiallySpeaking: true)
        let service = AVSpeechSynthesizerService(synthesizer: synth)

        do {
            try await service.speak("First interruption test")
        } catch {
            XCTFail("Unexpected TTS error: \(error)")
        }

        XCTAssertEqual(synth.stopCallCount, 1)
        XCTAssertEqual(service.interruptionCount, 1)
        XCTAssertEqual(synth.speakCallCount, 1)
    }

    @MainActor
    func testTTSStopCancelsSpeech() async {
        let synth = MockSpeechSynthesizer(initiallySpeaking: true)
        let service = AVSpeechSynthesizerService(synthesizer: synth)
        await service.stop()
        XCTAssertEqual(synth.stopCallCount, 1)
        XCTAssertFalse(synth.isSpeaking)
    }
}

@MainActor
private final class MockSpeechSynthesizer: SpeechSynthesizing {
    var isSpeaking: Bool
    private(set) var stopCallCount = 0
    private(set) var speakCallCount = 0

    init(initiallySpeaking: Bool) {
        self.isSpeaking = initiallySpeaking
    }

    func speak(_ utterance: AVSpeechUtterance) {
        speakCallCount += 1
        isSpeaking = true
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        stopCallCount += 1
        isSpeaking = false
        return true
    }
}
