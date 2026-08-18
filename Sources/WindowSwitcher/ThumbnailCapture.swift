import CoreGraphics
import Foundation
import ScreenCaptureKit
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
        return captureOnce(windowNumber: windowNumber)
    }

    static func captureOnce(windowNumber: UInt32) -> CGImage? {
        let box = CaptureBox()
        let sem = DispatchSemaphore(value: 0)
        Task {
            box.image = await captureSC(windowNumber: windowNumber)
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 1.5)
        return box.image
    }

    private static func captureSC(windowNumber: UInt32) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let window = content.windows.first(where: { $0.windowID == CGWindowID(windowNumber) }) else {
                return nil
            }
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            let width = max(Int(window.frame.width), 160)
            let height = max(Int(window.frame.height), 90)
            config.width = width
            config.height = height
            config.showsCursor = false
            config.capturesAudio = false
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            return nil
        }
    }
}

private final class CaptureBox: @unchecked Sendable {
    var image: CGImage?
}
