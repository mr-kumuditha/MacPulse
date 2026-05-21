import Foundation
import os.log

final class Logger {
    static let shared = Logger()

    enum Category: String {
        case app = "App"
        case scan = "Scan"
        case clean = "Clean"
        case monitor = "Monitor"
        case security = "Security"
        case license = "License"
        case automation = "Automation"
    }

    private let subsystem = "com.macpulse.app"
    private var loggers: [Category: os.Logger] = [:]

    private init() {
        for category in [Category.app, .scan, .clean, .monitor, .security, .license, .automation] {
            loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    func info(_ message: String, category: Category) {
        loggers[category]?.info("\(message, privacy: .public)")
    }

    func warning(_ message: String, category: Category) {
        loggers[category]?.warning("\(message, privacy: .public)")
    }

    func error(_ message: String, category: Category) {
        loggers[category]?.error("\(message, privacy: .public)")
    }

    func debug(_ message: String, category: Category) {
        loggers[category]?.debug("\(message, privacy: .public)")
    }
}
