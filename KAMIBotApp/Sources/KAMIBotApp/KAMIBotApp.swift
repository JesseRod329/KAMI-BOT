import SwiftUI

@main
struct KAMIBotApp: App {
    @State private var settingsStore: SettingsStore
    @State private var viewModel: BMOViewModel

    init() {
        let settingsStore = SettingsStore()
        let container = AppContainer(config: settingsStore.toAgentConfig())
        _settingsStore = State(initialValue: settingsStore)
        _viewModel = State(
            initialValue: BMOViewModel(
                agent: container.agent,
                audioStartupCoordinator: container.audioStartupCoordinator,
                modelStartupCoordinator: container.modelStartupCoordinator,
                startupChecks: container.startupChecks
            )
        )
    }

    var body: some Scene {
        WindowGroup("KAMI BOT") {
            ContentView(viewModel: viewModel, settingsStore: settingsStore)
                .floatingWindow()
                .frame(minWidth: 320, minHeight: 420)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 360, height: 460)
    }
}
