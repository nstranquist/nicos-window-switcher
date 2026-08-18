import Testing
import WindowSwitcherCore

@Suite("SearchRanker")
struct SearchRankerTests {
    @Test("empty query preserves incoming order")
    func emptyPreservesOrder() {
        let records = Fixtures.records()
        #expect(SearchRanker.rank(records, query: "") == records)
        #expect(SearchRanker.rank(records, query: "   ") == records)
    }

    @Test("title match ranks above app contains")
    func titleBeatsApp() {
        let records = Fixtures.records()
        let ranked = SearchRanker.rank(records, query: "Scratch")
        #expect(ranked.first?.appName == "Notes")
        #expect(ranked.first?.title == "Scratch")
    }

    @Test("app prefix ranks Safari windows together")
    func appPrefix() {
        let records = Fixtures.records()
        let ranked = SearchRanker.rank(records, query: "saf")
        #expect(ranked.count == 2)
        #expect(ranked.allSatisfy { $0.appName == "Safari" })
        #expect(ranked[0].title == "Inbox — Mail")
    }

    @Test("non-matching query drops records")
    func noMatch() {
        let records = Fixtures.records()
        #expect(SearchRanker.rank(records, query: "zzz-no-such-window").isEmpty)
    }

    @Test("exact title scores higher than contains")
    func scoreOrder() {
        let exact = SearchRanker.scoreRecord(Fixtures.records().first { $0.title == "Scratch" }!, query: "Scratch")
        let contains = SearchRanker.scoreRecord(Fixtures.records().first { $0.title.contains("AltTab") }!, query: "Alt")
        #expect(exact > contains)
        #expect(exact == 100)
    }
}
