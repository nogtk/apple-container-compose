// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "apple-container-compose",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "apple-container-compose", targets: ["AppleCompose"]),
        .library(name: "AppleComposeCore", targets: ["AppleComposeCore"])
    ],
    targets: [
        .executableTarget(
            name: "AppleCompose",
            dependencies: ["AppleComposeCore"]
        ),
        .target(name: "AppleComposeCore"),
        .testTarget(
            name: "AppleComposeCoreTests",
            dependencies: ["AppleComposeCore"]
        )
    ]
)
