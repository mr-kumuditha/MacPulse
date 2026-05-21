import Foundation

actor FileOperationService {
    static let shared = FileOperationService()

    private let fileManager = FileManager.default
    private let safetyManager = SafetyManager.shared

    enum FileError: LocalizedError {
        case notSafeToDelete(String)
        case deletionFailed(String, Error)
        case accessDenied(String)
        case notFound(String)

        var errorDescription: String? {
            switch self {
            case .notSafeToDelete(let path): return "Not safe to delete: \(path)"
            case .deletionFailed(let path, let error): return "Failed to delete \(path): \(error.localizedDescription)"
            case .accessDenied(let path): return "Access denied: \(path)"
            case .notFound(let path): return "File not found: \(path)"
            }
        }
    }

    struct DeletionResult {
        var deletedCount: Int = 0
        var freedBytes: Int64 = 0
        var errors: [FileError] = []
    }

    func deleteFiles(_ paths: [String], category: String) async -> DeletionResult {
        var result = DeletionResult()
        let validation = safetyManager.validateBatchDeletion(paths: paths)

        for path in validation.blocked {
            result.errors.append(.notSafeToDelete(path))
        }

        for path in validation.safe {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: path)
                let size = (attrs[.size] as? Int64) ?? 0

                try fileManager.removeItem(atPath: path)

                result.deletedCount += 1
                result.freedBytes += size
                safetyManager.recordDeletion(path: path, size: size, category: category)
                Logger.shared.info("Deleted: \(path) (\(size) bytes)", category: .clean)
            } catch {
                result.errors.append(.deletionFailed(path, error))
                Logger.shared.error("Failed to delete: \(path) - \(error)", category: .clean)
            }
        }

        return result
    }

    func moveToTrash(_ paths: [String]) async -> DeletionResult {
        var result = DeletionResult()

        for path in paths {
            guard safetyManager.isSafeToDelete(path: path) else {
                result.errors.append(.notSafeToDelete(path))
                continue
            }

            do {
                let url = URL(fileURLWithPath: path)
                var trashedURL: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)

                let attrs = try? fileManager.attributesOfItem(atPath: path)
                let size = (attrs?[.size] as? Int64) ?? 0
                result.deletedCount += 1
                result.freedBytes += size
            } catch {
                result.errors.append(.deletionFailed(path, error))
            }
        }

        return result
    }

    func fileSize(at path: String) -> Int64 {
        guard let attrs = try? fileManager.attributesOfItem(atPath: path) else { return 0 }
        return (attrs[.size] as? Int64) ?? 0
    }

    func directorySize(at path: String) async -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return 0 }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory,
                  !isDirectory,
                  let fileSize = resourceValues.fileSize else { continue }
            totalSize += Int64(fileSize)
        }

        return totalSize
    }
}
