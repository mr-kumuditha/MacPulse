import Foundation

struct SystemMetrics {
    let cpuUsage: Double          // 0.0 - 100.0
    let memoryUsed: Int64         // bytes
    let memoryTotal: Int64        // bytes
    let memoryPressure: MemoryPressure
    let diskUsed: Int64           // bytes
    let diskTotal: Int64          // bytes
    let networkBytesIn: Int64
    let networkBytesOut: Int64
    let timestamp: Date

    var memoryUsagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }

    var diskUsagePercent: Double {
        guard diskTotal > 0 else { return 0 }
        return Double(diskUsed) / Double(diskTotal) * 100
    }

    var diskFree: Int64 {
        diskTotal - diskUsed
    }

    var formattedMemoryUsed: String {
        ByteCountFormatter.string(fromByteCount: memoryUsed, countStyle: .memory)
    }

    var formattedMemoryTotal: String {
        ByteCountFormatter.string(fromByteCount: memoryTotal, countStyle: .memory)
    }

    var formattedDiskUsed: String {
        ByteCountFormatter.string(fromByteCount: diskUsed, countStyle: .file)
    }

    var formattedDiskFree: String {
        ByteCountFormatter.string(fromByteCount: diskFree, countStyle: .file)
    }

    var formattedDiskTotal: String {
        ByteCountFormatter.string(fromByteCount: diskTotal, countStyle: .file)
    }

    static var empty: SystemMetrics {
        SystemMetrics(
            cpuUsage: 0,
            memoryUsed: 0,
            memoryTotal: 0,
            memoryPressure: .nominal,
            diskUsed: 0,
            diskTotal: 0,
            networkBytesIn: 0,
            networkBytesOut: 0,
            timestamp: Date()
        )
    }
}

enum MemoryPressure: String {
    case nominal = "Normal"
    case warning = "Warning"
    case critical = "Critical"

    var color: String {
        switch self {
        case .nominal: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }
}

struct MetricsHistory {
    var entries: [SystemMetrics] = []
    let maxEntries: Int = 60  // Last 60 seconds

    mutating func add(_ metrics: SystemMetrics) {
        entries.append(metrics)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    var cpuHistory: [Double] {
        entries.map(\.cpuUsage)
    }

    var memoryHistory: [Double] {
        entries.map(\.memoryUsagePercent)
    }
}

struct ProcessInfo: Identifiable {
    let id: Int32  // pid
    let name: String
    let cpuUsage: Double
    let memoryBytes: Int64

    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: memoryBytes, countStyle: .memory)
    }
}
