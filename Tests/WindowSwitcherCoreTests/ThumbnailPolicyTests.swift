import Testing
import WindowSwitcherCore

@Suite("ThumbnailPolicy")
struct ThumbnailPolicyTests {
    @Test("list and focus stay allowed when capture is absent")
    func absentStillLists() {
        let decision = ThumbnailPolicy.decide(permission: .absent, thumbnailsEnabled: true)
        #expect(decision.listAndFocusAllowed)
        #expect(decision.attachImage == false)
        #expect(decision.reason.contains("absent"))
    }

    @Test("capture present attaches an image when enabled")
    func presentAttaches() {
        let decision = ThumbnailPolicy.decide(permission: .present, thumbnailsEnabled: true)
        #expect(decision.listAndFocusAllowed)
        #expect(decision.attachImage)
        let attached = ThumbnailPolicy.attachedImage(
            permission: .present,
            thumbnailsEnabled: true,
            image: "png-bytes"
        )
        #expect(attached == "png-bytes")
    }

    @Test("disabled thumbnails never attach even when capture is present")
    func disabledNeverAttaches() {
        let decision = ThumbnailPolicy.decide(permission: .present, thumbnailsEnabled: false)
        #expect(decision.listAndFocusAllowed)
        #expect(decision.attachImage == false)
        let attached = ThumbnailPolicy.attachedImage(
            permission: .present,
            thumbnailsEnabled: false,
            image: "png-bytes"
        )
        #expect(attached == nil)
    }

    @Test("unknown permission does not block list or focus")
    func unknownAllows() {
        let decision = ThumbnailPolicy.decide(permission: .unknown, thumbnailsEnabled: true)
        #expect(decision.listAndFocusAllowed)
        #expect(decision.attachImage == false)
    }
}
