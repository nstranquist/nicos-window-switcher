import Foundation

public struct CatalogOwner: Sendable, Equatable {
    public var productID: String
    public var label: String

    public init(productID: String, label: String) {
        self.productID = productID
        self.label = label
    }
}

public struct CatalogOwnerRule: Sendable, Equatable {
    public var productID: String
    public var label: String
    public var bundleIDs: [String]
    public var appNames: [String]

    public init(productID: String, label: String, bundleIDs: [String] = [], appNames: [String] = []) {
        self.productID = productID
        self.label = label
        self.bundleIDs = bundleIDs
        self.appNames = appNames
    }
}

/// Maps a window's app/bundle facts onto an optional catalog product owner.
public enum CatalogLabelMapper {
    public static let defaultRules: [CatalogOwnerRule] = [
        CatalogOwnerRule(
            productID: "product.nicos-window-switcher",
            label: "Nicos Window Switcher",
            bundleIDs: ["com.nstranquist.nicos-window-switcher"],
            appNames: ["Nicos Window Switcher", "WindowSwitcher"]
        ),
        CatalogOwnerRule(
            productID: "product.nicos-slot-dock",
            label: "Nicos Slot Dock",
            bundleIDs: ["com.nstranquist.nicos-slot-dock"],
            appNames: ["Nicos Slot Dock", "SlotDock"]
        ),
        CatalogOwnerRule(
            productID: "product.nicos-scratchpad",
            label: "Nicos Scratchpad",
            bundleIDs: ["com.nstranquist.nicos-scratchpad"],
            appNames: ["Nicos Scratchpad"]
        ),
        CatalogOwnerRule(
            productID: "product.nicos-hidden-menubar",
            label: "Nicos Hidden Bar",
            bundleIDs: ["com.nstranquist.nicos-hidden-menubar"],
            appNames: ["Nicos Hidden Bar", "Hidden Bar"]
        ),
        CatalogOwnerRule(
            productID: "product.nicos-voice",
            label: "Nicos Voice",
            bundleIDs: ["com.nstranquist.nicos-voice"],
            appNames: ["Nicos Voice"]
        ),
        CatalogOwnerRule(
            productID: "product.nicos-launcher-menubar",
            label: "Nicos Launch",
            bundleIDs: ["com.nstranquist.nicos-launcher"],
            appNames: ["Nicos Launch"]
        ),
    ]

    public static func owner(for record: WindowRecord, rules: [CatalogOwnerRule] = defaultRules) -> CatalogOwner? {
        let bundle = record.bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !bundle.isEmpty {
            for rule in rules {
                if rule.bundleIDs.contains(where: { $0.caseInsensitiveCompare(bundle) == .orderedSame }) {
                    return CatalogOwner(productID: rule.productID, label: rule.label)
                }
            }
        }
        let app = record.appName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !app.isEmpty {
            for rule in rules {
                if rule.appNames.contains(where: { $0.caseInsensitiveCompare(app) == .orderedSame }) {
                    return CatalogOwner(productID: rule.productID, label: rule.label)
                }
            }
        }
        return nil
    }

    public static func apply(_ records: [WindowRecord], rules: [CatalogOwnerRule] = defaultRules) -> [WindowRecord] {
        records.map { record in
            var copy = record
            if let owner = owner(for: record, rules: rules) {
                copy.catalogProductID = owner.productID
                copy.catalogLabel = owner.label
            }
            return copy
        }
    }
}
