import Foundation
import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let bundleIdentifier: String?
    let version: String?
    let size: Int64
    let icon: NSImage?
    let lastUsedDate: Date?

    var relatedPaths: [String] {
        guard let bundleID = bundleIdentifier else { return [] }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/Library/Application Support/\(bundleID)",
            "\(home)/Library/Application Support/\(name)",
            "\(home)/Library/Preferences/\(bundleID).plist",
            "\(home)/Library/Caches/\(bundleID)",
            "\(home)/Library/Caches/\(name)",
            "\(home)/Library/Logs/\(bundleID)",
            "\(home)/Library/Logs/\(name)",
            "\(home)/Library/Saved Application State/\(bundleID).savedState",
            "\(home)/Library/Containers/\(bundleID)",
            "\(home)/Library/Group Containers/\(bundleID)",
            "\(home)/Library/HTTPStorages/\(bundleID)",
            "\(home)/Library/WebKit/\(bundleID)"
        ]
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }
}

struct AppLeftover: Identifiable {
    let id = UUID()
    let path: String
    let size: Int64
    let type: LeftoverType

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum LeftoverType: String {
    case preferences = "Preferences"
    case cache = "Cache"
    case applicationSupport = "App Data"
    case savedState = "Saved State"
    case container = "Container"
    case logs = "Logs"
    case other = "Other"
}
