import Foundation

public enum HotkeyModifier: String, Codable, Sendable, Equatable, CaseIterable {
    case control
    case option
    case shift
    case command
}

public enum HotkeyKey: String, Codable, Sendable, Equatable {
    case tab
    case space
    case grave
}

public enum HotkeySpecError: Error, Equatable, CustomStringConvertible {
    case collidesWithAltTab

    public var description: String {
        switch self {
        case .collidesWithAltTab:
            return "default must not steal AltTab Option+Tab"
        }
    }
}

/// Carbon-style binding. Default is Control+Option+Tab so AltTab keeps Option+Tab.
public struct HotkeySpec: Codable, Sendable, Equatable {
    public var modifiers: Set<HotkeyModifier>
    public var key: HotkeyKey

    public init(modifiers: Set<HotkeyModifier>, key: HotkeyKey) {
        self.modifiers = modifiers
        self.key = key
    }

    public static let `default` = HotkeySpec(modifiers: [.control, .option], key: .tab)

    public var isOptionTab: Bool {
        modifiers == [.option] && key == .tab
    }

    public func validated() throws {
        if isOptionTab { throw HotkeySpecError.collidesWithAltTab }
    }

    public var displayLabel: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        switch key {
        case .tab: parts.append("Tab")
        case .space: parts.append("Space")
        case .grave: parts.append("`")
        }
        return parts.joined()
    }

    enum CodingKeys: String, CodingKey {
        case modifiers, key
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mods = try container.decode([HotkeyModifier].self, forKey: .modifiers)
        modifiers = Set(mods)
        key = try container.decode(HotkeyKey.self, forKey: .key)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modifiers.sorted { $0.rawValue < $1.rawValue }, forKey: .modifiers)
        try container.encode(key, forKey: .key)
    }
}
