import AppKit
import SwiftUI
import WindowSwitcherCore

@MainActor
final class OverlayController: NSObject {
    private var panel: NSPanel?
    private var hosting: NSHostingView<OverlayView>?
    private var session = SwitcherSession()
    private let config: SwitcherConfig
    private var typingMonitor: Any?
    private var localTypingMonitor: Any?

    init(config: SwitcherConfig) {
        self.config = config
    }

    var isShowing: Bool { session.isShowing }

    func handleNext() {
        if session.isShowing {
            session.cycleNext()
        } else {
            let records = WindowEnumerator.records(
                config: config,
                excludingPID: ProcessInfo.processInfo.processIdentifier
            )
            session.begin(windows: records)
        }
        present()
    }

    func handlePrev() {
        if !session.isShowing {
            handleNext()
            return
        }
        session.cyclePrev()
        present()
    }

    func handleRelease() {
        guard session.isShowing else { return }
        let record = session.commit()
        hide()
        guard let record else { return }
        let target = FocusMapper.target(for: record)
        _ = try? WindowFocuser.focus(target, dryRun: false)
    }

    func applyQuery(_ query: String) {
        session.setQuery(query)
        present()
    }

    /// Session-scoped keyDown path. Global/local monitors call this so letters
    /// update the query even while the panel is nonactivating.
    @discardableResult
    func handleSessionKey(_ input: SessionKeyInput) -> SessionKeyOutcome {
        let outcome = SessionKeyHandler.apply(input, to: &session)
        switch outcome {
        case .updated:
            present()
        case .cancelled:
            hide()
        case .ignored:
            break
        }
        return outcome
    }

    func cancel() {
        session.cancel()
        hide()
    }

    func present() {
        let view = OverlayView(
            windows: session.windows,
            selectedID: session.selected?.id,
            query: session.query,
            capturePermission: ThumbnailCapture.permission(),
            thumbnailsEnabled: config.thumbnailsEnabled,
            onQuery: { [weak self] query in self?.applyQuery(query) }
        )

        if panel == nil {
            let hosting = NSHostingView(rootView: view)
            self.hosting = hosting
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 760, height: 420),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled],
                backing: .buffered,
                defer: false
            )
            panel.title = "Nicos Window Switcher"
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            panel.isMovableByWindowBackground = true
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.becomesKeyOnlyIfNeeded = false
            panel.contentView = hosting
            self.panel = panel
        } else {
            hosting?.rootView = view
        }
        if HeadlessSupport.isHeadless {
            HeadlessSupport.parkOffscreen(panel)
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = panel?.frame.size ?? NSSize(width: 760, height: 420)
            let origin = NSPoint(
                x: frame.midX - size.width / 2,
                y: frame.midY - size.height / 2
            )
            panel?.setFrameOrigin(origin)
        }
        panel?.orderFrontRegardless()
        panel?.makeKey()
        startTypingCapture()
    }

    func hide() {
        stopTypingCapture()
        session.cancel()
        panel?.orderOut(nil)
    }

    private func startTypingCapture() {
        guard typingMonitor == nil else { return }
        typingMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.consumeKey(event)
        }
        localTypingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.consumeKey(event) { return nil }
            return event
        }
    }

    private func stopTypingCapture() {
        if let typingMonitor { NSEvent.removeMonitor(typingMonitor) }
        if let localTypingMonitor { NSEvent.removeMonitor(localTypingMonitor) }
        typingMonitor = nil
        localTypingMonitor = nil
    }

    @discardableResult
    private func consumeKey(_ event: NSEvent) -> Bool {
        guard session.isShowing else { return false }
        let input = SessionKeyHandler.input(
            characters: event.charactersIgnoringModifiers ?? event.characters ?? "",
            keyCode: event.keyCode,
            command: event.modifierFlags.contains(.command)
        )
        let outcome = handleSessionKey(input)
        return outcome != .ignored
    }
}
