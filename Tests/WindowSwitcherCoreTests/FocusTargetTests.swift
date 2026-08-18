import Testing
import WindowSwitcherCore

@Suite("FocusMapper")
struct FocusTargetTests {
    @Test("maps a record to an AX raise target")
    func mapsRecord() {
        let record = Fixtures.records()[0]
        let target = FocusMapper.target(for: record)
        #expect(target.windowID == record.id)
        #expect(target.pid == record.ownerPID)
        #expect(target.windowNumber == record.windowNumber)
        #expect(target.appName == record.appName)
        #expect(target.title == record.title)
        #expect(target.strategy == .axRaise)
    }

    @Test("looks up a record by stable id")
    func lookup() {
        let records = Fixtures.records()
        let id = records[1].id
        #expect(FocusMapper.record(id: id, in: records)?.id == id)
        #expect(FocusMapper.record(id: "missing:0", in: records) == nil)
    }
}
