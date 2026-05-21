import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var diskUsagePercent: Double = 0
    @Published var diskFree: String = "--"
    @Published var diskTotal: String = "--"
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    @Published var lastCleanDate: String = "Never"
    @Published var totalSpaceCleaned: String = "0 MB"
    @Published var quickStats: [QuickStat] = []

    private let monitor = SystemMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    struct QuickStat: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: String
    }

    init() {
        bindMonitor()
        loadStats()
    }

    private func bindMonitor() {
        monitor.$currentMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.diskUsagePercent = metrics.diskUsagePercent
                self?.diskFree = metrics.formattedDiskFree
                self?.diskTotal = metrics.formattedDiskTotal
                self?.cpuUsage = metrics.cpuUsage
                self?.memoryUsage = metrics.memoryUsagePercent
            }
            .store(in: &cancellables)
    }

    func loadStats() {
        let state = AppState.shared
        if let date = state.lastScanDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            lastCleanDate = formatter.localizedString(for: date, relativeTo: Date())
        }
        totalSpaceCleaned = ByteCountFormatter.string(
            fromByteCount: state.totalSpaceCleaned,
            countStyle: .file
        )

        quickStats = [
            QuickStat(title: "Disk Free", value: diskFree, icon: "internaldrive", color: "blue"),
            QuickStat(title: "CPU", value: String(format: "%.0f%%", cpuUsage), icon: "cpu", color: "orange"),
            QuickStat(title: "Memory", value: String(format: "%.0f%%", memoryUsage), icon: "memorychip", color: "green"),
            QuickStat(title: "Cleaned", value: totalSpaceCleaned, icon: "sparkles", color: "purple")
        ]
    }
}
