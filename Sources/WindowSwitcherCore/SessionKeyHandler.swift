import Foundation

public struct SessionKeyInput: Sendable, Equatable {
    public var characters: String
    public var isDelete: Bool
    public var isEscape: Bool
    public var hasCommand: Bool

    public init(characters: String, isDelete: Bool = false, isEscape: Bool = false, hasCommand: Bool = false) {
        self.characters = characters
        self.isDelete = isDelete
        self.isEscape = isEscape
        self.hasCommand = hasCommand
    }
}

public enum SessionKeyOutcome: Sendable, Equatable {
    case updated
    case cancelled
    case ignored
}

/// Hold-session typing. OverlayController's keyDown monitor feeds this.
public enum SessionKeyHandler {
    public static let deleteKeyCode: UInt16 = 51
    public static let escapeKeyCode: UInt16 = 53
    public static let tabKeyCode: UInt16 = 48
    public static let returnKeyCode: UInt16 = 36

    public static func input(characters: String, keyCode: UInt16, command: Bool) -> SessionKeyInput {
        SessionKeyInput(
            characters: characters,
            isDelete: keyCode == deleteKeyCode,
            isEscape: keyCode == escapeKeyCode,
            hasCommand: command
        )
    }

    public static func apply(_ input: SessionKeyInput, to session: inout SwitcherSession) -> SessionKeyOutcome {
        guard session.isShowing else { return .ignored }
        if input.hasCommand { return .ignored }
        if input.isEscape {
            session.cancel()
            return .cancelled
        }
        if input.isDelete {
            guard !session.query.isEmpty else { return .ignored }
            session.setQuery(String(session.query.dropLast()))
            return .updated
        }
        let printable = input.characters.filter { character in
            character != "\t"
                && character != "\r"
                && character != "\u{1b}"
                && (character.isLetter || character.isNumber || character.isPunctuation || character == " ")
        }
        guard !printable.isEmpty else { return .ignored }
        session.setQuery(session.query + String(printable))
        return .updated
    }
}
