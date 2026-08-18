import Foundation

/// Kind of window after public-API classification (layer + name heuristics).
public enum WindowKind: String, Codable, Sendable, Equatable, CaseIterable {
    case standard
    case overlay
    case desktop
    case menu
    case unknown
}

/// Axis-aligned bounds in screen points (no AppKit).
public struct WindowBounds: Codable, Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var area: Double { max(0, width) * max(0, height) }

    public func matches(_ other: WindowBounds, tolerance: Double) -> Bool {
        abs(x - other.x) <= tolerance
            && abs(y - other.y) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}

/// Raw snapshot from CGWindowList (or a test fixture). No live APIs.
public struct RawWindowSnapshot: Codable, Sendable, Equatable {
    public var windowNumber: UInt32
    public var ownerPID: Int32
    public var ownerName: String
    public var title: String
    public var layer: Int
    public var isOnscreen: Bool
    public var alpha: Double
    public var bounds: WindowBounds
    public var isSwitcherSelf: Bool
    public var bundleID: String

    public init(
        windowNumber: UInt32,
        ownerPID: Int32,
        ownerName: String,
        title: String,
        layer: Int = 0,
        isOnscreen: Bool = true,
        alpha: Double = 1,
        bounds: WindowBounds = WindowBounds(x: 0, y: 0, width: 800, height: 600),
        isSwitcherSelf: Bool = false,
        bundleID: String = ""
    ) {
        self.windowNumber = windowNumber
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.title = title
        self.layer = layer
        self.isOnscreen = isOnscreen
        self.alpha = alpha
        self.bounds = bounds
        self.isSwitcherSelf = isSwitcherSelf
        self.bundleID = bundleID
    }
}

/// Normalized window the overlay, search, and CLI share.
public struct WindowRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var windowNumber: UInt32
    public var ownerPID: Int32
    public var appName: String
    public var title: String
    public var layer: Int
    public var isOnscreen: Bool
    public var bounds: WindowBounds
    public var kind: WindowKind
    public var bundleID: String

    public init(
        id: String,
        windowNumber: UInt32,
        ownerPID: Int32,
        appName: String,
        title: String,
        layer: Int,
        isOnscreen: Bool,
        bounds: WindowBounds,
        kind: WindowKind,
        bundleID: String = ""
    ) {
        self.id = id
        self.windowNumber = windowNumber
        self.ownerPID = ownerPID
        self.appName = appName
        self.title = title
        self.layer = layer
        self.isOnscreen = isOnscreen
        self.bounds = bounds
        self.kind = kind
        self.bundleID = bundleID
    }

    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? appName : trimmed
    }

    /// Stable public-API identity: pid + CGWindowNumber.
    public static func makeID(pid: Int32, windowNumber: UInt32) -> String {
        "\(pid):\(windowNumber)"
    }
}
