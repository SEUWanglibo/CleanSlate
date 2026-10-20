import AppKit
import SwiftUI

/// 黑屏：在每块屏幕上盖一个纯黑的无边框窗口，层级高于菜单栏和 Dock，方便看清并擦掉屏幕上的灰尘和指纹。
final class BlackoutOverlay {
    private var windows: [NSWindow] = []

    func show(controller: CleanupController) {
        hide()
        for screen in NSScreen.screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless,
                                  backing: .buffered, defer: false, screen: screen)
            window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            window.contentView = NSHostingView(rootView: BlackoutView(controller: controller))
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

/// 黑屏上的提示：开始时显示几秒后淡出，保持全黑；按住双 Command 时显示解锁进度。
struct BlackoutView: View {
    @ObservedObject var controller: CleanupController

    var body: some View {
        ZStack {
            Color.black
            if controller.showHint || controller.unlockProgress > 0 {
                VStack(spacing: 22) {
                    Mascot(size: 88, breathing: false)
                        .opacity(0.55)
                    PawProgressRing(progress: controller.unlockProgress, size: 52,
                                    track: Color.white.opacity(0.15))
                    VStack(spacing: 6) {
                        Text(controller.unlockProgress > 0 ? "小橘醒啦…" : "小橘睡着了，放心擦屏幕吧")
                            .font(Theme.rounded(18, .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("同时按住左右两个 ⌘ 3 秒叫醒它")
                            .font(Theme.rounded(13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 1), value: controller.showHint)
        .animation(.easeOut(duration: 0.3), value: controller.unlockProgress > 0)
    }
}
