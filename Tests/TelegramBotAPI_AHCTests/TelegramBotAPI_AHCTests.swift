import Foundation
import HTTPTypes
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import Testing

@testable import TelegramBotAPI_AHC

#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Date
#endif

final class TelegramBotAPI_AHCTests {
    let client = {
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
    func sendMessageToAnExistingChat() async throws {
        let chatId = getEnvironmentVariable("CHAT_ID")!
        let message = "Hello, World!"
        let response = try await client.post_sol_sendMessage(
            .init(
                body: .json(
                    .init(
                        chat_id: .init(value2: chatId),
                        text: message
                    )
                )
            )
        )

        dump(response)
    }
}
