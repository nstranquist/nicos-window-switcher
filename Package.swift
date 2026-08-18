// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WindowSwitcher",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WindowSwitcherCore", targets: ["WindowSwitcherCore"]),
        .executable(name: "WindowSwitcher", targets: ["WindowSwitcher"]),
    ],
    targets: [
        .target(
            name: "WindowSwitcherCore",
            path: "Sources/WindowSwitcherCore"
        ),
        .executableTarget(
            name: "WindowSwitcher",
            dependencies: ["WindowSwitcherCore"],
            path: "Sources/WindowSwitcher"
        ),
        .testTarget(
            name: "WindowSwitcherCoreTests",
            dependencies: ["WindowSwitcherCore"],
            path: "Tests/WindowSwitcherCoreTests"
        ),
    ]
)
