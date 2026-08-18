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

        let wantedTitle = target.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !wantedTitle.isEmpty {
            for window in windows {
                if axString(window, kAXTitleAttribute) == wantedTitle {
                    return window
                }
            }
            for window in windows {
                if axString(window, kAXTitleAttribute).localizedCaseInsensitiveContains(wantedTitle) {
                    return window
                }
            }
        }
        return windows.first
    }

    private static func axString(_ element: AXUIElement, _ attribute: String) -> String {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success else { return "" }
        return (value as? String) ?? ""
    }
}
