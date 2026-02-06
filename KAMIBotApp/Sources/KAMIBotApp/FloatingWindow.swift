import AppKit
import SwiftUI

struct FloatingWindowConfig: Equatable {
    var isBorderless: Bool = true
    var isFloating: Bool = true
    var isTransparent: Bool = true
}

enum FloatingWindowStyler {
    static func apply(_ config: FloatingWindowConfig, to window: NSWindow) {
        if config.isBorderless {
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
        }

        if config.isTransparent {
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
        }

        if config.isFloating {
            window.level = .floating
            window.collectionBehavior.insert(.canJoinAllSpaces)
            window.collectionBehavior.insert(.fullScreenAuxiliary)
        }
    }
}

struct FloatingWindowAccessor: NSViewRepresentable {
    var config: FloatingWindowConfig

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }
            FloatingWindowStyler.apply(config, to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else {
                return
            }
            FloatingWindowStyler.apply(config, to: window)
        }
    }
}

extension View {
    func floatingWindow(config: FloatingWindowConfig = FloatingWindowConfig()) -> some View {
        background(FloatingWindowAccessor(config: config))
    }
}
