import AsyncHTTPClient
import Logging
import Foundation
import HTTPTypes
import LoggingToTelegram
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import SwiftLogExport
import TelegramBotAPI_AHC
import Testing

struct LoggingToTelegramTests {
    let telegramClient = {
        // get api key from environment
        let botToken = getEnvironmentVariable("BOT_TOKEN")!

        let serverURL = URL(string: "https://api.telegram.org/bot\(botToken)")!

        return Client(
            serverURL: serverURL,
            transport: AsyncHTTPClientTransport(),
            middlewares: []
        )
    }()

    @Test
    func testExample() async throws {
        let chatId = getEnvironmentVariable("CHAT_ID")!
        let telegramExporter = TelegramLogRecordExporter(client: telegramClient, chatId: chatId)
        let batchProcessor = BatchLogRecordProcessor(
            exporter: telegramExporter,
            configuration: .init()  // Use default configuration or customize
                // clock: .continuous // Default clock
        )

        let logger = Logger(label: "YourApp") { label in
            // This factory creates the handler using the shared processor
            TelegramLoggingHandler(
                label: label,
                processor: batchProcessor
            )
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await batchProcessor.run()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(0.5))
                logger.info(###"""
                *bold \*text*
                _italic \*text_
                __underline__
                ~strikethrough~
                ||spoiler||
                *bold _italic bold ~italic bold strikethrough ||italic bold strikethrough spoiler||~ __underline italic bold___ bold*
                [inline URL](http://www.example.com/)
                [inline mention of a user](tg://user?id=123456789)
                ![👍](tg://emoji?id=5368324170671202286)
                `inline fixed-width code`
                ```
                pre-formatted fixed-width code block
                ```
                ```python
                pre-formatted fixed-width code block written in the Python programming language
                ```
                >Block quotation started
                >Block quotation continued
                >Block quotation continued
                >Block quotation continued
                >The last line of the block quotation
                **>The expandable block quotation started right after the previous block quotation
                >It is separated from the previous block quotation by an empty bold entity
                >Expandable block quotation continued
                >Hidden by default part of the expandable block quotation started
                >Expandable block quotation continued
                >The last line of the expandable block quotation with the expandability mark||
                """###, 
                metadata: ["key": "value", "key2": "value2", "key3": "value3"])
            }

            try await Task.sleep(for: .seconds(2.3))
            group.cancelAll()
        }

    }
}
