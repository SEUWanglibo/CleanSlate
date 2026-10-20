import CoreGraphics
import Foundation

/// 全局事件拦截。和 CleanupBuddy 一样：在 HID 层创建 CGEventTap，监听所有事件，
/// 在回调里按设置决定吞掉（返回 nil）还是放行。
final class EventTap {
    var lockKeyboard = true
    var lockMouse = true
    /// 左右 Command 是否同时按下的变化回调
    var onBothCommandKeysChanged: ((Bool) -> Void)?

    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var bothCommandDown = false

    // IOKit NX_DEVICELCMDKEYMASK / NX_DEVICERCMDKEYMASK
    private static let leftCommandMask: UInt64 = 0x08
    private static let rightCommandMask: UInt64 = 0x10

    private static let keyboardTypes: Set<UInt32> = [
        CGEventType.keyDown.rawValue,
        CGEventType.keyUp.rawValue,
        CGEventType.flagsChanged.rawValue,
        14, // NSEventTypeSystemDefined：音量、亮度、媒体键
    ]

    func start() throws {
        guard port == nil else { return }

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            let tap = Unmanaged<EventTap>.fromOpaque(userInfo!).takeUnretainedValue()
            return tap.handle(type: type, event: event)
        }

        guard let port = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask.max,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw NSError(domain: "CleanSlate", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "无法创建事件拦截，请检查辅助功能权限"])
        }
        let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        self.port = port
        self.source = source
    }

    func stop() {
        if let port { CGEvent.tapEnable(tap: port, enable: false); CFMachPortInvalidate(port) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        port = nil
        source = nil
        bothCommandDown = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 回调太慢或用户输入时系统会自动停用 tap，需要重新启用，否则锁就失效了
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            let flags = event.flags.rawValue
            let both = flags & Self.leftCommandMask != 0 && flags & Self.rightCommandMask != 0
            if both != bothCommandDown {
                bothCommandDown = both
                onBothCommandKeysChanged?(both)
            }
        }

        let isKeyboard = Self.keyboardTypes.contains(type.rawValue)
        if isKeyboard && lockKeyboard { return nil }
        if !isKeyboard && lockMouse { return nil }
        return Unmanaged.passUnretained(event)
    }
}
