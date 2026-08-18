import AppKit
import Foundation
import WindowSwitcherCore

@main
enum WindowSwitcherMain {
    static func main() {
        let args = CommandLine.arguments
        let options = CLI.parse(args)
        if options.help {
            print(CLI.usage)
            return
        }

        let config = ConfigStore.load()
        let pid = ProcessInfo.processInfo.processIdentifier

        switch options.command {
        case "list":
            exit(CLI.runList(config: config, json: options.json, excludingPID: pid))
        case "focus":
            exit(CLI.runFocus(config: config, id: options.id, dryRun: options.dryRun, excludingPID: pid))
        case "toggle":
            DistributedNotificationCenter.default().postNotificationName(
                AppDelegate.toggleNotification,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            print("toggled hotkeys on the running switcher")
            return
        case "":
            if InstanceLock.shouldClaim, !InstanceLock.claim() {
                fputs("window-switcher: already running; use the menu bar WS item or `WindowSwitcher toggle`\n", stderr)
                return
            }
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate
            app.run()
        default:
            fputs("window-switcher: unknown command \(options.command)\n", stderr)
            fputs(CLI.usage + "\n", stderr)
            exit(2)
        }
    }
}
