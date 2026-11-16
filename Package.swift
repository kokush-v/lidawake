// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LidAwake",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LidAwake", targets: ["LidAwake"])
    ],
    targets: [
        .target(name: "LidAwakeCore"),
        .executableTarget(name: "LidAwake", dependencies: ["LidAwakeCore"]),
        .testTarget(name: "LidAwakeCoreTests", dependencies: ["LidAwakeCore"])
    ]
)
