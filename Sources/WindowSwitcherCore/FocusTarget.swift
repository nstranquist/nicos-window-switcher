import Foundation

public enum FocusStrategy: String, Codable, Sendable, Equatable {
    case axRaise
}

/// Public-API focus mapping. The AppKit/AX adapter performs the raise.
public struct FocusTarget: Codable, Sendable, Equatable {
    public var windowID: String
    public var pid: Int32
    public var windowNumber: UInt32
    public var appName: String
    public var title: String
    public var bounds: WindowBounds
    public var strategy: FocusStrategy

    public init(
        windowID: String,
        pid: Int32,
        windowNumber: UInt32,
        appName: String,
        title: String,
        bounds: WindowBounds,
        strategy: FocusStrategy = .axRaise
    ) {
        self.windowID = windowID
        self.pid = pid
        self.windowNumber = windowNumber
        self.appName = appName
        self.title = title
        self.bounds = bounds
        self.strategy = strategy
    }
}

public enum FocusMapper {
    public static func target(for record: WindowRecord) -> FocusTarget {
        FocusTarget(
            windowID: record.id,
            pid: record.ownerPID,
            windowNumber: record.windowNumber,
            appName: record.appName,
            title: record.title,
            bounds: record.bounds,
            strategy: .axRaise
        )
    }

    public static func record(id: String, in records: [WindowRecord]) -> WindowRecord? {
        records.first { $0.id == id }
    }
}
