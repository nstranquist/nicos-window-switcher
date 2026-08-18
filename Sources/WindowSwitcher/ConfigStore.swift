import Foundation
import WindowSwitcherCore

enum ConfigStore {
    static var configURL: URL {
        if let override = ProcessInfo.processInfo.environment["NICOS_SWITCHER_CONFIG"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("nicos-window-switcher", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    static func load() -> SwitcherConfig {
        let url = configURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .default
        }
        do {
            let data = try Data(contentsOf: url)
            return try SwitcherConfig.load(from: data)
        } catch {
            fputs("window-switcher: config load failed (\(error)); using default\n", stderr)
            return .default
        }
    }

    @discardableResult
    static func save(_ config: SwitcherConfig) -> Bool {
        do {
            try config.hotkey.validated()
            let url = configURL
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try config.encoded().write(to: url, options: .atomic)
            return true
        } catch {
            fputs("window-switcher: config save failed (\(error))\n", stderr)
            return false
        }
    }
}
