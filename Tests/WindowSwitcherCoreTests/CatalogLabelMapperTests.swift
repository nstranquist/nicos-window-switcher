import Testing
import WindowSwitcherCore

@Suite("CatalogLabelMapper")
struct CatalogLabelMapperTests {
    @Test("known bundle maps to a product id")
    func knownBundle() {
        let record = WindowRecord(
            id: "1:2",
            windowNumber: 2,
            ownerPID: 1,
            appName: "Nicos Scratchpad",
            title: "notes",
            layer: 0,
            isOnscreen: true,
            bounds: WindowBounds(x: 0, y: 0, width: 100, height: 100),
            kind: .standard,
            bundleID: "com.nstranquist.nicos-scratchpad"
        )
        let owner = CatalogLabelMapper.owner(for: record)
        #expect(owner?.productID == "product.nicos-scratchpad")
        #expect(owner?.label == "Nicos Scratchpad")
        let labeled = CatalogLabelMapper.apply([record])
        #expect(labeled[0].catalogProductID == "product.nicos-scratchpad")
        #expect(labeled[0].catalogLabel == "Nicos Scratchpad")
    }

    @Test("live scratchpad bundle maps even when it is not the nstranquist id")
    func liveScratchpadBundle() {
        let record = WindowRecord(
            id: "4:4",
            windowNumber: 4,
            ownerPID: 4,
            appName: "Nicos Scratchpad",
            title: "Scratchpad",
            layer: 0,
            isOnscreen: true,
            bounds: WindowBounds(x: 0, y: 0, width: 100, height: 100),
            kind: .standard,
            bundleID: "com.nicos.nicos-scratchpad"
        )
        #expect(CatalogLabelMapper.owner(for: record)?.productID == "product.nicos-scratchpad")
    }

    @Test("ndev pressure maps from its shipped bundle")
    func pressureBundle() {
        let record = WindowRecord(
            id: "5:5",
            windowNumber: 5,
            ownerPID: 5,
            appName: "NDev Pressure",
            title: "NDev Pressure",
            layer: 0,
            isOnscreen: true,
            bounds: WindowBounds(x: 0, y: 0, width: 100, height: 100),
            kind: .standard,
            bundleID: "com.nstranquist.ndev-pressure"
        )
        #expect(CatalogLabelMapper.owner(for: record)?.productID == "product.ndev-pressure")
        #expect(CatalogLabelMapper.owner(for: record)?.label == "NDev Pressure")
    }

    @Test("unknown app stays unlabeled")
    func unknownUnlabeled() {
        let record = Fixtures.records().first { $0.appName == "Safari" }!
        #expect(CatalogLabelMapper.owner(for: record) == nil)
        #expect(CatalogLabelMapper.apply([record])[0].catalogProductID == nil)
    }

    @Test("app name maps when bundle is empty")
    func appNameFallback() {
        let record = WindowRecord(
            id: "9:9",
            windowNumber: 9,
            ownerPID: 9,
            appName: "Nicos Slot Dock",
            title: "strip",
            layer: 0,
            isOnscreen: true,
            bounds: WindowBounds(x: 0, y: 0, width: 100, height: 100),
            kind: .standard,
            bundleID: ""
        )
        #expect(CatalogLabelMapper.owner(for: record)?.productID == "product.nicos-slot-dock")
    }

    @Test("search ranks a catalog label")
    func searchUsesLabel() {
        let raw = Fixtures.records()
        let scratch = WindowRecord(
            id: "3:3",
            windowNumber: 3,
            ownerPID: 3,
            appName: "Mystery",
            title: "doc",
            layer: 0,
            isOnscreen: true,
            bounds: WindowBounds(x: 0, y: 0, width: 100, height: 100),
            kind: .standard,
            bundleID: "com.nstranquist.nicos-scratchpad"
        )
        let labeled = CatalogLabelMapper.apply(raw + [scratch])
        let ranked = SearchRanker.rank(labeled, query: "scratchpad")
        #expect(ranked.first?.catalogProductID == "product.nicos-scratchpad")
    }
}
