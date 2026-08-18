import Foundation

public struct SwitcherConfig: Codable, Sendable, Equatable {
    public var hotkey: HotkeySpec
    public var exceptions: [ExceptionRule]
    public var thumbnailsEnabled: Bool
    public var hotkeysEnabled: Bool

    public init(
        hotkey: HotkeySpec = .default,
        exceptions: [ExceptionRule] = [],
        thumbnailsEnabled: Bool = false,
        hotkeysEnabled: Bool = true
    ) {
        self.hotkey = hotkey
        self.exceptions = exceptions
        self.thumbnailsEnabled = thumbnailsEnabled
        self.hotkeysEnabled = hotkeysEnabled
    }

    public static let `default` = SwitcherConfig()

    enum CodingKeys: String, CodingKey {
        case hotkey, exceptions, thumbnailsEnabled, hotkeysEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotkey = try container.decodeIfPresent(HotkeySpec.self, forKey: .hotkey) ?? .default
        exceptions = try container.decodeIfPresent([ExceptionRule].self, forKey: .exceptions) ?? []
        thumbnailsEnabled = try container.decodeIfPresent(Bool.self, forKey: .thumbnailsEnabled) ?? false
        hotkeysEnabled = try container.decodeIfPresent(Bool.self, forKey: .hotkeysEnabled) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hotkey, forKey: .hotkey)
        try container.encode(exceptions, forKey: .exceptions)
        try container.encode(thumbnailsEnabled, forKey: .thumbnailsEnabled)
        try container.encode(hotkeysEnabled, forKey: .hotkeysEnabled)
    }

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
        let labeled = CatalogLabelMapper.apply(filtered)
        return SearchRanker.rank(labeled, query: query)
    }
}
