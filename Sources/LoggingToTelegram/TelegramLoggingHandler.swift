import Foundation // For Date
import Logging // For LogHandler, Logger types etc.
import SwiftLogExport // For LogRecordProcessor protocol (used by BatchLogRecordProcessor)
// Assuming BatchLogRecordProcessor and TelegramLogRecordExporter are in the same module or imported
// Assuming TelegramLogRecord is also available

/// A `LogHandler` that formats log messages and sends them to a Telegram chat
/// via a `BatchLogRecordProcessor` using a `TelegramLogRecordExporter`.
public struct TelegramLoggingHandler: LogHandler {
    // MARK: - Properties

    /// The label identifying this logger instance. Often corresponds to the `Logger`'s label.
    private let label: String

    /// The shared batch processor that handles buffering and exporting log records.
    /// This MUST be shared across handler instances derived from the same initial bootstrap
    /// or configuration to ensure logs go to the same batcher.
    private let processor: BatchLogRecordProcessor<TelegramLogRecord, TelegramLogRecordExporter, ContinuousClock>

    /// The specific log level for this handler instance. Messages below this level will be ignored.
    /// Stored directly in the struct to ensure value semantics.
    public var logLevel: Logger.Level

    /// Metadata associated with this specific handler instance.
    /// Stored directly in the struct to ensure value semantics.
    public var metadata: Logger.Metadata

    /// An optional provider for adding metadata dynamically (e.g., from task-local storage).
    /// Stored directly in the struct to ensure value semantics.
    public var metadataProvider: Logger.MetadataProvider?

    // MARK: - Initialization

    /// Creates a `TelegramLoggingHandler`.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - processor: The **shared** `BatchLogRecordProcessor` instance responsible for handling `TelegramLogRecord`s.
    ///   - level: The initial minimum log level for this handler instance. Defaults to `.info`.
    ///   - metadata: Initial metadata for this handler instance. Defaults to empty.
    ///   - metadataProvider: An optional `Logger.MetadataProvider`. Defaults to `nil`.
    public init(
        label: String,
        processor: BatchLogRecordProcessor<TelegramLogRecord, TelegramLogRecordExporter, ContinuousClock>,
        level: Logger.Level = .info,
        metadata: Logger.Metadata = [:],
        metadataProvider: Logger.MetadataProvider? = nil
    ) {
        self.label = label
        self.processor = processor
        self.logLevel = level
        self.metadata = metadata
        self.metadataProvider = metadataProvider
    }

    // MARK: - LogHandler Conformance

    /// The core logging function. Called by `Logger` when a message should be logged.
    ///
    /// This function creates a `TelegramLogRecord` and passes it to the underlying processor.
    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata logMetadata: Logger.Metadata?, // Renamed to avoid conflict with property
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        // 1. Combine metadata following swift-log precedence:
        //    - Handler's base metadata
        //    - Provider's metadata
        //    - Log call's metadata
        let effectiveMetadata = self.metadata
            .merging(self.metadataProvider?.get() ?? [:], uniquingKeysWith: { _, new in new })
            .merging(logMetadata ?? [:], uniquingKeysWith: { _, new in new })

        // 2. Create the specific LogRecord type
        var record = TelegramLogRecord(
            message: message,
            level: level,
            metadata: effectiveMetadata,
            source: source,
            file: file,
            function: function,
            line: line,
            timestamp: Date() // Add timestamp at the moment of logging
        )

        // 3. Emit the record to the processor
        // Since processor is an actor, we call its method asynchronously.
        // We use Task.detached or similar if needed, but onEmit itself is non-blocking
        // as it just yields to an AsyncStream. Swift-log expects `log` to be synchronous.
        // The `onEmit` is nonisolated, so it can be called synchronously.
        self.processor.onEmit(&record)
    }

    /// Accessor for individual metadata items. Modifies the handler's specific metadata.
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            self.metadata[key]
        }
        set {
            // Ensures value semantics - modification only affects this struct instance
            self.metadata[key] = newValue
        }
    }

    // SwiftLog 1.0 compatibility. Automatically synthesized if the newer `log` is implemented.
    // No need to implement this manually unless supporting very old swift-log versions
    // without the newer `log` signature available.
    /*
     @available(*, deprecated, renamed: "log(level:message:metadata:source:file:function:line:)")
     public func log(
         level: Logging.Logger.Level,
         message: Logging.Logger.Message,
         metadata: Logging.Logger.Metadata?,
         file: String,
         function: String,
         line: UInt
     ) {
         // If you needed to support older swift-log AND target newer OS, you might call the newer one here.
         // However, the protocol definition usually handles this. Best practice is to just implement the newer one.
         self.log(
             level: level,
             message: message,
             metadata: metadata,
             source: self.label, // Source wasn't passed in the old signature, use label as fallback
             file: file,
             function: function,
             line: line
         )
     }
     */
}

// MARK: - Bootstrapping Example (How to use it)

/*
 // This part would typically be in your application setup code

 import ServiceLifecycle // For ServiceGroup
 import TelegramBotAPI_AHC // For the client
 import AsyncHTTPClient // For HTTPClient

 func bootstrapTelegramLogging(httpClient: HTTPClient, botToken: String, chatId: String) async throws {
     // 1. Create the Telegram client (assuming you have one configured)
     let telegramClient = Client(httpClient: httpClient, botToken: botToken)

     // 2. Create the Exporter
     let telegramExporter = TelegramLogRecordExporter(client: telegramClient, chatId: chatId)

     // 3. Create the Processor (shared instance)
     let batchProcessor = BatchLogRecordProcessor(
         exporter: telegramExporter,
         configuration: .init() // Use default configuration or customize
         // clock: .continuous // Default clock
     )

     // 4. Configure swift-log to use the handler factory
     LoggingSystem.bootstrap { label in
         // Create a new handler instance for each Logger, but share the processor
         TelegramLoggingHandler(label: label, processor: batchProcessor)
     }

     // IMPORTANT: The BatchLogRecordProcessor needs to be run, typically as part of a ServiceGroup
     // Example:
     // let serviceGroup = ServiceGroup(
     //     services: [batchProcessor], // Add other services if needed
     //     configuration: .init(gracefulShutdownSignals: [.sigterm, .sigint]),
     //     logger: Logger(label: "ServiceRunner")
     // )
     // try await serviceGroup.run()

     // Keep the processor alive for the duration of your application.
     // How you manage its lifecycle depends on your application structure (e.g., Vapor, standalone).
     // You might store `batchProcessor` somewhere accessible and ensure its `run()` method is called
     // and awaited appropriately, often within a service management framework.
 }

 // --- Somewhere else in your code ---
 // let logger = Logger(label: "com.myapp.feature")
 // logger.info("User logged in", metadata: ["user_id": "12345"])
 // logger.warning("Failed to load resource", metadata: ["resource": "/data/config.json"])

 */