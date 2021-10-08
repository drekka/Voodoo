// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import SwiftUI

let package = Package(
    name: "Simulcra",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "Simulcra",
            targets: ["Simulcra"]
        ),
    ],
    dependencies: [
        .package(name: "Nimble", url: "https://github.com/quick/nimble", branch: "main"),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "Simulcra",
            dependencies: [
                "Swifter",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SimulcraTests",
            dependencies: [
                "Simulcra",
                "Nimble",
            ],
            path: "Tests",
            resources: [
                .copy("Test files/Simple.json"),
                .copy("Test files/Invalid.json"),
                .copy("Test files/Simple.html"),
            ]
        ),
    ]
)
