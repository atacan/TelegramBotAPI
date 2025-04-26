import Logging
import SwiftLogExport

public struct LoggingHandler: LogHandler {
    public func log(level: SwiftLog.Logger.Level, message: SwiftLog.Logger.Message, metadata: SwiftLog.Logger.Metadata, source: SwiftLog.Logger.Source, file: String, function: String, line: UInt) {
        print(message)
    }
}