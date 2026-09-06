// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShootIt",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "ShootIt", targets: ["ShootIt"])
    ],
    targets: [
        .executableTarget(
            name: "ShootIt",
            path: "Sources/ShootIt",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ScreenCaptureKit")
            ]
        ),
        .testTarget(
            name: "ShootItTests",
            dependencies: ["ShootIt"],
            path: "Tests/ShootItTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
