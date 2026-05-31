// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Handy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Handy", targets: ["Handy"]),
        .library(name: "HandyCore", targets: ["HandyCore"])
    ],
    targets: [
        .target(name: "HandyCore"),
        .executableTarget(
            name: "Handy",
            dependencies: ["HandyCore"]
        ),
        .testTarget(
            name: "HandyCoreTests",
            dependencies: ["HandyCore"]
        )
    ]
)
