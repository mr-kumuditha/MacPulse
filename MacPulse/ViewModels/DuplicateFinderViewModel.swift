import Foundation
import Combine

@MainActor
final class DuplicateFinderViewModel: ObservableObject {
    @Published var phase: DuplicateScanPhase = .idle
    @Published var groups: [DuplicateGroup] = []
    @Published var totalWastedSpace: Int64 = 0
    @Published var searchDirectories: [String] = [
        FileManager.default.homeDirectoryForCurrentUser.path
    ]
    @Published var isDeleting = false
    @Published var resultMessage: String?

    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file)
    }

    func startScan() async {
        phase = .indexing(filesFound: 0)
        groups = []
        totalWastedSpace = 0
        resultMessage = nil

        let found = await DuplicateFinderService.shared.findDuplicates(
            in: searchDirectories
        ) { newPhase in
            Task { @MainActor [weak self] in
                self?.phase = newPhase
            }
        }

        groups = found
        totalWastedSpace = found.reduce(0) { $0 + $1.wastedSpace }
        phase = .complete
    }

    func autoSelectDuplicates() {
        for groupIndex in groups.indices {
            for fileIndex in groups[groupIndex].files.indices {
                // Keep the oldest (original) file, select the rest
                groups[groupIndex].files[fileIndex].isSelected = fileIndex > 0
            }
        }
    }

    func deleteSelected() async {
        isDeleting = true
        defer { isDeleting = false }

        let selectedPaths = groups.flatMap { group in
            group.files.filter(\.isSelected).map(\.path)
        }

        let result = await FileOperationService.shared.deleteFiles(selectedPaths, category: "duplicates")
        AppState.shared.recordCleaning(bytes: result.freedBytes)

        let freedStr = ByteCountFormatter.string(fromByteCount: result.freedBytes, countStyle: .file)
        resultMessage = "Removed \(result.deletedCount) duplicates, freed \(freedStr)"

        // Remove deleted files from groups
        groups = groups.compactMap { group in
            let remaining = group.files.filter { !$0.isSelected }
            guard remaining.count > 1 else { return nil }
            return DuplicateGroup(hash: group.hash, files: remaining, fileSize: group.fileSize)
        }
        totalWastedSpace = groups.reduce(0) { $0 + $1.wastedSpace }
    }
}
