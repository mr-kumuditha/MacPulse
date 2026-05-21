import SwiftUI
import Charts

struct SystemMonitorView: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Monitor")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Real-time system performance metrics")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Live")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)

            Divider()

            if !licenseManager.hasAccess(to: .realtimeMonitor) {
                premiumRequired
            } else {
                monitorContent
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var monitorContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Gauges row
                HStack(spacing: 20) {
                    GaugeCard(
                        title: "CPU",
                        value: monitor.currentMetrics.cpuUsage,
                        format: "%.1f%%",
                        color: cpuColor
                    )
                    GaugeCard(
                        title: "Memory",
                        value: monitor.currentMetrics.memoryUsagePercent,
                        format: "%.1f%%",
                        color: memoryColor,
                        subtitle: "\(monitor.currentMetrics.formattedMemoryUsed) / \(monitor.currentMetrics.formattedMemoryTotal)"
                    )
                    GaugeCard(
                        title: "Disk",
                        value: monitor.currentMetrics.diskUsagePercent,
                        format: "%.1f%%",
                        color: diskColor,
                        subtitle: "\(monitor.currentMetrics.formattedDiskFree) free"
                    )
                }

                // Charts
                HStack(spacing: 20) {
                    chartCard(title: "CPU History", data: monitor.history.cpuHistory, color: .blue)
                    chartCard(title: "Memory History", data: monitor.history.memoryHistory, color: .green)
                }

                // Memory pressure
                GroupBox {
                    HStack {
                        Label("Memory Pressure", systemImage: "gauge.with.dots.needle.67percent")
                            .font(.headline)
                        Spacer()
                        Text(monitor.currentMetrics.memoryPressure.rawValue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(pressureColor.opacity(0.2))
                            .foregroundStyle(pressureColor)
                            .clipShape(Capsule())
                    }
                }

                // Top processes
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Top Processes", systemImage: "list.number")
                            .font(.headline)

                        ForEach(monitor.topProcesses) { process in
                            HStack {
                                Text(process.name)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(String(format: "%.1f%%", process.cpuUsage))
                                    .frame(width: 60, alignment: .trailing)
                                    .foregroundStyle(.secondary)
                                Text(process.formattedMemory)
                                    .frame(width: 80, alignment: .trailing)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.callout)
                            if process.id != monitor.topProcesses.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func chartCard(title: String, data: [Double], color: Color) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                if #available(macOS 14.0, *) {
                    Chart(Array(data.enumerated()), id: \.offset) { index, value in
                        AreaMark(
                            x: .value("Time", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(color.gradient.opacity(0.3))

                        LineMark(
                            x: .value("Time", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(color)
                    }
                    .chartYScale(domain: 0...100)
                    .chartXAxis(.hidden)
                    .frame(height: 120)
                } else {
                    MiniChart(data: data, color: color)
                        .frame(height: 120)
                }
            }
        }
    }

    private var premiumRequired: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
            Text("Real-time monitoring is available with MacPulse Pro")
                .foregroundStyle(.secondary)
            Button("Upgrade to Pro") {
                licenseManager.showUpgradeSheet = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
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

    private var pressureColor: Color {
        switch monitor.currentMetrics.memoryPressure {
        case .nominal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct GaugeCard: View {
    let title: String
    let value: Double
    let format: String
    let color: Color
    var subtitle: String?

    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(value / 100, 1))
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: value)

                    VStack(spacing: 2) {
                        Text(String(format: format, value))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct MiniChart: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            if data.count >= 2 {
                Path { path in
                    let step = width / CGFloat(max(data.count - 1, 1))
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * step
                        let y = height - (CGFloat(value / 100) * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
}
