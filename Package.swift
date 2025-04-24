// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HexaSphereGrid",
    platforms: [
        .iOS(.v15), // ✅ ajoute ça pour supporter SwiftUI moderne
    ],
    products: [
        .library(
            name: "HexaSphereGrid",
            targets: ["HexaSphereGrid"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HexaSphereGrid",
            dependencies: [],
            path: "Sources/HexaSphereGrid"
        ),
        .testTarget(
            name: "HexaSphereGridTests",
            dependencies: ["HexaSphereGrid"]
        ),
    ]
)
