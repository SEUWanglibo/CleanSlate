import AppKit
import SwiftUI

/// 颜色取自图标：小橘的橘色 + 背景的灰紫色
enum Theme {
    static let orange = Color(red: 0.94, green: 0.55, blue: 0.27)
    static let orangeDeep = Color(red: 0.88, green: 0.43, blue: 0.20)
    static let plum = Color(red: 0.43, green: 0.25, blue: 0.39)
    static let cream = Color(red: 0.99, green: 0.93, blue: 0.84)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// 小橘头像，打包后从 app 的 Resources 里读取
struct Mascot: View {
    var size: CGFloat
    var breathing = true

    var body: some View {
        TimelineView(.animation(paused: !breathing)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
                .scaleEffect(breathing ? 1 + 0.018 * sin(t * 1.6) : 1, anchor: .bottom)
        }
    }

    private var image: Image {
        if let nsImage = NSImage(named: "Mascot") { return Image(nsImage: nsImage) }
        return Image(systemName: "cat.fill")
    }
}

/// 可点击的大方块选项
struct OptionTileStyle: ToggleStyle {
    let icon: String

    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn
        return Button {
            configuration.isOn.toggle()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(height: 26)
                configuration.label
                    .font(Theme.rounded(12, .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .foregroundColor(isOn ? Theme.orangeDeep : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isOn ? Theme.orange.opacity(0.15) : Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isOn ? Theme.orange.opacity(0.7) : Color.primary.opacity(0.06), lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isOn {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.orange)
                        .padding(9)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}

/// 橘色胶囊主按钮
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }

    private struct PrimaryButton: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(Theme.rounded(16, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    Capsule().fill(LinearGradient(colors: [Theme.orange, Theme.orangeDeep],
                                                  startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: Theme.orange.opacity(isEnabled ? 0.35 : 0), radius: 10, y: 4)
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.25), value: configuration.isPressed)
        }
    }
}

/// 键帽样式的 ⌘
struct KeyCap: View {
    var symbol = "⌘"
    var pressed = false

    var body: some View {
        Text(symbol)
            .font(Theme.rounded(13, .semibold))
            .frame(width: 26, height: 24)
            .foregroundColor(pressed ? .white : .primary.opacity(0.7))
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(pressed ? Theme.orange : Color.primary.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(pressed ? 0 : 0.12), lineWidth: 1)
            )
    }
}

/// 圆环进度，中间一个小爪印
struct PawProgressRing: View {
    var progress: Double
    var size: CGFloat = 56
    var track = Color.primary.opacity(0.1)

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.34))
                .foregroundColor(progress > 0 ? Theme.orange : track)
        }
        .frame(width: size, height: size)
    }
}
