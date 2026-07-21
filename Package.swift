// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClawdBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "clawdbar", targets: ["ClawdBar"]),
    ],
    targets: [
        .target(name: "ClawdBarCore"),
        .executableTarget(name: "ClawdBar", dependencies: ["ClawdBarCore"]),
        .testTarget(name: "ClawdBarCoreTests", dependencies: ["ClawdBarCore"]),
    ]
)
