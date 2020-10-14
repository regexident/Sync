// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sync",
    products: [
        .library(
            name: "Sync",
            targets: [
                "Sync",
            ]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Sync",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "SyncTests",
            dependencies: [
                "Sync",
            ]
        ),
    ]
)
