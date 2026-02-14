// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StatusDot",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "StatusDot",
            path: "Sources",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "StatusDotTests",
            dependencies: ["StatusDot"],
            path: "Tests"
        )
    ]
)
