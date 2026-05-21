import Foundation
import Combine
import AppKit

@MainActor
final class UninstallerViewModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var selectedApp: InstalledApp?
    @Published var leftovers: [AppLeftover] = []
    @Published var isLoading = false
    @Published var isUninstalling = false
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .size
    @Published var resultMessage: String?

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case date = "Last Used"
    }

    var filteredApps: [InstalledApp] {
        let sorted: [InstalledApp]
        switch sortOrder {
        case .name: sorted = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .size: sorted = apps.sorted { $0.size > $1.size }
        case .date: sorted = apps.sorted { ($0.lastUsedDate ?? .distantPast) > ($1.lastUsedDate ?? .distantPast) }
        }

        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func loadApps() async {
        isLoading = true
        apps = await AppUninstallerService.shared.getInstalledApps()
        isLoading = false
    }

    func selectApp(_ app: InstalledApp) async {
        selectedApp = app
        leftovers = await AppUninstallerService.shared.findLeftovers(for: app)
    }

    func uninstallSelected(includeLeftovers: Bool) async {
        guard let app = selectedApp else { return }
        isUninstalling = true
        defer { isUninstalling = false }

        do {
            let freed = try await AppUninstallerService.shared.uninstallApp(
                app,
                includeLeftovers: includeLeftovers
            )
            let freedStr = ByteCountFormatter.string(fromByteCount: freed, countStyle: .file)
            resultMessage = "Uninstalled \(app.name), freed \(freedStr)"
            apps.removeAll { $0.id == app.id }
            selectedApp = nil
            leftovers = []
        } catch {
            resultMessage = "Failed: \(error.localizedDescription)"
        }
    }

    func revealInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
