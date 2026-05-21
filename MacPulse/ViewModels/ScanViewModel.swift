import Foundation
import Combine

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var phase: ScanPhase = .idle
    @Published var progress: Double = 0
    @Published var categorySummaries: [CategorySummary] = []
    @Published var totalSize: Int64 = 0
    @Published var totalFiles: Int = 0
    @Published var isCleaningInProgress = false
    @Published var cleaningResult: String?
    @Published var selectedCategories: Set<CleaningCategory> = Set(CleaningCategory.allCases)

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var selectedSize: Int64 {
        categorySummaries
            .filter { selectedCategories.contains($0.category) }
            .reduce(0) { $0 + $1.totalSize }
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    func startScan() async {
        phase = .preparing
        progress = 0
        categorySummaries = []
        totalSize = 0
        totalFiles = 0
        cleaningResult = nil

        let summaries = await ScanEngine.shared.scanAll(
            categories: Array(selectedCategories)
        ) { [weak self] category, prog in
            Task { @MainActor in
                self?.phase = .scanning(category: category, progress: prog)
                self?.progress = prog
            }
        }

        categorySummaries = summaries
        totalSize = summaries.reduce(0) { $0 + $1.totalSize }
        totalFiles = summaries.reduce(0) { $0 + $1.fileCount }
        phase = .complete
        progress = 1.0
    }

    func clean() async {
        isCleaningInProgress = true
        defer { isCleaningInProgress = false }

        var totalFreed: Int64 = 0
        var totalDeleted = 0

        for summary in categorySummaries where selectedCategories.contains(summary.category) {
            let paths = summary.results.filter(\.isSelected).map(\.path)
            let result = await FileOperationService.shared.deleteFiles(
                paths,
                category: summary.category.rawValue
            )
            totalFreed += result.freedBytes
            totalDeleted += result.deletedCount
        }

        AppState.shared.recordCleaning(bytes: totalFreed)

        let freedStr = ByteCountFormatter.string(fromByteCount: totalFreed, countStyle: .file)
        cleaningResult = "Cleaned \(totalDeleted) files, freed \(freedStr)"

        // Reset scan results
        categorySummaries = []
        totalSize = 0
        totalFiles = 0
        phase = .idle
    }

    func toggleCategory(_ category: CleaningCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}
