import Foundation

/// AX-visible window as the adapter collected it. `windowNumber` is optional
/// because public AX has no reverse wid lookup.
public struct AXWindowSnapshot: Sendable, Equatable {
    public var title: String
    public var bounds: WindowBounds
    public var windowNumber: UInt32?

    public init(title: String, bounds: WindowBounds, windowNumber: UInt32? = nil) {
        self.title = title
        self.bounds = bounds
        self.windowNumber = windowNumber
    }
}

/// Pure match of a CG/AX focus target onto AX records.
/// Never falls back to `windows.first`.
public enum AXWindowMatcher {
    public static let defaultTolerance: Double = 4

    public static func matchIndex(
        target: FocusTarget,
        windows: [AXWindowSnapshot],
        boundTolerance: Double = defaultTolerance
    ) -> Int? {
        if target.windowNumber != 0 {
            let byNumber = windows.indices.filter { windows[$0].windowNumber == target.windowNumber }
            if byNumber.count == 1 { return byNumber[0] }
            if byNumber.count > 1 { return nil }
        }

        let byBounds = windows.indices.filter { windows[$0].bounds.matches(target.bounds, tolerance: boundTolerance) }
        if byBounds.count == 1 { return byBounds[0] }
        if byBounds.count > 1 {
            let wanted = target.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !wanted.isEmpty {
                let titled = byBounds.filter { windows[$0].title == wanted }
                if titled.count == 1 { return titled[0] }
            }
            return nil
        }

        let wanted = target.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !wanted.isEmpty {
            let byTitle = windows.indices.filter { windows[$0].title == wanted }
            if byTitle.count == 1 { return byTitle[0] }
        }

        return nil
    }
}

/// AX reports Cocoa bottom-left origin; CGWindowList uses Quartz top-left.
public enum ScreenCoordinates {
    public static func quartzBounds(
        cocoaX: Double,
        cocoaY: Double,
        width: Double,
        height: Double,
        primaryHeight: Double
    ) -> WindowBounds {
        WindowBounds(
            x: cocoaX,
            y: primaryHeight - cocoaY - height,
            width: width,
            height: height
        )
    }
}
