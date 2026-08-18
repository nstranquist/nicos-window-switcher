import AppKit
import Foundation
import WindowSwitcherCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: OverlayController?
    private var hotkeys: HotkeyMonitor?
    private var statusItem: NSStatusItem?
    private var config = SwitcherConfig.default

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = ConfigStore.load()
        NSApp.setActivationPolicy(.accessory)

        let overlay = OverlayController(config: config)
        self.overlay = overlay

        let monitor = HotkeyMonitor()
        monitor.onNext = { overlay.handleNext() }
        monitor.onPrev = { overlay.handlePrev() }
        monitor.onRelease = { overlay.handleRelease() }
        monitor.register(config.hotkey)
        self.hotkeys = monitor

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "WS"
        item.button?.toolTip = "Nicos Window Switcher"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show switcher (\(config.hotkey.displayLabel))", action: #selector(showSwitcher), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item

        if HeadlessSupport.isSelfTest {
            runSelfTestAndExit()
        }
    }

    @objc private func showSwitcher() {
        overlay?.handleNext()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
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
