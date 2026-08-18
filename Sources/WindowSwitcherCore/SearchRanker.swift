import Foundation

public struct RankedWindow: Sendable, Equatable {
    public var record: WindowRecord
    public var score: Int
    public var originalIndex: Int
}

/// Pure type-to-search ranking over window records.
public enum SearchRanker {
    public static func rank(_ records: [WindowRecord], query: String) -> [WindowRecord] {
        rankDetailed(records, query: query).map(\.record)
    }

    public static func rankDetailed(_ records: [WindowRecord], query: String) -> [RankedWindow] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty {
            return records.enumerated().map { RankedWindow(record: $0.element, score: 0, originalIndex: $0.offset) }
        }

        var ranked: [RankedWindow] = []
        ranked.reserveCapacity(records.count)
        for (index, record) in records.enumerated() {
            let score = scoreRecord(record, query: needle)
            if score > 0 {
                ranked.append(RankedWindow(record: record, score: score, originalIndex: index))
            }
        }
        ranked.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.originalIndex < $1.originalIndex
        }
        return ranked
    }

    public static func scoreRecord(_ record: WindowRecord, query: String) -> Int {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return 0 }
        let title = record.title
        let app = record.appName
        if title.caseInsensitiveCompare(q) == .orderedSame { return 100 }
        if app.caseInsensitiveCompare(q) == .orderedSame { return 90 }
        if title.lowercased().hasPrefix(q.lowercased()) { return 80 }
        if app.lowercased().hasPrefix(q.lowercased()) { return 70 }
        if title.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil { return 50 }
        if let label = record.catalogLabel,
           label.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        {
            return 45
        }
        if app.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil { return 40 }
        if let productID = record.catalogProductID,
           productID.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        {
            return 35
        }
        if record.displayTitle.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil { return 30 }
        return 0
    }
}
