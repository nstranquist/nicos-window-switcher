import AppKit
import SwiftUI
import WindowSwitcherCore

struct OverlayView: View {
    var windows: [WindowRecord]
    var selectedID: String?
    var query: String
    var capturePermission: CapturePermission
    var thumbnailsEnabled: Bool
    var onQuery: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Filter windows", text: Binding(
                get: { query },
                set: { onQuery($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 16, weight: .medium))

            if windows.isEmpty {
                Text("No windows")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                        ForEach(windows) { window in
                            tile(window)
                        }
                    }
                    .padding(4)
                }
            }
        }
        .padding(16)
        .frame(width: 760, height: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func tile(_ window: WindowRecord) -> some View {
        let selected = window.id == selectedID
        VStack(alignment: .leading, spacing: 6) {
            tileImage(window)
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            Text(window.displayTitle)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
            Text(window.appName)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private func tileImage(_ window: WindowRecord) -> some View {
        let decision = ThumbnailPolicy.decide(
            permission: capturePermission,
            thumbnailsEnabled: thumbnailsEnabled
        )
        if decision.attachImage, let cgImage = ThumbnailCapture.image(
            windowNumber: window.windowNumber,
            enabled: thumbnailsEnabled
        ) {
            Image(decorative: cgImage, scale: 1, orientation: .up)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(nsImage: appIcon(for: window))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(12)
        }
    }

    private func appIcon(for window: WindowRecord) -> NSImage {
        if let running = NSRunningApplication(processIdentifier: window.ownerPID),
           let icon = running.icon
        {
            return icon
        }
        return NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app")
    }
}
