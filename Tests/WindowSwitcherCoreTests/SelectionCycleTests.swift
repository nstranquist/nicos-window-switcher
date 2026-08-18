import Testing
import WindowSwitcherCore

@Suite("SelectionCycle")
struct SelectionCycleTests {
    @Test("begin selects the next window, not the frontmost")
    func beginSelectsNext() {
        var session = SwitcherSession()
        session.begin(windows: Fixtures.records())
        #expect(session.isShowing)
        #expect(session.selectedIndex == 1)
        #expect(session.selected?.id == Fixtures.records()[1].id)
    }

    @Test("cycle wraps forward and backward")
    func wraps() {
        var session = SwitcherSession()
        let records = Array(Fixtures.records().prefix(3))
        session.begin(windows: records)
        session.cycleNext()
        #expect(session.selectedIndex == 2)
        session.cycleNext()
        #expect(session.selectedIndex == 0)
        session.cyclePrev()
        #expect(session.selectedIndex == 2)
    }

    @Test("query filters then commit returns the selected record")
    func queryThenCommit() {
        var session = SwitcherSession()
        session.begin(windows: Fixtures.records())
        session.setQuery("Notes")
        #expect(session.windows.count == 1)
        #expect(session.selected?.appName == "Notes")
        let target = session.commit()
        #expect(target?.appName == "Notes")
        #expect(session.isShowing == false)
    }

    @Test("cancel hides without a target")
    func cancel() {
        var session = SwitcherSession()
        session.begin(windows: Fixtures.records())
        session.cancel()
        #expect(session.isShowing == false)
        #expect(session.selected == nil)
    }

    @Test("single window begins at index 0")
    func singleWindow() {
        var session = SwitcherSession()
        session.begin(windows: [Fixtures.records()[0]])
        #expect(session.selectedIndex == 0)
        session.cycleNext()
        #expect(session.selectedIndex == 0)
    }
}
