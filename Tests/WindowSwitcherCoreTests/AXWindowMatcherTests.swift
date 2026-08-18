import Testing
import WindowSwitcherCore

@Suite("AXWindowMatcher")
struct AXWindowMatcherTests {
    private func target(
        number: UInt32,
        pid: Int32 = 101,
        title: String,
        bounds: WindowBounds
    ) -> FocusTarget {
        FocusTarget(
            windowID: WindowRecord.makeID(pid: pid, windowNumber: number),
            pid: pid,
            windowNumber: number,
            appName: "Safari",
            title: title,
            bounds: bounds
        )
    }

    @Test("two same-PID empty-title windows match by bounds, not first")
    func emptyTitlesMatchBoundsNotFirst() {
        let first = WindowBounds(x: 0, y: 0, width: 800, height: 600)
        let second = WindowBounds(x: 200, y: 80, width: 1100, height: 720)
        let windows = [
            AXWindowSnapshot(title: "", bounds: first),
            AXWindowSnapshot(title: "", bounds: second),
        ]
        let focus = target(number: 11, title: "", bounds: second)
        #expect(AXWindowMatcher.matchIndex(target: focus, windows: windows) == 1)
        #expect(AXWindowMatcher.matchIndex(target: focus, windows: windows) != 0)
    }

    @Test("two same-PID empty-title windows with no bounds match return nil")
    func emptyTitlesNoGuess() {
        let windows = [
            AXWindowSnapshot(title: "", bounds: WindowBounds(x: 0, y: 0, width: 800, height: 600)),
            AXWindowSnapshot(title: "", bounds: WindowBounds(x: 200, y: 80, width: 1100, height: 720)),
        ]
        let focus = target(
            number: 99,
            title: "",
            bounds: WindowBounds(x: 9_000, y: 9_000, width: 10, height: 10)
        )
        #expect(AXWindowMatcher.matchIndex(target: focus, windows: windows) == nil)
    }

    @Test("unique windowNumber wins over empty titles")
    func windowNumberWins() {
        let first = WindowBounds(x: 0, y: 0, width: 800, height: 600)
        let second = WindowBounds(x: 200, y: 80, width: 1100, height: 720)
        let windows = [
            AXWindowSnapshot(title: "", bounds: first, windowNumber: 10),
            AXWindowSnapshot(title: "", bounds: second, windowNumber: 11),
        ]
        let focus = target(number: 11, title: "", bounds: first)
        #expect(AXWindowMatcher.matchIndex(target: focus, windows: windows) == 1)
    }

    @Test("FocusMapper copies bounds onto the target")
    func mapperWiresBounds() {
        let record = Fixtures.records()[1]
        let mapped = FocusMapper.target(for: record)
        #expect(mapped.bounds == record.bounds)
        #expect(mapped.windowNumber == record.windowNumber)
    }

    @Test("quartz conversion flips Cocoa Y")
    func quartzFlip() {
        let bounds = ScreenCoordinates.quartzBounds(
            cocoaX: 10,
            cocoaY: 100,
            width: 200,
            height: 50,
            primaryHeight: 1000
        )
        #expect(bounds.x == 10)
        #expect(bounds.y == 850)
        #expect(bounds.width == 200)
        #expect(bounds.height == 50)
    }
}
