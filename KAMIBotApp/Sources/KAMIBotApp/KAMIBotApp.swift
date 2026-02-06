import SwiftUI

@main
struct KAMIBotApp: App {
    @State private var viewModel: BMOViewModel

    init() {
        let container = AppContainer()
        _viewModel = State(
            initialValue: BMOViewModel(
                agent: container.agent,
                audioStartupCoordinator: container.audioStartupCoordinator
            )
        )
    }

    var body: some Scene {
        WindowGroup("KAMI BOT") {
            ContentView(viewModel: viewModel)
                .floatingWindow()
                .frame(minWidth: 320, minHeight: 420)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 360, height: 460)
    }
}
