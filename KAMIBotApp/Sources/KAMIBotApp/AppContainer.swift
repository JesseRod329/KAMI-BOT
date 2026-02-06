import AudioPipeline
import CoreAgent
import Foundation
import ModelRuntime
import VisionPipeline

@MainActor
struct AppContainer {
    let agent: BMOAgent

    init(config: AgentConfig = AgentConfig()) {
        let wakeWord = PorcupineWakeWordService(keyword: config.wakeWord)
        let stt = WhisperSpeechToTextService()
        let tts = AVSpeechSynthesizerService()

        let modelStore = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("models", isDirectory: true)
        let llm = MLXLLMService(modelID: config.llmModelID, modelStore: modelStore)

        let vision = SnapshotVisionService(enabled: config.visionEnabled)

        self.agent = BMOAgent(
            config: config,
            wakeWordService: wakeWord,
            sttService: stt,
            ttsService: tts,
            llmService: llm,
            visionService: vision
        )
    }
}
