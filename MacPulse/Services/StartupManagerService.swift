import Foundation

actor StartupManagerService {
    static let shared = StartupManagerService()

    private let fileManager = FileManager.default
    private let safetyManager = SafetyManager.shared

    func getStartupItems() async -> [StartupItem] {
        var items: [StartupItem] = []

        // Scan LaunchAgents
        items.append(contentsOf: scanLaunchItems(type: .launchAgent))
        items.append(contentsOf: scanLaunchItems(type: .launchDaemon))

        return items.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }

    private func scanLaunchItems(type: StartupItemType) -> [StartupItem] {
        var items: [StartupItem] = []

        for basePath in type.scanPaths {
            guard fileManager.fileExists(atPath: basePath),
                  let contents = try? fileManager.contentsOfDirectory(atPath: basePath) else { continue }

            for file in contents where file.hasSuffix(".plist") {
                let fullPath = (basePath as NSString).appendingPathComponent(file)
                guard let plist = NSDictionary(contentsOfFile: fullPath) else { continue }

                let label = plist["Label"] as? String ?? file
                let isDisabled = plist["Disabled"] as? Bool ?? false
                let bundleID = plist["Label"] as? String

                items.append(StartupItem(
                    name: file,
                    path: fullPath,
                    type: type,
                    isEnabled: !isDisabled,
                    bundleIdentifier: bundleID
                ))
            }
        }

        return items
    }

    func toggleItem(_ item: StartupItem, enabled: Bool) async throws {
        guard let bundleID = item.bundleIdentifier,
              safetyManager.isSafeToDisable(bundleID: bundleID) else {
            throw StartupError.protectedItem
        }

        let plistPath = item.path
        guard var plist = NSMutableDictionary(contentsOfFile: plistPath) else {
            throw StartupError.plistReadFailed
        }

        plist["Disabled"] = !enabled

        guard plist.write(toFile: plistPath, atomically: true) else {
            throw StartupError.plistWriteFailed
        }

        // Load/unload via launchctl
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = enabled ? ["load", plistPath] : ["unload", plistPath]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        Logger.shared.info(
            "\(enabled ? "Enabled" : "Disabled") startup item: \(item.name)",
            category: .app
        )
    }

    enum StartupError: LocalizedError {
        case protectedItem
        case plistReadFailed
        case plistWriteFailed

        var errorDescription: String? {
            switch self {
            case .protectedItem: return "This system item cannot be modified"
            case .plistReadFailed: return "Failed to read plist file"
            case .plistWriteFailed: return "Failed to write plist file"
            }
        }
    }
}
