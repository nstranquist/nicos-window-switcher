import Testing
import WindowSwitcherCore

@Suite("ExceptionFilter")
struct ExceptionFilterTests {
    @Test("hides a named app")
    func hidesNamedApp() {
        let records = Fixtures.records()
        let filtered = ExceptionFilter.apply(records, rules: [ExceptionRule(appName: "UTM")])
        #expect(records.contains { $0.appName == "UTM" })
        #expect(filtered.contains { $0.appName == "UTM" } == false)
        #expect(filtered.contains { $0.appName == "Safari" })
    }

    @Test("hides by title substring")
    func hidesTitle() {
        let records = Fixtures.records()
        let filtered = ExceptionFilter.apply(records, rules: [ExceptionRule(titleContains: "VM")])
        #expect(filtered.contains { $0.title.contains("VM") } == false)
        #expect(filtered.contains { $0.appName == "Notes" })
    }

    @Test("hides by window kind")
    func hidesKind() {
        let overlay = WindowRecord(
            id: "1:2",
            windowNumber: 2,
            ownerPID: 1,
            appName: "HUD",
            title: "toast",
            layer: 0,
            isOnscreen: true,
            bounds: WindowBounds(x: 0, y: 0, width: 100, height: 100),
            kind: .overlay
        )
        let standard = Fixtures.records()[0]
        let filtered = ExceptionFilter.apply([overlay, standard], rules: [ExceptionRule(kind: .overlay)])
        #expect(filtered == [standard])
    }

    @Test("empty rules pass through")
    func emptyRules() {
        let records = Fixtures.records()
        #expect(ExceptionFilter.apply(records, rules: [ExceptionRule()]) == records)
        #expect(ExceptionFilter.apply(records, rules: []) == records)
    }
}
