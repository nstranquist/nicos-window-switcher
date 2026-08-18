import WindowSwitcherCore

enum Fixtures {
    static func window(
        number: UInt32,
        pid: Int32,
        app: String,
        title: String,
        layer: Int = 0,
        onscreen: Bool = true,
        alpha: Double = 1,
        width: Double = 800,
        height: Double = 600,
        selfWindow: Bool = false,
        bundleID: String = ""
    ) -> RawWindowSnapshot {
        RawWindowSnapshot(
            windowNumber: number,
            ownerPID: pid,
            ownerName: app,
            title: title,
            layer: layer,
            isOnscreen: onscreen,
            alpha: alpha,
            bounds: WindowBounds(x: 10, y: 10, width: width, height: height),
            isSwitcherSelf: selfWindow,
            bundleID: bundleID
        )
    }

    static func desktop() -> [RawWindowSnapshot] {
        [
            window(number: 10, pid: 101, app: "Safari", title: "Inbox — Mail", bundleID: "com.apple.Safari"),
            window(number: 11, pid: 101, app: "Safari", title: "AltTab — Features", bundleID: "com.apple.Safari"),
            window(number: 20, pid: 202, app: "Cursor", title: "nicos-tools", bundleID: "com.todesktop.230313mzl4w4u92"),
            window(number: 30, pid: 303, app: "Notes", title: "Scratch", bundleID: "com.apple.Notes"),
            window(number: 40, pid: 404, app: "UTM", title: "Windows VM", bundleID: "com.utmapp.UTM"),
            window(number: 50, pid: 505, app: "Nicos Window Switcher", title: "Switcher", selfWindow: true),
            window(number: 60, pid: 606, app: "Dock", title: "", layer: 25),
            window(number: 70, pid: 707, app: "Finder", title: "Downloads", onscreen: false),
            window(number: 80, pid: 808, app: "Ghost", title: "gone", alpha: 0),
        ]
    }

    static func records() -> [WindowRecord] {
        WindowListNormalizer.normalizeAll(desktop())
    }
}
