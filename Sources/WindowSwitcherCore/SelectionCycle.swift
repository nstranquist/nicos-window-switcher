import Foundation

/// Hold/release selection session. Carbon adapter drives these transitions.
public struct SwitcherSession: Sendable, Equatable {
    public var isShowing: Bool
    public var selectedIndex: Int
    public var windows: [WindowRecord]
    public var query: String
    public var source: [WindowRecord]

    public init(
        isShowing: Bool = false,
        selectedIndex: Int = 0,
        windows: [WindowRecord] = [],
        query: String = "",
        source: [WindowRecord] = []
    ) {
        self.isShowing = isShowing
        self.selectedIndex = selectedIndex
        self.windows = windows
        self.query = query
        self.source = source
    }

    public var selected: WindowRecord? {
        guard isShowing, windows.indices.contains(selectedIndex) else { return nil }
        return windows[selectedIndex]
    }

    /// First press: show and land on the next window (MRU[1] when possible).
    public mutating func begin(windows incoming: [WindowRecord]) {
        source = incoming
        query = ""
        windows = incoming
        isShowing = true
        if incoming.count > 1 {
            selectedIndex = 1
        } else {
            selectedIndex = 0
        }
    }

    public mutating func cycleNext() {
        guard isShowing, !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
    }

    public mutating func cyclePrev() {
        guard isShowing, !windows.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
    }

    public mutating func setQuery(_ newQuery: String) {
        query = newQuery
        windows = SearchRanker.rank(source, query: newQuery)
        if windows.isEmpty {
            selectedIndex = 0
        } else if selectedIndex >= windows.count {
            selectedIndex = 0
        }
    }

    public mutating func commit() -> WindowRecord? {
        let target = selected
        isShowing = false
        query = ""
        return target
    }

    public mutating func cancel() {
        isShowing = false
        query = ""
        selectedIndex = 0
    }
}
