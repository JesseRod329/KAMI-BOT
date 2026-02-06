import AudioPipeline
import CoreAgent
import Foundation
import ModelRuntime
import VisionPipeline

@MainActor
struct AppContainer {
    let agent: BMOAgent
    let audioStartupCoordinator: AudioStartupCoordinator
    let modelStartupCoordinator: ModelStartupCoordinator

    init(config: AgentConfig = AgentConfig()) {
        let wakeWord = PorcupineWakeWordService(keyword: config.wakeWord)
        let stt = WhisperSpeechToTextService()
        let tts = AVSpeechSynthesizerService()
        let permissionProvider = SystemMicrophonePermissionProvider()

        let modelStore = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("models", isDirectory: true)
        let llm = MLXLLMService(modelID: config.llmModelID, modelStore: modelStore)
        let modelDownloader = ModelDownloader(baseDirectory: modelStore)
        let modelDescriptor = Self.resolveModelDescriptor(for: config)
        self.modelStartupCoordinator = ModelStartupCoordinator(
            downloader: modelDownloader,
            descriptor: modelDescriptor,
            llmService: llm
        )

        let vision = SnapshotVisionService(enabled: config.visionEnabled)
        self.audioStartupCoordinator = AudioStartupCoordinator(permissionProvider: permissionProvider)

        self.agent = BMOAgent(
            config: config,
            wakeWordService: wakeWord,
            sttService: stt,
            ttsService: tts,
            llmService: llm,
            visionService: vision
        )
    }

    private static func resolveModelDescriptor(for config: AgentConfig) -> ModelDescriptor {
        let env = ProcessInfo.processInfo.environment
        if let urlString = env["KAMI_BOT_MODEL_URL"],
           let url = URL(string: urlString),
           let sha = env["KAMI_BOT_MODEL_SHA256"],
           !sha.isEmpty {
            return ModelDescriptor(
                id: config.llmModelID,
                url: url,
                sha256: sha,
                license: env["KAMI_BOT_MODEL_LICENSE"] ?? "Custom"
            )
        }

        return ModelDescriptor(
            id: config.llmModelID,
            url: ModelCatalog.llama31_8B4bit.url,
            sha256: ModelCatalog.llama31_8B4bit.sha256,
            license: ModelCatalog.llama31_8B4bit.license
        )
    }
}
