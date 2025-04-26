import SwiftLogExport
import Logging // Need this for Logger types
import TelegramBotAPI_AHC // Need this for the Telegram client
import Foundation // Added for DateFormatter

// 1. Define the LogRecord conforming type
public struct TelegramLogRecord: LogRecord, Equatable, Sendable {
    public var message: Logger.Message
    public var level: Logger.Level
    public var metadata: Logger.Metadata
    // Add any other relevant info, like timestamp if needed for formatting
    public var timestamp: Date
    // swift-log standard fields
    public var source: String
    public var file: String
    public var function: String
    public var line: UInt

    // Initializer matching DefaultLogRecord for convenience
    init(
        message: Logger.Message,
        level: Logger.Level,
        metadata: Logger.Metadata,
        source: String,
        file: String,
        function: String,
        line: UInt,
        timestamp: Date
    ) {
        self.message = message
        self.level = level
        self.metadata = metadata
        self.source = source
        self.file = file
        self.function = function
        self.line = line
        self.timestamp = timestamp
    }
}

// 2. Define the LogRecordExporter
public struct TelegramLogRecordExporter: LogRecordExporter, Sendable {
    public typealias T = TelegramLogRecord

    private let client: Client // Telegram Client
    private let chatId: String // Target chat ID

    // 8. Add initialization
    public init(client: Client, chatId: String) {
        self.client = client
        self.chatId = chatId
    }

    // 4. Implement export
    public func export(_ batch: some Collection<T> & Sendable) async throws {
        // TODO: Implement formatting and sending logic
        for record in batch {
            let formattedMessage = formatRecord(record)
            // Use the client to send the message
            _ = try await client.post_sol_sendMessage(
                .init(
                    body: .json(
                        .init(
                            chat_id: .init(value2: self.chatId),
                            text: formattedMessage,
                            parse_mode: "MarkdownV2" // Or another mode if preferred
                        )
                    )
                )
            )
            // Consider adding delays or batching multiple messages into one Telegram message if needed
        }
    }

    // 5. Implement forceFlush (empty)
    public func forceFlush() async throws {
        // No buffering, so nothing to flush
    }

    // 6. Implement shutdown (empty)
    public func shutdown() async {
        // Nothing specific to shut down for now
    }

    // Helper function for formatting
    private func formatRecord(_ record: T) -> String {
        // Basic formatting, enhance as needed
        let timestamp = record.timestamp
        // Simple date format, adjust as needed
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current // Or UTC, etc.
        let timestampString = escapeMarkdownV2(dateFormatter.string(from: timestamp))

        let levelString = escapeMarkdownV2(record.level.rawValue.uppercased())
        // let messageString = escapeMarkdownV2(record.message.description)
        let messageString = record.message.description
        // Format source location
        let fileString = escapeMarkdownV2(record.file)
        let functionString = escapeMarkdownV2(record.function)
        let lineString = escapeMarkdownV2("\(record.line)")
        let sourceLocation = "\(fileString):\(lineString) \\- `\(functionString)`"

        // Improved metadata formatting
        let metadataString: String
        if record.metadata.isEmpty {
            metadataString = ""
        } else {
            // Format metadata dictionary nicely
            let formattedMetadata = record.metadata
                .map { key, value in "\(escapeMarkdownV2(key)): \(escapeMarkdownV2("\(value)"))" }
                .sorted(by: <)
                .joined(separator: "\n")
            metadataString = "\n\n*Metadata:*\n```\n\(formattedMetadata)\n```"
        }

        return """
        *\(levelString)* \\| \(timestampString)

        \(messageString)\(metadataString)

        \(sourceLocation)
        """
    }

    // Reusing the escape function (could be moved to a shared utility location)
    private func escapeMarkdownV2(_ text: String) -> String {
        // Note: Telegram MarkdownV2 requires escaping characters like '-', '=', '|', '{', '}', '.', '!'
        // Ensure all required characters are included.
        let specialCharacters = ["_", "*", "[", "]", "(", ")", "~", "`", ">", "#", "+", "-", "=", "|", "{", "}", ".", "!"]
        var escapedText = text
        for char in specialCharacters {
            escapedText = escapedText.replacingOccurrences(of: char, with: "\\" + char)
        }
        return escapedText
    }
}
