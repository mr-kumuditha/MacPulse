import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundStyle(.blue)
                Text("MacPulse")
                    .fontWeight(.semibold)
                Spacer()
                Text("v\(AppInfo.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Quick metrics
            VStack(spacing: 8) {
                MetricRow(
                    icon: "cpu",
                    label: "CPU",
                    value: String(format: "%.0f%%", monitor.currentMetrics.cpuUsage),
                    progress: monitor.currentMetrics.cpuUsage / 100
                )
                MetricRow(
                    icon: "memorychip",
                    label: "Memory",
                    value: String(format: "%.0f%%", monitor.currentMetrics.memoryUsagePercent),
                    progress: monitor.currentMetrics.memoryUsagePercent / 100
                )
                MetricRow(
                    icon: "internaldrive",
                    label: "Disk",
                    value: monitor.currentMetrics.formattedDiskFree + " free",
                    progress: monitor.currentMetrics.diskUsagePercent / 100
                )
            }

            Divider()

            Button {
                appState.selectedNavigation = .smartClean
                NSApplication.shared.activate(ignoringOtherApps: true)
                openMainWindow()
            } label: {
                Label("Smart Scan", systemImage: "sparkles")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                appState.selectedNavigation = .monitor
                NSApplication.shared.activate(ignoringOtherApps: true)
                openMainWindow()
            } label: {
                Label("System Monitor", systemImage: "waveform.path.ecg")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openMainWindow()
            } label: {
                Label("Open MacPulse", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 260)
    }

    private func openMainWindow() {
        for window in NSApplication.shared.windows {
            if window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
