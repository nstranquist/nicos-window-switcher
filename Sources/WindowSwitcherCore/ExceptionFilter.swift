import Foundation

/// Hide named apps or window kinds from the switcher.
public struct ExceptionRule: Codable, Sendable, Equatable {
    public var appName: String?
    public var bundleID: String?
    public var kind: WindowKind?
    public var titleContains: String?

    public init(
        appName: String? = nil,
        bundleID: String? = nil,
        kind: WindowKind? = nil,
        titleContains: String? = nil
    ) {
        self.appName = appName
        self.bundleID = bundleID
        self.kind = kind
        self.titleContains = titleContains
    }

    public var isEmpty: Bool {
        let app = appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bundle = bundleID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = titleContains?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return app.isEmpty && bundle.isEmpty && kind == nil && title.isEmpty
    }

    public func matches(_ record: WindowRecord) -> Bool {
        if isEmpty { return false }
        if let appName {
            let needle = appName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !needle.isEmpty, record.appName.caseInsensitiveCompare(needle) != .orderedSame {
                return false
            }
        }
        if let bundleID {
            let needle = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !needle.isEmpty, record.bundleID.caseInsensitiveCompare(needle) != .orderedSame {
                return false
            }
        }
        if let kind, record.kind != kind {
            return false
        }
        if let titleContains {
            let needle = titleContains.trimmingCharacters(in: .whitespacesAndNewlines)
            if !needle.isEmpty, record.title.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
                return false
            }
        }
        return true
    }
}

public enum ExceptionFilter {
    public static func apply(_ records: [WindowRecord], rules: [ExceptionRule]) -> [WindowRecord] {
        let active = rules.filter { !$0.isEmpty }
        guard !active.isEmpty else { return records }
        return records.filter { record in
            !active.contains { $0.matches(record) }
        }
    }
}
