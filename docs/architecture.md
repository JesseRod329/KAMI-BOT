# KAMI BOT Architecture

## Core Types

```swift
enum BMOState: Sendable {
    case idle
    case listening
    case thinking
    case speaking
    case error
}

enum FaceExpression: String, Sendable {
    case happy
    case neutral
    case curious
    case excited
    case squint
    case speaking
}
```

```swift
struct AgentConfig: Codable, Sendable {
    var wakeWord: String
    var llmModelID: String
    var visionModelID: String
    var sttTimeoutSeconds: Double
    var llmTimeoutSeconds: Double
    var telemetryEnabled: Bool
}
```

## Service Protocols

```swift
protocol WakeWordService
protocol SpeechToTextService
protocol TextToSpeechService
protocol LLMService
protocol VisionService
```

## Agent API

```swift
actor BMOAgent {
    func start() async
    func stop() async
    func handleWakeWordEvent() async
    func handleUserUtterance(_ utterance: String) async
    func speak(_ text: String) async
}
```

## UI Model

```swift
@MainActor @Observable final class BMOViewModel
```

The view model consumes `AsyncStream<AgentEvent>` from `BMOAgent`.

## Data Flow

1. Wake word event arrives.
2. Agent switches `idle -> listening` and captures utterance.
3. Agent routes prompt (text vs vision) then enters `thinking`.
4. LLM response is generated.
5. Agent enters `speaking`, emits face changes, and plays TTS.
6. Agent returns to `idle`.

## UI and Windowing

- `GlassSurface` provides Tahoe-first liquid-style panels with material fallback.
- `BMOFaceView` uses `matchedGeometryEffect` for expression transitions.
- `FloatingWindowStyler` configures a borderless, transparent, always-on-top desktop companion window.
