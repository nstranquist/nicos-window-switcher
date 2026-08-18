import Foundation
import WindowSwitcherCore

enum CLI {
    struct Options {
        var command: String = ""
        var json = false
        var dryRun = false
        var id: String?
        var help = false
    }

    static func parse(_ args: [String]) -> Options {
        var options = Options()
        var rest = Array(args.dropFirst())
        if rest.first == "--help" || rest.first == "-h" {
            options.help = true
            return options
        }
        if let first = rest.first, !first.hasPrefix("-") {
            options.command = first
            rest.removeFirst()
        }
        var index = 0
        while index < rest.count {
            let arg = rest[index]
            switch arg {
            case "--json":
                options.json = true
            case "--dry-run":
                options.dryRun = true
            case "--help", "-h":
                options.help = true
            case "--id":
                if index + 1 < rest.count {
                    options.id = rest[index + 1]
                    index += 1
                }
            default:
                if arg.hasPrefix("--id=") {
                    options.id = String(arg.dropFirst(5))
                }
            }
            index += 1
        }
        return options
    }

    static var usage: String {
        """
        WindowSwitcher — nicos window switcher

        Usage:
          WindowSwitcher                 Launch the overlay app
          WindowSwitcher list [--json]   List current-Space windows
          WindowSwitcher focus --id ID [--dry-run]
          WindowSwitcher toggle          Enable/disable hotkeys on the running app
          WindowSwitcher --help
        """
    }

    @discardableResult
    static func runList(config: SwitcherConfig, json: Bool, excludingPID: pid_t) -> Int32 {
        let records = WindowEnumerator.records(config: config, excludingPID: excludingPID)
        if records.isEmpty {
            fputs("window-switcher: no windows (Accessibility/Screen Recording may hide titles)\n", stderr)
        }
        if json {
            let payload: [[String: Any]] = records.map { record in
                [
                    "id": record.id,
                    "windowNumber": record.windowNumber,
                    "pid": record.ownerPID,
                    "app": record.appName,
                    "title": record.title,
                    "kind": record.kind.rawValue,
                    "bundleID": record.bundleID,
                ]
            }
            guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
                  let text = String(data: data, encoding: .utf8)
            else {
                fputs("window-switcher: failed to encode JSON\n", stderr)
                return 1
            }
            print(text)
        } else {
            for record in records {
                print("\(record.id)\t\(record.appName)\t\(record.displayTitle)")
            }
        }
        return 0
    }

    @discardableResult
    static func runFocus(config: SwitcherConfig, id: String?, dryRun: Bool, excludingPID: pid_t) -> Int32 {
        guard let id, !id.isEmpty else {
            fputs("window-switcher: focus requires --id\n", stderr)
            return 2
        }
        let records = WindowEnumerator.records(config: config, excludingPID: excludingPID)
        guard let record = FocusMapper.record(id: id, in: records) else {
            fputs("window-switcher: unknown window id \(id)\n", stderr)
            return 2
        }
        let target = FocusMapper.target(for: record)
        do {
            let message = try WindowFocuser.focus(target, dryRun: dryRun)
            print(message)
            return 0
        } catch {
            fputs("window-switcher: \(error)\n", stderr)
            return 3
        }
    }
}
