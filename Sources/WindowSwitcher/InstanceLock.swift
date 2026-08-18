import Darwin
import Foundation

enum InstanceLock {
    nonisolated(unsafe) private static var fd: Int32 = -1

    static var shouldClaim: Bool {
        if ProcessInfo.processInfo.environment["NICOS_SWITCHER_HEADLESS"] == "1" { return false }
        if ProcessInfo.processInfo.environment["NICOS_SWITCHER_SELFTEST"] == "1" { return false }
        if ProcessInfo.processInfo.environment["NICOS_SWITCHER_ALLOW_MULTI"] == "1" { return false }
        return true
    }

    static func claim() -> Bool {
        if fd >= 0 { return true }
        let url = ConfigStore.configURL
            .deletingLastPathComponent()
            .appendingPathComponent("instance.lock")
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            fputs("window-switcher: lock dir failed (\(error))\n", stderr)
            return false
        }
        let opened = open(url.path, O_CREAT | O_RDWR, 0o644)
        guard opened >= 0 else { return false }
        if flock(opened, LOCK_EX | LOCK_NB) != 0 {
            close(opened)
            return false
        }
        fd = opened
        return true
    }
}
