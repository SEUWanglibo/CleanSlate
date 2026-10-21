import AppKit
import ApplicationServices
import SwiftUI

final class CleanupController: ObservableObject {
    @AppStorage("lockKeyboard") var lockKeyboard = true
    @AppStorage("lockMouse") var lockMouse = true
    @AppStorage("blackScreen") var blackScreen = true
    /// 安全兜底：超过这个时间自动解锁，0 表示不自动解锁
    @AppStorage("autoUnlockMinutes") var autoUnlockMinutes = 5

    @Published private(set) var isCleaning = false
    @Published private(set) var unlockProgress: Double = 0
    /// 黑屏刚出现时显示几秒解锁提示，然后淡出保持全黑
    @Published private(set) var showHint = false
    @Published private(set) var hasAccessibilityPermission = AXIsProcessTrusted()
    @Published var errorMessage: String?
    /// 「请小橘吃罐头」收款码弹窗
    @Published var showingTipJar = false

    static let holdDuration: TimeInterval = 3

    private let eventTap = EventTap()
    private let overlay = BlackoutOverlay()
    private var holdTimer: Timer?
    private var holdStart: Date?
    private var autoUnlockTimer: Timer?
    private var permissionTimer: Timer?

    init() {
        eventTap.onBothCommandKeysChanged = { [weak self] down in
            down ? self?.beginHold() : self?.cancelHold()
        }
        // 授权后系统不会通知 app，轮询一下权限状态
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let trusted = AXIsProcessTrusted()
            if self?.hasAccessibilityPermission != trusted { self?.hasAccessibilityPermission = trusted }
        }
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    func start() {
        guard !isCleaning else { return }
        guard AXIsProcessTrusted() else { requestPermission(); return }

        eventTap.lockKeyboard = lockKeyboard
        eventTap.lockMouse = lockMouse
        do {
            try eventTap.start()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isCleaning = true
        if blackScreen {
            showHint = true
            overlay.show(controller: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.showHint = false }
        }
        if lockMouse || blackScreen { CGDisplayHideCursor(CGMainDisplayID()) }

        if autoUnlockMinutes > 0 {
            autoUnlockTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoUnlockMinutes * 60),
                                                   repeats: false) { [weak self] _ in self?.stop() }
        }
    }

    func stop() {
        guard isCleaning else { return }
        cancelHold()
        autoUnlockTimer?.invalidate()
        autoUnlockTimer = nil
        eventTap.stop()
        overlay.hide()
        CGDisplayShowCursor(CGMainDisplayID())
        isCleaning = false
        NSApp.activate(ignoringOtherApps: true)
    }

    private func beginHold() {
        guard isCleaning else { return }
        holdStart = Date()
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let holdStart = self.holdStart else { return }
            self.unlockProgress = min(Date().timeIntervalSince(holdStart) / Self.holdDuration, 1)
            if self.unlockProgress >= 1 { self.stop() }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStart = nil
        unlockProgress = 0
    }
}
