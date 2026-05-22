import Foundation
import AppKit

final class SafetyManager {
    static let shared = SafetyManager()

    private let protectedPaths: Set<String> = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "/System",
            "/usr",
            "/bin",
            "/sbin",
            "/Library/Apple",
            "/private/var/db",
            "\(home)/Library/Keychains",
            "\(home)/Library/Accounts",
            "\(home)/Library/Mail",
            "\(home)/Documents",
            "\(home)/Desktop",
            "\(home)/Pictures",
            "\(home)/Music",
            "\(home)/Movies",
            "\(home)/.ssh",
            "\(home)/.gnupg",
            "\(home)/.config",
            "\(home)/.gitconfig"
        ]
    }()

    private let protectedExtensions: Set<String> = [
        "keychain", "keychain-db", "pem", "key", "cert", "p12"
    ]

    private let protectedBundleIDs: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.SystemUIServer",
        "com.apple.loginwindow",
        "com.apple.WindowServer",
        "com.apple.kernel"
    ]

    private let maxDeletionBatchSize = 1000
    private var deletionLog: [DeletionRecord] = []

    struct DeletionRecord: Codable {
        let path: String
        let size: Int64
        let timestamp: Date
        let category: String
    }

    private init() {}

    func isSafeToDelete(path: String) -> Bool {
        let normalizedPath = (path as NSString).standardizingPath

        // Check protected paths
        for protected in protectedPaths {
            if normalizedPath == protected || normalizedPath.hasPrefix(protected + "/") {
                // Allow cleaning caches within some protected paths
                if normalizedPath.contains("/Caches/") && !normalizedPath.contains("/Keychains") {
                    continue
                }
                Logger.shared.warning("Blocked deletion of protected path: \(path)", category: .security)
                return false
            }
        }

        // Check protected extensions
        let ext = (normalizedPath as NSString).pathExtension.lowercased()
        if protectedExtensions.contains(ext) {
            Logger.shared.warning("Blocked deletion of protected file type: \(ext)", category: .security)
            return false
        }

        // Don't delete running app bundles
        if normalizedPath.hasSuffix(".app") {
            let runningApps = NSWorkspace.shared.runningApplications
            for app in runningApps {
                if let bundlePath = app.bundleURL?.path, bundlePath == normalizedPath {
                    Logger.shared.warning("Blocked deletion of running app: \(path)", category: .security)
                    return false
                }
            }
        }

        // Check file exists and is accessible
        let fm = FileManager.default
        guard fm.fileExists(atPath: normalizedPath) else { return false }
        guard fm.isDeletableFile(atPath: normalizedPath) else { return false }

        return true
    }

    func isSafeToDisable(bundleID: String) -> Bool {
        !protectedBundleIDs.contains(bundleID)
    }

    func validateBatchDeletion(paths: [String]) -> (safe: [String], blocked: [String]) {
        var safe: [String] = []
        var blocked: [String] = []

        for path in paths.prefix(maxDeletionBatchSize) {
            if isSafeToDelete(path: path) {
                safe.append(path)
            } else {
                blocked.append(path)
            }
        }

        return (safe, blocked)
    }

    func recordDeletion(path: String, size: Int64, category: String) {
        let record = DeletionRecord(path: path, size: size, timestamp: Date(), category: category)
        deletionLog.append(record)
        saveDeletionLog()
    }

    func getDeletionHistory() -> [DeletionRecord] {
        loadDeletionLog()
        return deletionLog
    }

    private func saveDeletionLog() {
        guard let data = try? JSONEncoder().encode(deletionLog) else { return }
        let logPath = getLogPath()
        try? data.write(to: URL(fileURLWithPath: logPath))
    }

    private func loadDeletionLog() {
        let logPath = getLogPath()
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: logPath)),
              let records = try? JSONDecoder().decode([DeletionRecord].self, from: data) else { return }
        deletionLog = records
    }

    private func getLogPath() -> String {
        let support = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MacPulse")
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("deletion_log.json").path
    }
}
