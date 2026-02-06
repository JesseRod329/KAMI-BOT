import Foundation
import XCTest
@testable import ModelRuntime

final class ModelRuntimeTests: XCTestCase {
    func testModelNotFound() async {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kami-model-tests-\(UUID().uuidString)")
        let service = MLXLLMService(modelID: "missing-model", modelStore: tmp)

        do {
            _ = try await service.generateResponse(prompt: "hello", systemPrompt: "sys", context: nil)
            XCTFail("Expected modelNotFound")
        } catch ModelRuntimeError.modelNotFound(let id) {
            XCTAssertEqual(id, "missing-model")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDownloadFailure() async {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kami-download-tests-\(UUID().uuidString)")
        let downloader = ModelDownloader(baseDirectory: tmp)

        let descriptor = ModelDescriptor(
            id: "llama-3.1-8b-4bit",
            url: URL(string: "https://invalid.invalid/not-found.bin")!,
            sha256: "deadbeef",
            license: "custom"
        )

        do {
            _ = try await downloader.ensureModelAvailable(descriptor)
            XCTFail("Expected downloadFailed")
        } catch ModelRuntimeError.downloadFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
