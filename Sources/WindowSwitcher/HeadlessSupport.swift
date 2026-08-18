import AppKit
import Foundation

enum HeadlessSupport {
    static var isHeadless: Bool {
        let value = ProcessInfo.processInfo.environment["NICOS_SWITCHER_HEADLESS"]
        return value == "1" || value?.lowercased() == "true"
    }

    static var isSelfTest: Bool {
        ProcessInfo.processInfo.environment["NICOS_SWITCHER_SELFTEST"] == "1"
    }

    static var reportPath: String {
        ProcessInfo.processInfo.environment["NICOS_SWITCHER_SELFTEST_REPORT"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("nicos-switcher-selftest.json").path
    }

    private static let offscreen = NSPoint(x: -30_000, y: -30_000)

    @MainActor
    static func parkOffscreen(_ window: NSWindow?) {
        guard isHeadless, let window else { return }
        window.setFrameOrigin(offscreen)
    }

    static func writeReport(_ payload: [String: Any], path: String) throws {
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
}
