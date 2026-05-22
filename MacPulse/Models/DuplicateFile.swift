import Foundation

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    var files: [DuplicateFile]
    let fileSize: Int64

    var wastedSpace: Int64 {
        fileSize * Int64(files.count - 1)
    }

    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: wastedSpace, countStyle: .file)
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let size: Int64
    let modificationDate: Date?
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool {
        lhs.id == rhs.id
    }
}

enum DuplicateScanPhase: Equatable {
    case idle
    case indexing(filesFound: Int)
    case hashing(progress: Double)
    case comparing
    case complete
    case failed(String)
}
