import Foundation

/// Turns raw CGWindow-shaped snapshots into overlay/CLI records.
public enum WindowListNormalizer {
    public static let minimumArea: Double = 64

    public static func classify(_ raw: RawWindowSnapshot) -> WindowKind {
        if raw.layer < 0 { return .desktop }
        if raw.layer > 0 { return .overlay }
        let name = raw.ownerName.lowercased()
        if name.contains("item-0") || name.contains("systemuiserver") || name.contains("control center") {
            return .menu
        }
        return .standard
    }

    public static func shouldKeep(_ raw: RawWindowSnapshot) -> Bool {
        if raw.isSwitcherSelf { return false }
        if raw.ownerPID <= 0 { return false }
        if raw.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if raw.alpha <= 0 { return false }
        if !raw.isOnscreen { return false }
        if raw.layer != 0 { return false }
        if raw.bounds.area < minimumArea { return false }
        return true
    }

    public static func normalize(_ raw: RawWindowSnapshot) -> WindowRecord? {
        guard shouldKeep(raw) else { return nil }
        return WindowRecord(
            id: WindowRecord.makeID(pid: raw.ownerPID, windowNumber: raw.windowNumber),
            windowNumber: raw.windowNumber,
            ownerPID: raw.ownerPID,
            appName: raw.ownerName,
            title: raw.title,
            layer: raw.layer,
            isOnscreen: raw.isOnscreen,
            bounds: raw.bounds,
            kind: classify(raw),
            bundleID: raw.bundleID
        )
    }

    public static func normalizeAll(_ raws: [RawWindowSnapshot]) -> [WindowRecord] {
        var seen = Set<String>()
        var out: [WindowRecord] = []
        for raw in raws {
            guard let record = normalize(raw) else { continue }
            if seen.contains(record.id) { continue }
            seen.insert(record.id)
            out.append(record)
        }
        return out
    }
}
