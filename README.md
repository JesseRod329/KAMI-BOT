# KAMI BOT

KAMI BOT is a native macOS desktop companion inspired by expressive character interfaces and built for Apple Silicon.

The project is designed as an open-source, privacy-first assistant:
- Local wake-word detection and voice pipeline
- Local LLM runtime via MLX-oriented interfaces
- Tahoe-first glass-style UI with compatibility fallback
- No telemetry by default

## Status

This repository is in active bootstrap and foundation development.

## Scope

- v1: Voice companion loop (wake word -> STT -> LLM -> TTS)
- v1.1: On-demand snapshot vision pipeline

## Architecture

The repository is organized as a macOS app plus local Swift packages:

- `KAMIBotApp/`: SwiftUI app shell, windowing, settings, view model
- `Packages/CoreAgent/`: agent state machine and domain protocols
- `Packages/AudioPipeline/`: wake word, audio capture, STT, TTS integrations
- `Packages/ModelRuntime/`: model lifecycle, downloader, and LLM runtime adapters
- `Packages/UIComponents/`: face rendering and glass-style UI components
- `Packages/VisionPipeline/`: v1.1 vision interface and on-demand snapshot flow

Detailed API and data-flow notes: `docs/architecture.md`.

## Getting Started

### Requirements

- macOS (Tahoe-first target, fallback supported)
- Xcode 16+ with command line tools
- Swift toolchain with `swift-testing` support

### Build

```bash
swift build --package-path KAMIBotApp
```

### Test

```bash
swift test --package-path KAMIBotApp
```

## Model and License Policy

- Model weights are not committed to this repository by default.
- First-run model downloads must be hash-verified.
- Contributors must document any new dependency licenses in `docs/dependencies.md`.

## Security

Report vulnerabilities using `SECURITY.md`.

## Contributing

See `CONTRIBUTING.md` for branch naming, commit style, and PR requirements.
