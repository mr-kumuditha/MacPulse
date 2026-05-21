import Foundation
import Combine

@MainActor
final class StartupManagerViewModel: ObservableObject {
    @Published var items: [StartupItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterType: StartupItemType?

    var filteredItems: [StartupItem] {
        guard let filter = filterType else { return items }
        return items.filter { $0.type == filter }
    }

    var enabledCount: Int {
        items.filter(\.isEnabled).count
    }

    func loadItems() async {
        isLoading = true
        items = await StartupManagerService.shared.getStartupItems()
        isLoading = false
    }

    func toggleItem(_ item: StartupItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        do {
            try await StartupManagerService.shared.toggleItem(item, enabled: !item.isEnabled)
            items[index].isEnabled.toggle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
