// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TelegramBotAPI",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v6), .tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TelegramBotAPI",
            targets: ["TelegramBotAPI"]
        ),
        // AsyncHTTPClient implementation
        .library(name: "TelegramBotAPI_AHC", targets: ["TelegramBotAPI_AHC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        // .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TelegramBotAPI"
        ),
        .target(
            name: "TelegramBotAPI_AHC",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
            ],
            exclude: [
                "openapi.yaml",
                "original.yaml",
                "openapi-generator-config.yaml",
            ]
        ),
        .testTarget(
            name: "TelegramBotAPI_AHCTests",
            dependencies: ["TelegramBotAPI_AHC"],
            resources: [.copy("Resources")]
        ),
        .executableTarget(
            name: "Prepare",
            dependencies: []
        ),
        .testTarget(
            name: "TelegramBotAPITests",
            dependencies: ["TelegramBotAPI"]
        ),
    ]
)
