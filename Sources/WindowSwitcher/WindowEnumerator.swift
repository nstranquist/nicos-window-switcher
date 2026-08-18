import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import WindowSwitcherCore

enum WindowEnumerator {
    static func snapshots(excludingPID: pid_t) -> [RawWindowSnapshot] {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return info.compactMap { dict in
            snapshot(from: dict, excludingPID: excludingPID)
        }
    }

    static func snapshot(from dict: [String: Any], excludingPID: pid_t) -> RawWindowSnapshot? {
        let number = uint32(dict[kCGWindowNumber as String])
        let pid = int32(dict[kCGWindowOwnerPID as String])
        guard number > 0, pid > 0 else { return nil }
        let owner = string(dict[kCGWindowOwnerName as String])
        let title = string(dict[kCGWindowName as String])
        let layer = intValue(dict[kCGWindowLayer as String])
        let alpha = doubleValue(dict[kCGWindowAlpha as String], default: 1)
        let onscreen = boolValue(dict[kCGWindowIsOnscreen as String], default: true)
        let boundsDict = dict[kCGWindowBounds as String] as? [String: Any] ?? [:]
        let bounds = WindowBounds(
            x: doubleValue(boundsDict["X"]),
            y: doubleValue(boundsDict["Y"]),
            width: doubleValue(boundsDict["Width"], default: 0),
            height: doubleValue(boundsDict["Height"], default: 0)
        )
        let bundleID = bundleID(for: pid)
        return RawWindowSnapshot(
            windowNumber: number,
            ownerPID: pid,
            ownerName: owner,
            title: title,
            layer: layer,
            isOnscreen: onscreen,
            alpha: alpha,
            bounds: bounds,
            isSwitcherSelf: pid == excludingPID,
            bundleID: bundleID
        )
    }

    static func records(config: SwitcherConfig, query: String = "", excludingPID: pid_t) -> [WindowRecord] {
        WindowPipeline.visibleWindows(
            raw: snapshots(excludingPID: excludingPID),
            exceptions: config.exceptions,
            query: query
        )
    }

    private static func bundleID(for pid: pid_t) -> String {
        NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? ""
    }

    private static func string(_ value: Any?) -> String {
        value as? String ?? ""
    }

    private static func uint32(_ value: Any?) -> UInt32 {
        if let n = value as? UInt32 { return n }
        if let n = value as? Int { return UInt32(n) }
        if let n = value as? NSNumber { return n.uint32Value }
        return 0
    }

    private static func int32(_ value: Any?) -> Int32 {
        if let n = value as? Int32 { return n }
        if let n = value as? Int { return Int32(n) }
        if let n = value as? NSNumber { return n.int32Value }
        return 0
    }

    private static func intValue(_ value: Any?) -> Int {
        if let n = value as? Int { return n }
        if let n = value as? NSNumber { return n.intValue }
        return 0
    }

    private static func doubleValue(_ value: Any?, default fallback: Double = 0) -> Double {
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        if let n = value as? NSNumber { return n.doubleValue }
        return fallback
    }

    private static func boolValue(_ value: Any?, default fallback: Bool) -> Bool {
        if let n = value as? Bool { return n }
        if let n = value as? NSNumber { return n.boolValue }
        return fallback
    }
}
