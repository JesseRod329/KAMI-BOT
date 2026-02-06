import CoreAgent
import CryptoKit
import Foundation

public struct ModelDescriptor: Sendable, Codable {
    public var id: String
    public var url: URL
    public var sha256: String
    public var license: String

    public init(id: String, url: URL, sha256: String, license: String) {
        self.id = id
        self.url = url
        self.sha256 = sha256
        self.license = license
    }
}

public enum ModelRuntimeError: Error, Equatable {
    case modelNotFound(String)
    case downloadFailed(String)
    case hashMismatch(expected: String, got: String)
}

public actor ModelDownloader {
    public let baseDirectory: URL

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    public func ensureModelAvailable(_ descriptor: ModelDescriptor) async throws -> URL {
        let destination = baseDirectory.appendingPathComponent(descriptor.id)

        if FileManager.default.fileExists(atPath: destination.path()) {
            return destination
        }

        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        do {
            let (data, _) = try await URLSession.shared.data(from: descriptor.url)
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard digest == descriptor.sha256 else {
                throw ModelRuntimeError.hashMismatch(expected: descriptor.sha256, got: digest)
            }
            try data.write(to: destination)
            return destination
        } catch let error as ModelRuntimeError {
            throw error
        } catch {
            throw ModelRuntimeError.downloadFailed(error.localizedDescription)
        }
    }
}

public actor MLXLLMService: LLMService {
    private let modelID: String
    private let modelStore: URL
    private(set) var loadedModelPath: URL?

    public init(modelID: String, modelStore: URL) {
        self.modelID = modelID
        self.modelStore = modelStore
    }

    public func loadIfNeeded() throws {
        let candidate = modelStore.appendingPathComponent(modelID)
        guard FileManager.default.fileExists(atPath: candidate.path()) else {
            throw ModelRuntimeError.modelNotFound(modelID)
        }
        loadedModelPath = candidate
    }

    public func generateResponse(
        prompt: String,
        systemPrompt: String,
        context: VisionContext?
    ) async throws -> String {
        if loadedModelPath == nil {
            try loadIfNeeded()
        }

        let prefix = "[BMO]"
        if let context {
            return "\(prefix) I can see \(context.summary). You said: \(prompt)"
        }
        return "\(prefix) You said: \(prompt)"
    }
}
