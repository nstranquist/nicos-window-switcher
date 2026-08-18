import ApplicationServices
import AppKit
import Foundation
import WindowSwitcherCore

enum WindowFocuser {
    enum FocusError: Error, CustomStringConvertible {
        case accessibilityDenied
        case windowNotFound
        case activateFailed

        var description: String {
            switch self {
            case .accessibilityDenied:
                return "Accessibility permission denied"
            case .windowNotFound:
                return "no AX window matched the focus target"
            case .activateFailed:
                return "could not activate the owning application"
            }
        }
    }

    static var accessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func focus(_ target: FocusTarget, dryRun: Bool) throws -> String {
        if dryRun {
            return "dry-run \(target.windowID) pid=\(target.pid) app=\(target.appName) title=\(target.title)"
        }
        guard accessibilityTrusted else { throw FocusError.accessibilityDenied }
        guard let running = NSRunningApplication(processIdentifier: target.pid) else {
            throw FocusError.activateFailed
        }
        running.activate(options: [.activateAllWindows])
        let app = AXUIElementCreateApplication(target.pid)
        guard let element = findWindow(app: app, target: target) else {
            throw FocusError.windowNotFound
        }
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        return "focused \(target.windowID)"
    }

    private static func findWindow(app: AXUIElement, target: FocusTarget) -> AXUIElement? {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value)
        guard status == .success, let windows = value as? [AXUIElement] else { return nil }
        let primaryHeight = NSScreen.screens.map(\.frame.maxY).max() ?? NSScreen.main?.frame.height ?? 0
        let snapshots = windows.map { snapshot(from: $0, primaryHeight: primaryHeight) }
        guard let index = AXWindowMatcher.matchIndex(target: target, windows: snapshots) else {
            return nil
        }
        return windows[index]
    }

    static func snapshot(from element: AXUIElement, primaryHeight: CGFloat) -> AXWindowSnapshot {
        let title = axString(element, kAXTitleAttribute)
        let origin = axPoint(element, kAXPositionAttribute)
        let size = axSize(element, kAXSizeAttribute)
        let bounds = ScreenCoordinates.quartzBounds(
            cocoaX: origin.x,
            cocoaY: origin.y,
            width: size.width,
            height: size.height,
            primaryHeight: Double(primaryHeight)
        )
        return AXWindowSnapshot(title: title, bounds: bounds, windowNumber: nil)
    }

    private static func axString(_ element: AXUIElement, _ attribute: String) -> String {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success else { return "" }
        return (value as? String) ?? ""
    }

    private static func axPoint(_ element: AXUIElement, _ attribute: String) -> CGPoint {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success, let axValue = value else { return .zero }
        var point = CGPoint.zero
        if AXValueGetValue(axValue as! AXValue, .cgPoint, &point) {
            return point
        }
        return .zero
    }

    private static func axSize(_ element: AXUIElement, _ attribute: String) -> CGSize {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success, let axValue = value else { return .zero }
        var size = CGSize.zero
        if AXValueGetValue(axValue as! AXValue, .cgSize, &size) {
            return size
        }
        return .zero
    }
}
