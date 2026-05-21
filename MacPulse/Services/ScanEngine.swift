import Foundation

actor ScanEngine {
    static let shared = ScanEngine()

    private let fileManager = FileManager.default
    private let safetyManager = SafetyManager.shared

    func scanAll(
        categories: [CleaningCategory] = CleaningCategory.allCases,
        progressHandler: @Sendable (CleaningCategory, Double) -> Void
    ) async -> [CategorySummary] {
        var summaries: [CategorySummary] = []

        for (index, category) in categories.enumerated() {
            let baseProgress = Double(index) / Double(categories.count)
            progressHandler(category, baseProgress)

            let results = await scanCategory(category)
            if !results.isEmpty {
                summaries.append(CategorySummary(category: category, results: results))
            }

            progressHandler(category, Double(index + 1) / Double(categories.count))
        }

        return summaries
    }

    func scanCategory(_ category: CleaningCategory) async -> [ScanResult] {
        var results: [ScanResult] = []

        for basePath in category.scanPaths {
            guard fileManager.fileExists(atPath: basePath) else { continue }

            let scanned = await scanDirectory(
                at: basePath,
                category: category,
                maxDepth: depthForCategory(category)
            )
            results.append(contentsOf: scanned)
        }

        return results.sorted { $0.fileSize > $1.fileSize }
    }

    private func scanDirectory(
        at path: String,
        category: CleaningCategory,
        maxDepth: Int
    ) async -> [ScanResult] {
        var results: [ScanResult] = []

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return results }

        for case let fileURL as URL in enumerator {
            if enumerator.level > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            guard let resourceValues = try? fileURL.resourceValues(
                forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]
            ) else { continue }

            let isDirectory = resourceValues.isDirectory ?? false

            // For certain categories, we want directory sizes
            if shouldReportDirectories(category) && isDirectory && enumerator.level == 1 {
                let dirSize = await FileOperationService.shared.directorySize(at: fileURL.path)
                if dirSize > 0 {
                    results.append(ScanResult(
                        category: category,
                        path: fileURL.path,
                        fileSize: dirSize,
                        fileName: fileURL.lastPathComponent,
                        modificationDate: resourceValues.contentModificationDate
                    ))
                }
                enumerator.skipDescendants()
                continue
            }

            guard !isDirectory else { continue }

            let fileSize = Int64(resourceValues.fileSize ?? 0)
            guard fileSize > 0 else { continue }
            guard matchesCategory(fileURL: fileURL, category: category) else { continue }

            results.append(ScanResult(
                category: category,
                path: fileURL.path,
                fileSize: fileSize,
                fileName: fileURL.lastPathComponent,
                modificationDate: resourceValues.contentModificationDate
            ))
        }

        return results
    }

    private func matchesCategory(fileURL: URL, category: CleaningCategory) -> Bool {
        switch category {
        case .brokenDownloads:
            let ext = fileURL.pathExtension.lowercased()
            return ext == "download" || ext == "crdownload" || ext == "part" || ext == "partial"
        case .systemLogs:
            let ext = fileURL.pathExtension.lowercased()
            return ext == "log" || ext == "diag" || ext == "crash"
        default:
            return true
        }
    }

    private func shouldReportDirectories(_ category: CleaningCategory) -> Bool {
        switch category {
        case .userCache, .xcodeDerivedData, .iosBackups: return true
        default: return false
        }
    }

    private func depthForCategory(_ category: CleaningCategory) -> Int {
        switch category {
        case .userCache: return 2
        case .xcodeDerivedData: return 1
        case .trash: return 1
        case .systemLogs: return 3
        case .iosBackups: return 1
        default: return 4
        }
    }
}
