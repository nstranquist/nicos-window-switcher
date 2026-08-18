import Foundation

public enum CapturePermission: String, Codable, Sendable, Equatable {
    case absent
    case present
    case unknown
}

public struct ThumbnailDecision: Codable, Sendable, Equatable {
    public var attachImage: Bool
    public var listAndFocusAllowed: Bool
    public var reason: String

    public init(attachImage: Bool, listAndFocusAllowed: Bool, reason: String) {
        self.attachImage = attachImage
        self.listAndFocusAllowed = listAndFocusAllowed
        self.reason = reason
    }
}

/// Capture is opt-in and never required for list or focus.
public enum ThumbnailPolicy {
    public static func decide(permission: CapturePermission, thumbnailsEnabled: Bool) -> ThumbnailDecision {
        if !thumbnailsEnabled {
            return ThumbnailDecision(
                attachImage: false,
                listAndFocusAllowed: true,
                reason: "thumbnails disabled"
            )
        }
        switch permission {
        case .present:
            return ThumbnailDecision(
                attachImage: true,
                listAndFocusAllowed: true,
                reason: "capture present"
            )
        case .absent:
            return ThumbnailDecision(
                attachImage: false,
                listAndFocusAllowed: true,
                reason: "capture absent; list and focus still allowed"
            )
        case .unknown:
            return ThumbnailDecision(
                attachImage: false,
                listAndFocusAllowed: true,
                reason: "capture unknown; do not block list or focus"
            )
        }
    }

    /// Attach a caller-supplied image payload only when policy allows it.
    public static func attachedImage<Image>(
        permission: CapturePermission,
        thumbnailsEnabled: Bool,
        image: Image?
    ) -> Image? {
        let decision = decide(permission: permission, thumbnailsEnabled: thumbnailsEnabled)
        guard decision.attachImage else { return nil }
        return image
    }
}
