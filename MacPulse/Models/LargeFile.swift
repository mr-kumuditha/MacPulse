import Foundation

struct LargeFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let size: Int64
    let modificationDate: Date?
    let category: LargeFileCategory
    var isSelected: Bool = false

    var fileName: String {
        (path as NSString).lastPathComponent
    }

    var directory: String {
        (path as NSString).deletingLastPathComponent
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var daysSinceModified: Int? {
        guard let date = modificationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LargeFile, rhs: LargeFile) -> Bool {
        lhs.id == rhs.id
    }
}

enum LargeFileCategory: String, CaseIterable {
    case documents = "Documents"
    case media = "Media"
    case archives = "Archives"
    case diskImages = "Disk Images"
    case applications = "Applications"
    case other = "Other"

    var icon: String {
        switch self {
        case .documents: return "doc.fill"
        case .media: return "film"
        case .archives: return "archivebox.fill"
        case .diskImages: return "opticaldiscdrive"
        case .applications: return "app.fill"
        case .other: return "questionmark.folder"
        }
    }

    static func categorize(path: String) -> LargeFileCategory {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key", "txt", "rtf":
            return .documents
        case "mp4", "mov", "avi", "mkv", "mp3", "wav", "aac", "flac", "jpg", "jpeg", "png", "gif", "psd", "ai", "tiff":
            return .media
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return .archives
        case "dmg", "iso", "img", "sparseimage", "sparsebundle":
            return .diskImages
        case "app":
            return .applications
        default:
            return .other
        }
    }
}

struct StorageBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let size: Int64
    let color: String
    let icon: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var percentage: Double {
        0 // Calculated by consumer relative to total
    }
}
