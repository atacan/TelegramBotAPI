# TelegramBotAPI

A Swift package providing a strongly typed client for the Telegram Bot API, along with a SwiftLog backend that sends logs to Telegram chats.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2014%2B%20%7C%20iOS%2017%2B%20%7C%20watchOS%206%2B%20%7C%20tvOS%2013%2B-blue.svg)](https://developer.apple.com/swift/)

## Overview

This package provides two main components:

1. **TelegramBotAPI_AHC**: A fully typed Swift client for the Telegram Bot API, generated from the official OpenAPI specification and using AsyncHTTPClient for networking.

2. **LoggingToTelegram**: A SwiftLog backend that allows you to send your application logs directly to a Telegram chat, making it easy to monitor your application remotely.

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, watchOS 6+, or tvOS 13+
- [Swift-Log](https://github.com/apple/swift-log) (included as a dependency)
- [AsyncHTTPClient](https://github.com/swift-server/async-http-client) (included as a dependency)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    // For the Telegram Bot API client only
    .package(url: "https://github.com/yourusername/TelegramBotAPI", from: "1.0.0"),
    
    // If you also need the logging component
    // Note: This is automatically included when you depend on LoggingToTelegram
    .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
]

targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            // For the Telegram Bot API client only
            .product(name: "TelegramBotAPI_AHC", package: "TelegramBotAPI"),
            
            // For the logging component
            .product(name: "LoggingToTelegram", package: "TelegramBotAPI"),
        ]
    )
]
```

## Usage

### TelegramBotAPI_AHC

The `TelegramBotAPI_AHC` module provides a type-safe client for interacting with the Telegram Bot API.

```swift
import TelegramBotAPI_AHC
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import HTTPTypes
import Foundation

// Setup the client
let botToken = "YOUR_BOT_TOKEN"
let serverURL = URL(string: "https://api.telegram.org/bot\(botToken)")!

let client = Client(
    serverURL: serverURL,
    transport: AsyncHTTPClientTransport(),
    middlewares: []
)

// Example: Send a message
do {
    let chatId = "CHAT_ID"
    let message = "Hello from Swift!"
    
    let response = try await client.postSendMessage(
        .init(
            body: .json(
                .init(
                    chatId: .init(value2: chatId),
                    text: message
                )
            )
        )
    )
    
    print("Message sent: \(response.body)")
} catch {
    print("Failed to send message: \(error)")
}

// Example: Send formatted message with Markdown
do {
    let chatId = "CHAT_ID"
    let message = """
    __*Important Message:*__
    
    ```swift
    func helloWorld() {
        print("Hello, World!")
    }
    ```
    """
    
    let response = try await client.postSendMessage(
        .init(
            body: .json(
                .init(
                    chatId: .init(value2: chatId),
                    text: message,
                    parseMode: "MarkdownV2"
                )
            )
        )
    )
    
    print("Formatted message sent: \(response.body)")
} catch {
    print("Failed to send formatted message: \(error)")
}
```

### LoggingToTelegram

The `LoggingToTelegram` module allows you to send your application logs to a Telegram chat.

```swift
import AsyncHTTPClient
import Logging
import LoggingToTelegram
import TelegramBotAPI_AHC
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import HTTPTypes
import Foundation
import SwiftLogExport

// Setup the client
let botToken = "YOUR_BOT_TOKEN"
let chatId = "CHAT_ID"

let serverURL = URL(string: "https://api.telegram.org/bot\(botToken)")!

let telegramClient = Client(
    serverURL: serverURL,
    transport: AsyncHTTPClientTransport(),
    middlewares: []
)

// Create the exporter
let telegramExporter = TelegramLogRecordExporter(client: telegramClient, chatId: chatId)

// Create the processor
let batchProcessor = BatchLogRecordProcessor(
    exporter: telegramExporter,
    configuration: .init()  // Use default configuration or customize
)

// Create a logger configured with the TelegramLoggingHandler
let logger = Logger(label: "YourApp") { label in
    // This factory creates the handler using the shared processor
    TelegramLoggingHandler(
        label: label,
        processor: batchProcessor
    )
}

// Start the processor in the background
Task {
    try await batchProcessor.run()
}

// Use the logger
logger.info("Application started")
logger.warning("Something to watch out for", metadata: ["key": "value"])
logger.error("Something went wrong", metadata: ["error_code": "500"])

// When you're done (e.g., application shutdown)
// Cancel the processor task
```

## Features

### TelegramBotAPI_AHC

- Complete type-safe wrapper for all Telegram Bot API methods
- Generated from the official OpenAPI specification
- Async/await API design
- Built on AsyncHTTPClient for efficient networking
- Support for Markdown and HTML formatting

### LoggingToTelegram

- SwiftLog compatible logging backend
- Sends formatted log messages to a Telegram chat
- Supports log levels, metadata, and source location information
- Batches log messages for efficient delivery
- Markdown formatting for better readability

## Advanced Configuration

### TelegramBotAPI Client Configuration

The Telegram Bot API client can be configured with custom middleware or HTTP client settings:

```swift
import TelegramBotAPI_AHC
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import HTTPTypes
import Foundation

// Setup with custom configuration
let botToken = "YOUR_BOT_TOKEN"
let serverURL = URL(string: "https://api.telegram.org/bot\(botToken)")!

// Create custom middleware if needed
let loggingMiddleware = // Your custom middleware implementation

let client = Client(
    serverURL: serverURL,
    transport: AsyncHTTPClientTransport(),
    middlewares: [loggingMiddleware]
)

// Use the client...
```

### LoggingToTelegram Configuration

The `BatchLogRecordProcessor` can be configured with custom settings:

```swift
let batchProcessor = BatchLogRecordProcessor(
    exporter: telegramExporter,
    configuration: .init(
        maxQueueSize: 2048,         // Maximum number of records to buffer
        scheduledDelay: .seconds(5), // How often to send batches
        exportTimeout: .seconds(30), // How long to wait for export before timing out
        maxExportBatchSize: 512      // Maximum number of records to export at once
    )
)
```

## License

This package is available under the [MIT License](LICENSE).

## Credits

- Generated using the [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- The openapi schema is from [tdlight-team/tdlight-telegram-bot-api](https://github.com/tdlight-team/tdlight-telegram-bot-api/blob/master/LICENSE_1_0.txt). See its license for more details.
- Powered by [AsyncHTTPClient](https://github.com/swift-server/async-http-client) and [Swift-Log](https://github.com/apple/swift-log)
