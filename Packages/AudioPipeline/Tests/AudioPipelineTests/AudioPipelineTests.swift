import Foundation
import XCTest
@testable import AudioPipeline

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
}
