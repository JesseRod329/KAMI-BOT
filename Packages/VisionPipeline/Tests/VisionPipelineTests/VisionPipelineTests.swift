import XCTest
@testable import VisionPipeline

final class VisionPipelineTests: XCTestCase {
    func testVisionFeatureFlag() async {
        let disabled = SnapshotVisionService(enabled: false)
        do {
            _ = try await disabled.captureSnapshotDescription()
            XCTFail("Expected disabled error")
        } catch VisionPipelineError.disabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let enabled = SnapshotVisionService(enabled: true)
        await enabled.queueSnapshotSummary("A monitor and a cup")
        do {
            let context = try await enabled.captureSnapshotDescription()
            XCTAssertEqual(context.summary, "A monitor and a cup")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
