import Testing
import WindowSwitcherCore

@Suite("HotkeySpec")
struct HotkeySpecTests {
    @Test("default is Control+Option+Tab, not Option+Tab")
    func defaultDoesNotStealAltTab() throws {
        #expect(HotkeySpec.default.isOptionTab == false)
        #expect(HotkeySpec.default.modifiers == [.control, .option])
        #expect(HotkeySpec.default.key == .tab)
        try HotkeySpec.default.validated()
        #expect(HotkeySpec.default.displayLabel.contains("Tab"))
    }

    @Test("Option+Tab is rejected")
    func rejectsOptionTab() {
        let colliding = HotkeySpec(modifiers: [.option], key: .tab)
        #expect(colliding.isOptionTab)
        #expect(throws: HotkeySpecError.collidesWithAltTab) {
            try colliding.validated()
        }
    }

    @Test("hotkeysEnabled persists and defaults on")
    func hotkeysTogglePersists() throws {
        #expect(SwitcherConfig.default.hotkeysEnabled)
        var config = SwitcherConfig.default
        config.hotkeysEnabled = false
        let loaded = try SwitcherConfig.load(from: config.encoded())
        #expect(loaded.hotkeysEnabled == false)
        #expect(loaded.hotkey == HotkeySpec.default)
    }

    @Test("pipeline applies exceptions then search")
    func pipeline() {
        let windows = WindowPipeline.visibleWindows(
            raw: Fixtures.desktop(),
            exceptions: [ExceptionRule(appName: "UTM")],
            query: "saf"
        )
        #expect(windows.allSatisfy { $0.appName == "Safari" })
        #expect(windows.contains { $0.appName == "UTM" } == false)
        #expect(windows.contains { $0.appName == "Nicos Window Switcher" } == false)
    }
}
