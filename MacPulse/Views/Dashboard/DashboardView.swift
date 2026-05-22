import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsGrid
                systemHealthSection
                quickActionsSection
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to MacPulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                HStack(spacing: 4) {
                    Text("v\(AppInfo.version)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .clipShape(Capsule())
                    Text("by \(AppInfo.developer)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                appState.selectedNavigation = .smartClean
            } label: {
                Label("Smart Scan", systemImage: "sparkles")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Disk Free",
                value: monitor.currentMetrics.formattedDiskFree,
                icon: "internaldrive",
                color: .blue,
                progress: 1.0 - monitor.currentMetrics.diskUsagePercent / 100
            )
            StatCard(
                title: "CPU Usage",
                value: String(format: "%.0f%%", monitor.currentMetrics.cpuUsage),
                icon: "cpu",
                color: cpuColor,
                progress: monitor.currentMetrics.cpuUsage / 100
            )
            StatCard(
                title: "Memory",
                value: String(format: "%.0f%%", monitor.currentMetrics.memoryUsagePercent),
                icon: "memorychip",
                color: memoryColor,
                progress: monitor.currentMetrics.memoryUsagePercent / 100
            )
            StatCard(
                title: "Space Cleaned",
                value: viewModel.totalSpaceCleaned,
                icon: "sparkles",
                color: .purple,
                progress: nil
            )
        }
    }

    private var systemHealthSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Disk Usage", systemImage: "chart.bar.fill")
                    .font(.headline)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(diskColor.gradient)
                            .frame(width: geo.size.width * monitor.currentMetrics.diskUsagePercent / 100)
                    }
                }
                .frame(height: 24)

                HStack {
                    Text("\(monitor.currentMetrics.formattedDiskUsed) used")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(monitor.currentMetrics.formattedDiskFree) available")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(monitor.currentMetrics.formattedDiskTotal) total")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            .padding(4)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Clean Junk",
                    icon: "sparkles",
                    color: .blue
                ) { appState.selectedNavigation = .smartClean }

                QuickActionButton(
                    title: "Find Duplicates",
                    icon: "doc.on.doc",
                    color: .orange
                ) { appState.selectedNavigation = .duplicates }

                QuickActionButton(
                    title: "Large Files",
                    icon: "internaldrive",
                    color: .green
                ) { appState.selectedNavigation = .storage }

                QuickActionButton(
                    title: "Privacy",
                    icon: "hand.raised.fill",
                    color: .red
                ) { appState.selectedNavigation = .privacy }

                QuickActionButton(
                    title: "Startup Items",
                    icon: "power",
                    color: .purple
                ) { appState.selectedNavigation = .startup }

                QuickActionButton(
                    title: "Uninstall Apps",
                    icon: "trash",
                    color: .pink
                ) { appState.selectedNavigation = .uninstaller }
            }
        }
    }

    private var cpuColor: Color {
        monitor.currentMetrics.cpuUsage > 80 ? .red :
        monitor.currentMetrics.cpuUsage > 50 ? .orange : .green
    }

    private var memoryColor: Color {
        monitor.currentMetrics.memoryUsagePercent > 85 ? .red :
        monitor.currentMetrics.memoryUsagePercent > 65 ? .orange : .green
    }

    private var diskColor: Color {
        monitor.currentMetrics.diskUsagePercent > 90 ? .red :
        monitor.currentMetrics.diskUsagePercent > 75 ? .orange : .blue
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let progress: Double?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let progress {
                ProgressView(value: min(max(progress, 0), 1))
                    .tint(color)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
