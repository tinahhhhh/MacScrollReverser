// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ScrollReverser",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "ScrollReverser", targets: ["ScrollReverser"])
    ],
    dependencies: [
        // No external dependencies
    ],
    targets: [
        .executableTarget(
            name: "ScrollReverser",
            dependencies: [],
            path: ".",
            sources: ["main.swift", "AppDelegate.swift", "LaunchAtLogin.swift"],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
