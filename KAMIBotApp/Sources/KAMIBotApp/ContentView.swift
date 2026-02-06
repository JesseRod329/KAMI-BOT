import CoreAgent
import SwiftUI
import UIComponents

struct ContentView: View {
    @Bindable var viewModel: BMOViewModel
    @Bindable var settingsStore: SettingsStore
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 14) {
            GlassSurface {
                BMOFaceView(expression: viewModel.expression, state: viewModel.state)
            }

            Text("State: \(viewModel.state.rawValue.capitalized)")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(viewModel.transcript.suffix(4).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: 280, alignment: .leading)

            HStack {
                Button("Start") {
                    viewModel.start()
                }
                Button("Stop") {
                    viewModel.stop()
                }
                Button("Settings") {
                    isShowingSettings = true
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(settingsStore: settingsStore)
        }
    }
}
