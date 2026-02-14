// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StatusDot",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "StatusDot",
            path: "Sources"
        )
    ]
)
