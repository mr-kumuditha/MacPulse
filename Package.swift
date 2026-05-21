// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPulse",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacPulse", targets: ["MacPulse"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacPulse",
            path: "MacPulse",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MacPulseTests",
            dependencies: ["MacPulse"],
            path: "MacPulseTests"
        )
    ]
)
