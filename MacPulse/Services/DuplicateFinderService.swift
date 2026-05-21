import Foundation
import CommonCrypto

actor DuplicateFinderService {
    static let shared = DuplicateFinderService()

    private let fileManager = FileManager.default
    private let minFileSize: Int64 = 1024 // Skip files < 1KB

    func findDuplicates(
        in directories: [String],
        progressHandler: @Sendable (DuplicateScanPhase) -> Void
    ) async -> [DuplicateGroup] {
        progressHandler(.indexing(filesFound: 0))

        // Phase 1: Index files by size
        var sizeMap: [Int64: [String]] = [:]
        var totalFiles = 0

        for directory in directories {
            guard let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      let isDir = values.isDirectory, !isDir,
                      let size = values.fileSize else { continue }

                let fileSize = Int64(size)
                guard fileSize >= minFileSize else { continue }

                sizeMap[fileSize, default: []].append(fileURL.path)
                totalFiles += 1

                if totalFiles % 500 == 0 {
                    progressHandler(.indexing(filesFound: totalFiles))
                }
            }
        }

        // Phase 2: Hash files that share the same size
        let candidates = sizeMap.filter { $0.value.count > 1 }
        var hashMap: [String: [(path: String, size: Int64, date: Date?)]] = [:]
        var processed = 0
        let totalCandidates = candidates.values.reduce(0) { $0 + $1.count }

        progressHandler(.hashing(progress: 0))

        for (size, paths) in candidates {
            for path in paths {
                guard let hash = hashFile(at: path) else { continue }

                let date = (try? fileManager.attributesOfItem(atPath: path))?[.modificationDate] as? Date
                hashMap[hash, default: []].append((path: path, size: size, date: date))

                processed += 1
                let progress = Double(processed) / Double(totalCandidates)
                if processed % 50 == 0 {
                    progressHandler(.hashing(progress: progress))
                }
            }
        }

        // Phase 3: Build duplicate groups
        progressHandler(.comparing)

        let groups = hashMap
            .filter { $0.value.count > 1 }
            .map { hash, entries in
                DuplicateGroup(
                    hash: hash,
                    files: entries.map { entry in
                        DuplicateFile(
                            path: entry.path,
                            size: entry.size,
                            modificationDate: entry.date
                        )
                    },
                    fileSize: entries.first?.size ?? 0
                )
            }
            .sorted { $0.wastedSpace > $1.wastedSpace }

        progressHandler(.complete)
        return groups
    }

    private func hashFile(at path: String, chunkSize: Int = 65536) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { handle.closeFile() }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        // Hash first chunk
        let firstChunk = handle.readData(ofLength: chunkSize)
        guard !firstChunk.isEmpty else { return nil }

        firstChunk.withUnsafeBytes { buffer in
            _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
        }

        // For larger files, also hash a middle and end chunk
        let fileSize = handle.seekToEndOfFile()
        if fileSize > UInt64(chunkSize * 3) {
            handle.seek(toFileOffset: fileSize / 2)
            let middleChunk = handle.readData(ofLength: chunkSize)
            middleChunk.withUnsafeBytes { buffer in
                _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
            }

            handle.seek(toFileOffset: fileSize - UInt64(chunkSize))
            let endChunk = handle.readData(ofLength: chunkSize)
            endChunk.withUnsafeBytes { buffer in
                _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
            }
        }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
