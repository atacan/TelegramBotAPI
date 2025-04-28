// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TelegramBotAPI",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v6), .tvOS(.v13)],
    products: [
        // AsyncHTTPClient implementation
        .library(name: "TelegramBotAPI_AHC", targets: ["TelegramBotAPI_AHC"]),
        .library(name: "LoggingToTelegram", targets: ["LoggingToTelegram"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
        // .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.1.0"),
        .package(url: "https://github.com/atacan/SwiftLogExport", branch: "main"),
        // .package(path: "../SwiftLogExport"),
    ],
    targets: [
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
        .target(
            name: "LoggingToTelegram",
            dependencies: [
                "TelegramBotAPI_AHC",
                .product(name: "SwiftLogExport", package: "SwiftLogExport"),
            ]
        ),
        .testTarget(
            name: "TelegramBotAPI_AHCTests",
            dependencies: ["TelegramBotAPI_AHC"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "LoggingToTelegramTests",
            dependencies: ["LoggingToTelegram"],
        ),
        .executableTarget(
            name: "Prepare",
            dependencies: []
        ),
    ]
)
