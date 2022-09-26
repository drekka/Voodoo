// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Simulcra",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "simulcra", targets: ["SimulcraCMD"]),
        .library(name: "Simulcra", targets: ["Simulcra"]),
    ],
    dependencies: [
        .package(name: "Nimble", url: "https://github.com/quick/nimble", .upToNextMajor(from: "10.0.0")),
        .package(name: "Hummingbird", url: "https://github.com/hummingbird-project/hummingbird", branch: "main"),
        .package(name: "HummingbirdMustache", url: "https://github.com/hummingbird-project/hummingbird-mustache", .upToNextMajor(from: "1.0.0")),
        .package(name: "JXKit", url: "https://github.com/jectivex/JXKit.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SimulcraCMD",
            dependencies: [
                "Simulcra",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "cmd"
        ),
        .target(
            name: "Simulcra",
            dependencies: [
                "Hummingbird",
                "HummingbirdMustache",
                "JXKit",
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
                .copy("Test files/Template.json"),
            ]
        ),
    ]
)
