// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "local-memo",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "local-memo", targets: ["local-memo"]),
        .library(name: "LocalMemoKit", targets: ["LocalMemoKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Ryu0118/swift-interaction", from: "0.2.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.2"),
        .package(url: "https://github.com/Ryu0118/FileManagerProtocol", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "local-memo",
            dependencies: [
                "LocalMemoCLI",
            ],
        ),
        .target(
            name: "LocalMemoCLI",
            dependencies: [
                "LocalMemoKit",
                .product(name: "Interaction", package: "swift-interaction"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
        ),
        .target(
            name: "LocalMemoKit",
            dependencies: [
                .product(name: "Interaction", package: "swift-interaction"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
        ),
        .testTarget(
            name: "LocalMemoKitTests",
            dependencies: [
                "LocalMemoKit",
                .product(name: "Interaction", package: "swift-interaction"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
        ),
        .testTarget(
            name: "LocalMemoCLITests",
            dependencies: [
                "LocalMemoCLI",
                "LocalMemoKit",
            ],
        ),
    ],
)
