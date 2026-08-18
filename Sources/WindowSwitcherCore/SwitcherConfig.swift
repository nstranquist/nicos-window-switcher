import Foundation

public struct SwitcherConfig: Codable, Sendable, Equatable {
    public var hotkey: HotkeySpec
    public var exceptions: [ExceptionRule]
    public var thumbnailsEnabled: Bool

    public init(
        hotkey: HotkeySpec = .default,
        exceptions: [ExceptionRule] = [],
        thumbnailsEnabled: Bool = false
    ) {
        self.hotkey = hotkey
        self.exceptions = exceptions
        self.thumbnailsEnabled = thumbnailsEnabled
    }

    public static let `default` = SwitcherConfig()

    public static func load(from data: Data) throws -> SwitcherConfig {
        let decoder = JSONDecoder()
        let config = try decoder.decode(SwitcherConfig.self, from: data)
        try config.hotkey.validated()
        return config
    }

    public func encoded() throws -> Data {
        try hotkey.validated()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

public enum WindowPipeline {
    public static func visibleWindows(
        raw: [RawWindowSnapshot],
        exceptions: [ExceptionRule],
        query: String
    ) -> [WindowRecord] {
        let normalized = WindowListNormalizer.normalizeAll(raw)
        let filtered = ExceptionFilter.apply(normalized, rules: exceptions)
        return SearchRanker.rank(filtered, query: query)
    }
}
