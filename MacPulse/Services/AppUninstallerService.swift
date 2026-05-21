import Foundation
import AppKit

actor AppUninstallerService {
    static let shared = AppUninstallerService()

    private let fileManager = FileManager.default

    func getInstalledApps() async -> [InstalledApp] {
        var apps: [InstalledApp] = []

        let appDirectories = [
            "/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        for dir in appDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let appPath = (dir as NSString).appendingPathComponent(item)
                let bundlePath = URL(fileURLWithPath: appPath)

                guard let bundle = Bundle(url: bundlePath) else { continue }

                let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? item.replacingOccurrences(of: ".app", with: "")
                let bundleID = bundle.bundleIdentifier
                let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

                let size = await FileOperationService.shared.directorySize(at: appPath)

                let icon = await MainActor.run {
                    NSWorkspace.shared.icon(forFile: appPath)
                }

                let lastUsed = (try? fileManager.attributesOfItem(atPath: appPath))?[.modificationDate] as? Date

                apps.append(InstalledApp(
                    name: name,
                    path: appPath,
                    bundleIdentifier: bundleID,
                    version: version,
                    size: size,
                    icon: icon,
                    lastUsedDate: lastUsed
                ))
            }
        }

        return apps.sorted { $0.size > $1.size }
    }

    func findLeftovers(for app: InstalledApp) async -> [AppLeftover] {
        var leftovers: [AppLeftover] = []

        for path in app.relatedPaths {
            guard fileManager.fileExists(atPath: path) else { continue }

            let size = await FileOperationService.shared.directorySize(at: path)
            guard size > 0 else { continue }

            let type = categorizeLeftover(path: path)
            leftovers.append(AppLeftover(path: path, size: size, type: type))
        }

        return leftovers.sorted { $0.size > $1.size }
    }

    func uninstallApp(_ app: InstalledApp, includeLeftovers: Bool) async throws -> Int64 {
        var freedSpace: Int64 = 0

        // Move app to trash
        let result = await FileOperationService.shared.moveToTrash([app.path])
        freedSpace += result.freedBytes

        if includeLeftovers {
            let leftovers = await findLeftovers(for: app)
            let paths = leftovers.map(\.path)
            let leftoverResult = await FileOperationService.shared.deleteFiles(paths, category: "uninstall")
            freedSpace += leftoverResult.freedBytes
        }

        Logger.shared.info("Uninstalled \(app.name), freed \(freedSpace) bytes", category: .clean)
        return freedSpace
    }

    private func categorizeLeftover(path: String) -> LeftoverType {
        if path.contains("/Preferences/") { return .preferences }
        if path.contains("/Caches/") { return .cache }
        if path.contains("/Application Support/") { return .applicationSupport }
        if path.contains("/Saved Application State/") { return .savedState }
        if path.contains("/Containers/") { return .container }
        if path.contains("/Logs/") { return .logs }
        return .other
    }
}
