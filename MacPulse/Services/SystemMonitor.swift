import Foundation
import Combine
import IOKit

final class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    @Published var currentMetrics: SystemMetrics = .empty
    @Published var history = MetricsHistory()
    @Published var topProcesses: [ProcessInfo] = []

    private var timer: Timer?
    private let updateInterval: TimeInterval = 2.0

    private init() {}

    func startMonitoring() {
        stopMonitoring()
        updateMetrics()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMetrics() {
        let metrics = SystemMetrics(
            cpuUsage: getCPUUsage(),
            memoryUsed: getMemoryUsed(),
            memoryTotal: getMemoryTotal(),
            memoryPressure: getMemoryPressure(),
            diskUsed: getDiskUsed(),
            diskTotal: getDiskTotal(),
            networkBytesIn: 0,
            networkBytesOut: 0,
            timestamp: Date()
        )

        DispatchQueue.main.async { [weak self] in
            self?.currentMetrics = metrics
            self?.history.add(metrics)
        }

        updateTopProcesses()
    }

    // MARK: - CPU

    private var previousCPUInfo: host_cpu_load_info?

    private func getCPUUsage() -> Double {
        var cpuInfo: host_cpu_load_info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &cpuInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let user = Double(cpuInfo.cpu_ticks.0)
        let system = Double(cpuInfo.cpu_ticks.1)
        let idle = Double(cpuInfo.cpu_ticks.2)
        let nice = Double(cpuInfo.cpu_ticks.3)

        if let prev = previousCPUInfo {
            let userDiff = user - Double(prev.cpu_ticks.0)
            let systemDiff = system - Double(prev.cpu_ticks.1)
            let idleDiff = idle - Double(prev.cpu_ticks.2)
            let niceDiff = nice - Double(prev.cpu_ticks.3)
            let totalDiff = userDiff + systemDiff + idleDiff + niceDiff

            previousCPUInfo = cpuInfo

            guard totalDiff > 0 else { return 0 }
            return ((userDiff + systemDiff + niceDiff) / totalDiff) * 100
        }

        previousCPUInfo = cpuInfo
        let total = user + system + idle + nice
        guard total > 0 else { return 0 }
        return ((user + system + nice) / total) * 100
    }

    // MARK: - Memory

    private func getMemoryUsed() -> Int64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = Int64(vm_kernel_page_size)
        let active = Int64(stats.active_count) * pageSize
        let wired = Int64(stats.wire_count) * pageSize
        let compressed = Int64(stats.compressor_page_count) * pageSize

        return active + wired + compressed
    }

    private func getMemoryTotal() -> Int64 {
        var size: Int64 = 0
        var len = MemoryLayout<Int64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }

    private func getMemoryPressure() -> MemoryPressure {
        let used = getMemoryUsed()
        let total = getMemoryTotal()
        guard total > 0 else { return .nominal }

        let ratio = Double(used) / Double(total)
        if ratio > 0.9 { return .critical }
        if ratio > 0.75 { return .warning }
        return .nominal
    }

    // MARK: - Disk

    private func getDiskUsed() -> Int64 {
        getDiskTotal() - getDiskFree()
    }

    private func getDiskTotal() -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else { return 0 }
        return (attrs[.systemSize] as? Int64) ?? 0
    }

    private func getDiskFree() -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else { return 0 }
        return (attrs[.systemFreeSize] as? Int64) ?? 0
    }

    // MARK: - Processes

    private func updateTopProcesses() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let pipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/ps")
            process.arguments = ["-Arco", "pid,pcpu,rss,comm"]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
            } catch { return }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return }

            let processes = output.components(separatedBy: "\n")
                .dropFirst()
                .prefix(10)
                .compactMap { line -> ProcessInfo? in
                    let parts = line.trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: .whitespaces)
                        .filter { !$0.isEmpty }
                    guard parts.count >= 4,
                          let pid = Int32(parts[0]),
                          let cpu = Double(parts[1]),
                          let rss = Int64(parts[2]) else { return nil }
                    let name = parts[3...].joined(separator: " ")
                    return ProcessInfo(id: pid, name: name, cpuUsage: cpu, memoryBytes: rss * 1024)
                }

            DispatchQueue.main.async {
                self?.topProcesses = processes
            }
        }
    }
}
