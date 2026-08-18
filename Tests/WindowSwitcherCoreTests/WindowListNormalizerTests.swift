import Testing
import WindowSwitcherCore

@Suite("WindowListNormalizer")
struct WindowListNormalizerTests {
    @Test("keeps other apps' windows and drops the switcher itself")
    func keepsWindowsNotAppsOnly() {
        let records = Fixtures.records()
        let ids = records.map(\.id)
        #expect(ids.contains("101:10"))
        #expect(ids.contains("101:11"))
        #expect(ids.contains("202:20"))
        #expect(!ids.contains(where: { $0.hasPrefix("505:") }))
        #expect(records.filter { $0.appName == "Safari" }.count == 2)
        #expect(Set(records.map(\.appName)).count > 1)
    }

    @Test("stable identity is pid plus window number")
    func stableIdentity() {
        let safari = Fixtures.records().first { $0.windowNumber == 10 }
        #expect(safari?.id == WindowRecord.makeID(pid: 101, windowNumber: 10))
        #expect(safari?.appName == "Safari")
        #expect(safari?.title == "Inbox — Mail")
    }

    @Test("drops overlays, offscreen, transparent, and tiny windows")
    func dropsNonStandard() {
        let records = Fixtures.records()
        #expect(records.contains { $0.appName == "Dock" } == false)
        #expect(records.contains { $0.appName == "Finder" } == false)
        #expect(records.contains { $0.appName == "Ghost" } == false)

        let tiny = Fixtures.window(number: 99, pid: 1, app: "Tiny", title: "x", width: 2, height: 2)
        #expect(WindowListNormalizer.normalize(tiny) == nil)
    }

    @Test("dedupes the same pid:windowNumber")
    func dedupes() {
        let raw = [
            Fixtures.window(number: 1, pid: 9, app: "A", title: "one"),
            Fixtures.window(number: 1, pid: 9, app: "A", title: "one-dup"),
        ]
        #expect(WindowListNormalizer.normalizeAll(raw).count == 1)
    }
}
