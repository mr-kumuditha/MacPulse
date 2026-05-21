import Foundation
import Combine

@MainActor
final class StorageViewModel: ObservableObject {
    @Published var largeFiles: [LargeFile] = []
    @Published var breakdown: [StorageBreakdown] = []
    @Published var isScanning = false
    @Published var filesFound = 0
    @Published var minimumSizeMB: Double = 50
    @Published var sortOrder: SortOrder = .size

    enum SortOrder: String, CaseIterable {
        case size = "Size"
        case date = "Date"
        case name = "Name"
    }

    var totalWaste: Int64 {
        largeFiles.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var formattedTotalWaste: String {
        ByteCountFormatter.string(fromByteCount: totalWaste, countStyle: .file)
    }

    var sortedFiles: [LargeFile] {
        switch sortOrder {
        case .size: return largeFiles.sorted { $0.size > $1.size }
        case .date: return largeFiles.sorted { ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast) }
        case .name: return largeFiles.sorted { $0.fileName.lowercased() < $1.fileName.lowercased() }
        }
    }

    func scan() async {
        isScanning = true
        filesFound = 0
        largeFiles = []

        async let files = LargeFileAnalyzer.shared.findLargeFiles(
            minimumSize: Int64(minimumSizeMB * 1024 * 1024)
        ) { [weak self] count in
            Task { @MainActor in
                self?.filesFound = count
            }
        }

        async let storageBreakdown = LargeFileAnalyzer.shared.getStorageBreakdown()

        largeFiles = await files
        breakdown = await storageBreakdown
        isScanning = false
    }

    func deleteSelected() async {
        let paths = largeFiles.filter(\.isSelected).map(\.path)
        let result = await FileOperationService.shared.moveToTrash(paths)
        AppState.shared.recordCleaning(bytes: result.freedBytes)
        largeFiles.removeAll { $0.isSelected }
    }

    func toggleFile(at index: Int) {
        guard index < largeFiles.count else { return }
        largeFiles[index].isSelected.toggle()
    }

    func revealInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}

import AppKit
