import AppKit
import Carbon
import Foundation
import WindowSwitcherCore

@MainActor
final class HotkeyMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var prevHotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    var onNext: (() -> Void)?
    var onPrev: (() -> Void)?
    var onRelease: (() -> Void)?
    private(set) var lastStatus: OSStatus = 0
    private var holding = false

    func register(_ spec: HotkeySpec) {
        unregister()
        do {
            try spec.validated()
        } catch {
            lastStatus = -50
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return noErr }
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                DispatchQueue.main.async {
                    monitor.handleHotKey(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        if status != noErr {
            lastStatus = status
            return
        }

        lastStatus = RegisterEventHotKey(
            spec.carbonKeyCode,
            spec.carbonModifiers,
            EventHotKeyID(signature: 0x4E575357, id: 1),
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        _ = RegisterEventHotKey(
            spec.carbonKeyCode,
            spec.carbonModifiers | UInt32(shiftKey),
            EventHotKeyID(signature: 0x4E575357, id: 2),
            GetApplicationEventTarget(),
            0,
            &prevHotKeyRef
        )

        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
            return event
        }
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let prevHotKeyRef { UnregisterEventHotKey(prevHotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
        if let flagsMonitor { NSEvent.removeMonitor(flagsMonitor) }
        if let localFlagsMonitor { NSEvent.removeMonitor(localFlagsMonitor) }
        hotKeyRef = nil
        prevHotKeyRef = nil
        handlerRef = nil
        flagsMonitor = nil
        localFlagsMonitor = nil
        holding = false
    }

    private func handleHotKey(id: UInt32) {
        holding = true
        if id == 2 {
            onPrev?()
        } else {
            onNext?()
        }
    }

    private func handleFlags(_ event: NSEvent) {
        guard holding else { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if !flags.contains(.control) && !flags.contains(.option) && !flags.contains(.command) {
            holding = false
            onRelease?()
        }
    }
}

private extension HotkeySpec {
    var carbonKeyCode: UInt32 {
        switch key {
        case .tab: return UInt32(kVK_Tab)
        case .space: return UInt32(kVK_Space)
        case .grave: return UInt32(kVK_ANSI_Grave)
        }
    }

    var carbonModifiers: UInt32 {
        var value: UInt32 = 0
        if modifiers.contains(.control) { value |= UInt32(controlKey) }
        if modifiers.contains(.option) { value |= UInt32(optionKey) }
        if modifiers.contains(.shift) { value |= UInt32(shiftKey) }
        if modifiers.contains(.command) { value |= UInt32(cmdKey) }
        return value
    }
}
