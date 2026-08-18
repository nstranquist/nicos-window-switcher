import ApplicationServices
import AppKit
import Foundation
import WindowSwitcherCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let toggleNotification = Notification.Name("com.nstranquist.nicos-window-switcher.toggleHotkeys")

    private var overlay: OverlayController?
    private var hotkeys: HotkeyMonitor?
    private var statusItem: NSStatusItem?
    private var config = SwitcherConfig.default
    private var hotkeysMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = ConfigStore.load()
        ConfigStore.save(config)
        NSApp.setActivationPolicy(.accessory)

        let overlay = OverlayController(config: config)
        self.overlay = overlay

        let monitor = HotkeyMonitor()
        monitor.onNext = { overlay.handleNext() }
        monitor.onPrev = { overlay.handlePrev() }
        monitor.onRelease = { overlay.handleRelease() }
        self.hotkeys = monitor
        applyHotkeyRegistration()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "WS"
        item.button?.toolTip = "Nicos Window Switcher · \(config.hotkey.displayLabel)"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show switcher (\(config.hotkey.displayLabel))", action: #selector(showSwitcher), keyEquivalent: "")
        let toggle = NSMenuItem(title: "Hotkeys", action: #selector(toggleHotkeys), keyEquivalent: "")
        toggle.state = config.hotkeysEnabled ? .on : .off
        menu.addItem(toggle)
        hotkeysMenuItem = toggle
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Request Accessibility…", action: #selector(requestAccessibility), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(toggleHotkeys),
            name: Self.toggleNotification,
            object: nil
        )

        if !HeadlessSupport.isSelfTest && !HeadlessSupport.isHeadless {
            requestAccessibility()
        }

        if HeadlessSupport.isSelfTest {
            runSelfTestAndExit()
        }
    }

    @objc private func showSwitcher() {
        overlay?.handleNext()
    }

    @objc func toggleHotkeys() {
        config.hotkeysEnabled.toggle()
        ConfigStore.save(config)
        applyHotkeyRegistration()
        hotkeysMenuItem?.state = config.hotkeysEnabled ? .on : .off
        if !config.hotkeysEnabled {
            overlay?.cancel()
        }
        fputs("window-switcher: hotkeys \(config.hotkeysEnabled ? "on" : "off")\n", stderr)
    }

    @objc private func requestAccessibility() {
        Self.promptAccessibility()
    }

    nonisolated private static func promptAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func applyHotkeyRegistration() {
        guard let hotkeys else { return }
        if config.hotkeysEnabled {
            hotkeys.register(config.hotkey)
        } else {
            hotkeys.unregister()
        }
    }

    private func runSelfTestAndExit() {
        overlay?.handleNext()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            let showing = self.overlay?.isShowing == true
            let permission = ThumbnailCapture.permission()
            let decision = ThumbnailPolicy.decide(
                permission: permission,
                thumbnailsEnabled: self.config.thumbnailsEnabled
            )
            let payload: [String: Any] = [
                "ok": showing && decision.listAndFocusAllowed,
                "app": "nicos-window-switcher",
                "showing": showing,
                "hotkey": self.config.hotkey.displayLabel,
                "hotkey_is_option_tab": self.config.hotkey.isOptionTab,
                "list_and_focus_allowed": decision.listAndFocusAllowed,
                "thumbnails_attach": decision.attachImage,
                "capture_permission": permission.rawValue,
                "hotkeys_enabled": self.config.hotkeysEnabled,
            ]
            do {
                try HeadlessSupport.writeReport(payload, path: HeadlessSupport.reportPath)
            } catch {
                fputs("window-switcher: self-test report failed: \(error)\n", stderr)
                exit(1)
            }
            exit(showing && !self.config.hotkey.isOptionTab ? 0 : 1)
        }
    }
}
