import CoreAgent
import Observation

@MainActor
@Observable
final class BMOViewModel {
    private let agent: BMOAgent
    private var streamTask: Task<Void, Never>?

    var state: BMOState = .idle
    var expression: FaceExpression = .happy
    var transcript: [String] = []

    init(agent: BMOAgent) {
        self.agent = agent
    }

    func start() {
        streamTask = Task {
            await agent.start()
            for await event in agent.eventStream() {
                switch event {
                case .stateChanged(let state):
                    self.state = state
                case .faceChanged(let expression):
                    self.expression = expression
                case .heardUtterance(let utterance):
                    transcript.append("You: \(utterance)")
                case .generatedResponse(let response):
                    transcript.append("BMO: \(response)")
                case .error(let message):
                    transcript.append("Error: \(message)")
                }
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        Task {
            await agent.stop()
        }
    }
}
