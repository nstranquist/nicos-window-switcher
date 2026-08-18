import Testing
import WindowSwitcherCore

@Suite("SessionKeyHandler")
struct SessionKeyHandlerTests {
    @Test("hold-session keyDown appends into setQuery")
    func typingFeedsSetQuery() {
        var session = SwitcherSession()
        session.begin(windows: Fixtures.records())
        let first = SessionKeyHandler.input(characters: "s", keyCode: 1, command: false)
        #expect(SessionKeyHandler.apply(first, to: &session) == .updated)
        #expect(session.query == "s")
        let second = SessionKeyHandler.input(characters: "af", keyCode: 0, command: false)
        #expect(SessionKeyHandler.apply(second, to: &session) == .updated)
        #expect(session.query == "saf")
        #expect(session.windows.allSatisfy { $0.appName == "Safari" })
        #expect(session.isShowing)
    }

    @Test("delete and escape update or cancel the live session")
    func deleteAndEscape() {
        var session = SwitcherSession()
        session.begin(windows: Fixtures.records())
        _ = SessionKeyHandler.apply(
            SessionKeyHandler.input(characters: "Notes", keyCode: 0, command: false),
            to: &session
        )
        #expect(session.windows.count == 1)
        let deleted = SessionKeyHandler.apply(
            SessionKeyHandler.input(characters: "", keyCode: SessionKeyHandler.deleteKeyCode, command: false),
            to: &session
        )
        #expect(deleted == .updated)
        #expect(session.query == "Note")
        let cancelled = SessionKeyHandler.apply(
            SessionKeyHandler.input(characters: "", keyCode: SessionKeyHandler.escapeKeyCode, command: false),
            to: &session
        )
        #expect(cancelled == .cancelled)
        #expect(session.isShowing == false)
    }

    @Test("tab and hidden session do not type")
    func ignoresTabAndHidden() {
        var hidden = SwitcherSession()
        #expect(
            SessionKeyHandler.apply(
                SessionKeyHandler.input(characters: "x", keyCode: 7, command: false),
                to: &hidden
            ) == .ignored
        )
        var session = SwitcherSession()
        session.begin(windows: Fixtures.records())
        #expect(
            SessionKeyHandler.apply(
                SessionKeyHandler.input(characters: "\t", keyCode: SessionKeyHandler.tabKeyCode, command: false),
                to: &session
            ) == .ignored
        )
        #expect(session.query.isEmpty)
    }
}
