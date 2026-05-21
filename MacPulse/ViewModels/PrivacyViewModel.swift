import Foundation
import Combine

@MainActor
final class PrivacyViewModel: ObservableObject {
    @Published var items: [PrivacyItem] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var resultMessage: String?
    @Published var selectedBrowser: Browser?

    var filteredItems: [PrivacyItem] {
        guard let browser = selectedBrowser else { return items }
        return items.filter { $0.browser == browser }
    }

    var totalSize: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var groupedByBrowser: [Browser: [PrivacyItem]] {
        Dictionary(grouping: items, by: \.browser)
    }

    func scan() async {
        isScanning = true
        resultMessage = nil
        items = await PrivacyCleanerService.shared.scanPrivacyItems()
        isScanning = false
    }

    func clean() async {
        isCleaning = true
        defer { isCleaning = false }

        let selected = items.filter(\.isSelected)
        let result = await PrivacyCleanerService.shared.cleanItems(selected)
        AppState.shared.recordCleaning(bytes: result.freedBytes)

        let freedStr = ByteCountFormatter.string(fromByteCount: result.freedBytes, countStyle: .file)
        resultMessage = "Cleaned \(result.deletedCount) items, freed \(freedStr)"

        items.removeAll { $0.isSelected }
    }

    func toggleAll(_ selected: Bool) {
        for i in items.indices {
            items[i].isSelected = selected
        }
    }
}
