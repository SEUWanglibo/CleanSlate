import SwiftUI

@main
struct CleanSlateApp: App {
    @StateObject private var controller = CleanupController()

    init() {
        // 开发用：CleanSlate --snapshot <out.png> [--dark] 把主界面离屏渲染成图片后退出
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
            Snapshot.render(to: args[i + 1], dark: args.contains("--dark"))
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup("CleanSlate") {
            ContentView(controller: controller)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @ObservedObject var controller: CleanupController

    private static let autoUnlockChoices = [0, 1, 3, 5, 10]

    var body: some View {
        VStack(spacing: 22) {
            header

            if !controller.hasAccessibilityPermission {
                permissionBanner
            }

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Toggle("锁键盘", isOn: $controller.lockKeyboard)
                        .toggleStyle(OptionTileStyle(icon: "keyboard"))
                    Toggle("锁触控板", isOn: $controller.lockMouse)
                        .toggleStyle(OptionTileStyle(icon: "rectangle.and.hand.point.up.left"))
                    Toggle("黑屏", isOn: $controller.blackScreen)
                        .toggleStyle(OptionTileStyle(icon: "moon.zzz.fill"))
                }

                HStack {
                    Label("自动解锁", systemImage: "timer")
                        .font(Theme.rounded(13, .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("自动解锁", selection: $controller.autoUnlockMinutes) {
                        ForEach(Self.autoUnlockChoices, id: \.self) { minutes in
                            Text(minutes == 0 ? "关" : "\(minutes) 分").tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 210)
                }
            }
            .disabled(controller.isCleaning)

            if controller.isCleaning {
                cleaningStatus
            } else {
                Button {
                    controller.start()
                } label: {
                    Label("开始打扫", systemImage: "pawprint.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(!canStart)
            }

            unlockHint

            if let error = controller.errorMessage {
                Text(error).font(Theme.rounded(12)).foregroundColor(.red)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .frame(width: 400)
        .background(background)
        .tint(Theme.orange)
    }

    private var canStart: Bool {
        controller.hasAccessibilityPermission
            && (controller.lockKeyboard || controller.lockMouse || controller.blackScreen)
    }

    private var mood: String {
        if controller.isCleaning { return "小橘帮你守着呢，放心擦吧～" }
        if !controller.hasAccessibilityPermission { return "先给小橘开个权限，它才能帮你看住键盘" }
        if !(controller.lockKeyboard || controller.lockMouse || controller.blackScreen) {
            return "至少选一项，小橘才知道要做什么"
        }
        return "趴好了，随时可以开始打扫"
    }

    private var header: some View {
        VStack(spacing: 12) {
            Mascot(size: 112)
                .shadow(color: Theme.plum.opacity(0.35), radius: 16, y: 8)
            VStack(spacing: 4) {
                Text("CleanSlate")
                    .font(Theme.rounded(26, .bold))
                Text(mood)
                    .font(Theme.rounded(13))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: mood)
            }
        }
    }

    private var permissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 16))
                .foregroundColor(Theme.orangeDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text("需要辅助功能权限").font(Theme.rounded(13, .semibold))
                Text("用来在打扫时拦住键盘和触控板").font(Theme.rounded(11)).foregroundColor(.secondary)
            }
            Spacer()
            Button("去授权") { controller.requestPermission() }
                .font(Theme.rounded(12, .semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.orange.opacity(0.12))
        )
    }

    private var cleaningStatus: some View {
        HStack(spacing: 14) {
            PawProgressRing(progress: controller.unlockProgress, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("打扫中…").font(Theme.rounded(15, .semibold))
                Text("按住两个 ⌘ 3 秒结束").font(Theme.rounded(12)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.orange.opacity(0.12))
        )
    }

    private var unlockHint: some View {
        HStack(spacing: 6) {
            Text("打扫时同时按住").foregroundColor(.secondary)
            KeyCap(pressed: controller.unlockProgress > 0)
            Text("+").foregroundColor(.secondary)
            KeyCap(pressed: controller.unlockProgress > 0)
            Text("3 秒解锁").foregroundColor(.secondary)
        }
        .font(Theme.rounded(12))
    }

    private var background: some View {
        ZStack(alignment: .top) {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(colors: [Theme.plum.opacity(0.18), Theme.orange.opacity(0.06), .clear],
                           startPoint: .top, endPoint: .center)
        }
        .ignoresSafeArea()
    }
}
