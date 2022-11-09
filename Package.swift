// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Voodoo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .executable(name: "magic", targets: ["magic"]),
        .library(name: "Voodoo", targets: ["Voodoo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/quick/nimble", .upToNextMajor(from: "10.0.0")),
        .package(url: "https://github.com/hummingbird-project/hummingbird", branch: "main"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-mustache", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/drekka/JXKit.git", branch: "feature/decoding-urls"),
//        .package(url: "https://github.com/jectivex/JXKit.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0"),
//        .package(url: "https://github.com/drekka/AnyCodable", branch: "develop/dc-missing-string-interpolation"),
//        .package(url: "https://github.com/drekka/GraphQL", branch: "feature/Public-visitor"),
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
            name: "magic",
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
