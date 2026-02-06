import CoreAgent
import Foundation

public enum VisionPipelineError: Error, Equatable {
    case disabled
    case captureUnavailable
}

public actor SnapshotVisionService: VisionService {
    private let enabled: Bool
    private var queuedSnapshot: VisionContext?

    public init(enabled: Bool = false) {
        self.enabled = enabled
    }

    public func queueSnapshotSummary(_ summary: String) {
        queuedSnapshot = VisionContext(summary: summary)
    }

    public func captureSnapshotDescription() async throws -> VisionContext {
        guard enabled else {
            throw VisionPipelineError.disabled
        }
        if let queuedSnapshot {
            self.queuedSnapshot = nil
            return queuedSnapshot
        }
        throw VisionPipelineError.captureUnavailable
    }
}
