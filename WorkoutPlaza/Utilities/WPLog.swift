
import Foundation
import OSLog

enum WPLogLevel: String {
    case debug
    case info
    case network
    case warning
    case error
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .network: return .default // 'network' is not a standard OSLogType, map to default or info
        case .warning: return .error   // OSLogType.error is often used for warnings/errors. .fault is for critical.
        case .error: return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .network: return "🌐"
        case .warning: return "⚠️"
        case .error: return "🚨"
        }
    }
}

final class WPLog {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WorkoutPlaza", category: "WPLog")
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Public API
    
    static func debug(_ items: Any..., file: String = #file, line: Int = #line) {
        log(level: .debug, items: items, file: file, line: line)
    }
    
    static func info(_ items: Any..., file: String = #file, line: Int = #line) {
        log(level: .info, items: items, file: file, line: line)
    }
    
    static func network(_ items: Any..., file: String = #file, line: Int = #line) {
        log(level: .network, items: items, file: file, line: line)
    }
    
    static func warning(_ items: Any..., file: String = #file, line: Int = #line) {
        log(level: .warning, items: items, file: file, line: line)
    }
    
    static func error(_ items: Any..., file: String = #file, line: Int = #line) {
        log(level: .error, items: items, file: file, line: line)
    }
    
    // MARK: - Internal Logging Logic
    
    private static func log(level: WPLogLevel, items: [Any], file: String, line: Int) {
        let timestamp = dateFormatter.string(from: Date())
        
        // Items to string
        let message = items.map { "\($0)" }.joined(separator: " ")
        
        // File name extracting
        let fileName = (file as NSString).lastPathComponent
        
        // Final Format: [Date Time] [Message...] ... [FileName:Line]
        // Note: OSLog already captures timestamp, but user explicitly requested prefix.
        // Also OSLog captures process/thread info.
        
        let logMessage = "[\(timestamp)] \(level.emoji) \(message) ... [\(fileName):\(line)]"
        
        // Log to OSLog
        switch level {
        case .debug:
            logger.debug("\(logMessage, privacy: .public)")
        case .info:
            logger.info("\(logMessage, privacy: .public)")
        case .network:
            logger.log("\(logMessage, privacy: .public)") // Mapped to default
        case .warning:
            logger.error("\(logMessage, privacy: .public)") // Mapped to error
        case .error:
            logger.fault("\(logMessage, privacy: .public)") // Mapped to fault
        }
    }
}
