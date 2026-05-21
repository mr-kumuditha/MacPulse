import Foundation

actor LargeFileAnalyzer {
    static let shared = LargeFileAnalyzer()

    private let fileManager = FileManager.default
    private let minimumSize: Int64 = 50 * 1024 * 1024 // 50 MB

    func findLargeFiles(
        in directory: String? = nil,
        minimumSize: Int64? = nil,
        progressHandler: @Sendable (Int) -> Void
    ) async -> [LargeFile] {
        let searchDir = directory ?? FileManager.default.homeDirectoryForCurrentUser.path
        let threshold = minimumSize ?? self.minimumSize
        var results: [LargeFile] = []
        var scannedCount = 0

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: searchDir),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return results }

        for case let fileURL as URL in enumerator {
            // Skip system directories
            let path = fileURL.path
            if path.contains("/Library/Application Support/MobileSync") ||
               path.contains("/.Trash/") ||
               path.contains("/node_modules/") ||
               path.contains("/.git/") {
                enumerator.skipDescendants()
                continue
            }

            guard let values = try? fileURL.resourceValues(
                forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]
            ) else { continue }

            guard let isDir = values.isDirectory, !isDir else { continue }

            let size = Int64(values.fileSize ?? 0)
            guard size >= threshold else { continue }

            results.append(LargeFile(
                path: path,
                size: size,
                modificationDate: values.contentModificationDate,
                category: LargeFileCategory.categorize(path: path)
            ))

            scannedCount += 1
            if scannedCount % 10 == 0 {
                progressHandler(scannedCount)
            }
        }

        return results.sorted { $0.size > $1.size }
    }

    func getStorageBreakdown() async -> [StorageBreakdown] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let directories: [(String, String, String)] = [
            ("\(home)/Documents", "Documents", "doc.fill"),
            ("\(home)/Downloads", "Downloads", "arrow.down.circle"),
            ("\(home)/Desktop", "Desktop", "menubar.dock.rectangle"),
            ("\(home)/Movies", "Movies", "film"),
            ("\(home)/Music", "Music", "music.note"),
            ("\(home)/Pictures", "Photos", "photo"),
            ("\(home)/Library", "System Data", "gearshape"),
            ("/Applications", "Applications", "app.fill")
        ]

        var breakdown: [StorageBreakdown] = []

        for (path, name, icon) in directories {
            let size = await FileOperationService.shared.directorySize(at: path)
            if size > 0 {
                breakdown.append(StorageBreakdown(
                    category: name,
                    size: size,
                    color: "blue",
                    icon: icon
                ))
            }
        }

        return breakdown.sorted { $0.size > $1.size }
    }
}
