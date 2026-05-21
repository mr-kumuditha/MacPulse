import Foundation

struct StartupItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let type: StartupItemType
    var isEnabled: Bool
    let bundleIdentifier: String?

    var displayName: String {
        name.replacingOccurrences(of: ".plist", with: "")
            .components(separatedBy: ".")
            .last ?? name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StartupItem, rhs: StartupItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum StartupItemType: String, CaseIterable {
    case loginItem = "Login Item"
    case launchAgent = "Launch Agent"
    case launchDaemon = "Launch Daemon"

    var icon: String {
        switch self {
        case .loginItem: return "person.crop.circle"
        case .launchAgent: return "gearshape.2"
        case .launchDaemon: return "server.rack"
        }
    }

    var scanPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .loginItem:
            return []  // Uses SMAppService API
        case .launchAgent:
            return [
                "\(home)/Library/LaunchAgents",
                "/Library/LaunchAgents"
            ]
        case .launchDaemon:
            return [
                "/Library/LaunchDaemons"
            ]
        }
    }
}
