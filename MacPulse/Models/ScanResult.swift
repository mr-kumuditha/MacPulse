import Foundation

struct ScanResult: Identifiable, Hashable {
    let id = UUID()
    let category: CleaningCategory
    let path: String
    let fileSize: Int64
    let fileName: String
    let modificationDate: Date?
    var isSelected: Bool = true

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
        lhs.id == rhs.id
    }
}

struct ScanSummary {
    let categories: [CategorySummary]
    let totalSize: Int64
    let totalFiles: Int
    let scanDuration: TimeInterval

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedDuration: String {
        String(format: "%.1fs", scanDuration)
    }
}

struct CategorySummary: Identifiable {
    let id = UUID()
    let category: CleaningCategory
    let results: [ScanResult]
    var isExpanded: Bool = false

    var totalSize: Int64 {
        results.reduce(0) { $0 + $1.fileSize }
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var fileCount: Int {
        results.count
    }
}

enum ScanPhase: Equatable {
    case idle
    case preparing
    case scanning(category: CleaningCategory, progress: Double)
    case analyzing
    case complete
    case failed(String)

    var description: String {
        switch self {
        case .idle: return "Ready to scan"
        case .preparing: return "Preparing..."
        case .scanning(let category, _): return "Scanning \(category.displayName)..."
        case .analyzing: return "Analyzing results..."
        case .complete: return "Scan complete"
        case .failed(let error): return "Failed: \(error)"
        }
    }
}
