import Foundation
import SwiftUI

enum CleaningCategory: String, CaseIterable, Identifiable, Codable {
    case userCache = "user_cache"
    case browserCache = "browser_cache"
    case xcodeDerivedData = "xcode_derived"
    case temporaryFiles = "temp_files"
    case trash = "trash"
    case systemLogs = "system_logs"
    case brokenDownloads = "broken_downloads"
    case mailCache = "mail_cache"
    case appLeftovers = "app_leftovers"
    case iosBackups = "ios_backups"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .userCache: return "User Cache"
        case .browserCache: return "Browser Cache"
        case .xcodeDerivedData: return "Xcode Data"
        case .temporaryFiles: return "Temporary Files"
        case .trash: return "Trash"
        case .systemLogs: return "System Logs"
        case .brokenDownloads: return "Broken Downloads"
        case .mailCache: return "Mail Cache"
        case .appLeftovers: return "App Leftovers"
        case .iosBackups: return "iOS Backups"
        }
    }

    var icon: String {
        switch self {
        case .userCache: return "folder.badge.gearshape"
        case .browserCache: return "globe"
        case .xcodeDerivedData: return "hammer"
        case .temporaryFiles: return "clock.arrow.circlepath"
        case .trash: return "trash"
        case .systemLogs: return "doc.text"
        case .brokenDownloads: return "arrow.down.circle.dotted"
        case .mailCache: return "envelope"
        case .appLeftovers: return "puzzlepiece"
        case .iosBackups: return "iphone"
        }
    }

    var color: Color {
        switch self {
        case .userCache: return .blue
        case .browserCache: return .orange
        case .xcodeDerivedData: return .purple
        case .temporaryFiles: return .gray
        case .trash: return .red
        case .systemLogs: return .green
        case .brokenDownloads: return .yellow
        case .mailCache: return .cyan
        case .appLeftovers: return .pink
        case .iosBackups: return .indigo
        }
    }

    var scanPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .userCache:
            return ["\(home)/Library/Caches"]
        case .browserCache:
            return [
                "\(home)/Library/Caches/com.apple.Safari",
                "\(home)/Library/Caches/Google/Chrome",
                "\(home)/Library/Caches/Firefox/Profiles",
                "\(home)/Library/Caches/BraveSoftware"
            ]
        case .xcodeDerivedData:
            return [
                "\(home)/Library/Developer/Xcode/DerivedData",
                "\(home)/Library/Developer/Xcode/Archives"
            ]
        case .temporaryFiles:
            return [
                NSTemporaryDirectory(),
                "/tmp",
                "/private/var/folders"
            ]
        case .trash:
            return ["\(home)/.Trash"]
        case .systemLogs:
            return [
                "\(home)/Library/Logs",
                "/Library/Logs"
            ]
        case .brokenDownloads:
            return ["\(home)/Downloads"]
        case .mailCache:
            return [
                "\(home)/Library/Containers/com.apple.mail/Data/Library/Caches"
            ]
        case .appLeftovers:
            return [
                "\(home)/Library/Application Support",
                "\(home)/Library/Preferences",
                "\(home)/Library/Saved Application State"
            ]
        case .iosBackups:
            return [
                "\(home)/Library/Application Support/MobileSync/Backup"
            ]
        }
    }

    var requiresPremium: Bool {
        switch self {
        case .appLeftovers, .iosBackups, .mailCache: return true
        default: return false
        }
    }

    var description: String {
        switch self {
        case .userCache: return "Application cache files that can be safely regenerated"
        case .browserCache: return "Web browser cached data, images, and scripts"
        case .xcodeDerivedData: return "Xcode build artifacts and derived data"
        case .temporaryFiles: return "System and application temporary files"
        case .trash: return "Files in the Trash waiting to be removed"
        case .systemLogs: return "System and application diagnostic logs"
        case .brokenDownloads: return "Incomplete or corrupted download files"
        case .mailCache: return "Apple Mail cached messages and attachments"
        case .appLeftovers: return "Residual files from uninstalled applications"
        case .iosBackups: return "Old iOS device backup files"
        }
    }
}
