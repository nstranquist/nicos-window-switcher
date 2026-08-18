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
        case "":
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
