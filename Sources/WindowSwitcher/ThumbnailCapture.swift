import CoreGraphics
import Foundation
import WindowSwitcherCore

enum ThumbnailCapture {
    static func permission() -> CapturePermission {
        if CGPreflightScreenCaptureAccess() {
            return .present
        }
        return .absent
    }

    /// One-shot capture for a window id. Never starts a continuous stream.
    static func image(windowNumber: UInt32, enabled: Bool) -> CGImage? {
        let decision = ThumbnailPolicy.decide(permission: permission(), thumbnailsEnabled: enabled)
        guard decision.attachImage else { return nil }
        let rect = CGRect.null
        let image = CGWindowListCreateImage(
            rect,
            .optionIncludingWindow,
            CGWindowID(windowNumber),
            [.boundsIgnoreFraming, .bestResolution]
        )
        return image
    }
}
