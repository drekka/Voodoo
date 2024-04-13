// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

_ = Package(
    name: "Voodoo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .executable(name: "voodoo", targets: ["VoodooCLI"]),
        .library(name: "Voodoo", targets: ["Voodoo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/quick/nimble", .upToNextMajor(from: "13.0.0")),
        .package(url: "https://github.com/hummingbird-project/hummingbird", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/hummingbird-project/hummingbird-mustache", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/jectivex/JXKit", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0"),
        .package(url: "https://github.com/GraphQLSwift/GraphQL", from: "2.0.0"),

    ],
    targets: [
        .target(
            name: "Voodoo",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),
                .product(name: "HummingbirdMustache", package: "hummingbird-mustache"),
                "JXKit",
                "Yams",
                "AnyCodable",
                "GraphQL",
            ],
            path: "Sources"
        ),
        .executableTarget(
            name: "VoodooCLI",
            dependencies: [
                "Voodoo",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "cmd"
        ),
        .testTarget(
            name: "VoodooTests",
            dependencies: [
                "Voodoo",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Nimble", package: "nimble"),
            ],
            path: "Tests",
            resources: [
                .copy("files"),
            ]
        ),
    ]
)
