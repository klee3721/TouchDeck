// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TouchDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TouchDeck", targets: ["TouchDeckApp"]),
        .library(name: "TouchDeckCore", targets: ["TouchDeckCore"]),
        .library(name: "TouchDeckRuntime", targets: ["TouchDeckRuntime"]),
        .library(name: "TouchDeckStudio", targets: ["TouchDeckStudio"])
    ],
    targets: [
        .target(
            name: "TouchDeckCore",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .target(
            name: "TouchDeckRuntime",
            dependencies: ["TouchDeckCore"]
        ),
        .target(
            name: "TouchDeckStudio",
            dependencies: [
                "TouchDeckCore",
                "TouchDeckRuntime"
            ]
        ),
        .executableTarget(
            name: "TouchDeckApp",
            dependencies: [
                "TouchDeckCore",
                "TouchDeckRuntime",
                "TouchDeckStudio"
            ]
        ),
        .testTarget(
            name: "TouchDeckCoreTests",
            dependencies: ["TouchDeckCore"]
        ),
        .testTarget(
            name: "TouchDeckStudioTests",
            dependencies: [
                "TouchDeckCore",
                "TouchDeckStudio"
            ]
        )
    ]
)
