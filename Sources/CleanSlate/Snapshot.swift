import AppKit
import SwiftUI

/// 开发用：把主界面放进离屏窗口渲染成 PNG，方便不截屏也能检查布局
enum Snapshot {
    static func render(to path: String, dark: Bool, tipJar: Bool = false) {
        _ = NSApplication.shared
        NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)

        let root = tipJar ? AnyView(TipJarView().background(Color(nsColor: .windowBackgroundColor)))
                         : AnyView(ContentView(controller: CleanupController()))
        let view = NSHostingView(rootView: root)
        let size = view.fittingSize
        view.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}
