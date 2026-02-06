import SwiftUI

@main
struct KAMIBotApp: App {
    @State private var viewModel = BMOViewModel(agent: AppContainer().agent)

    var body: some Scene {
        WindowGroup("KAMI BOT") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 320, minHeight: 420)
        }
        .defaultSize(width: 360, height: 460)
    }
}
