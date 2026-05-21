import Foundation

struct PrivacyItem: Identifiable, Hashable {
    let id = UUID()
    let browser: Browser
    let category: PrivacyCategory
    let path: String
    let size: Int64
    var isSelected: Bool = true

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PrivacyItem, rhs: PrivacyItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum Browser: String, CaseIterable, Identifiable {
    case safari = "Safari"
    case chrome = "Chrome"
    case firefox = "Firefox"
    case brave = "Brave"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .safari: return "safari"
        case .chrome: return "globe"
        case .firefox: return "flame"
        case .brave: return "shield.lefthalf.filled"
        }
    }

    var isInstalled: Bool {
        let fm = FileManager.default
        switch self {
        case .safari: return true
        case .chrome: return fm.fileExists(atPath: "/Applications/Google Chrome.app")
        case .firefox: return fm.fileExists(atPath: "/Applications/Firefox.app")
        case .brave: return fm.fileExists(atPath: "/Applications/Brave Browser.app")
        }
    }
}

enum PrivacyCategory: String, CaseIterable {
    case history = "Browsing History"
    case cookies = "Cookies"
    case cache = "Cache"
    case sessions = "Session Data"

    var icon: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .cookies: return "birthday.cake"
        case .cache: return "internaldrive"
        case .sessions: return "rectangle.stack"
        }
    }
}

struct CleaningSchedule: Identifiable, Codable {
    let id: UUID
    var isEnabled: Bool
    var frequency: ScheduleFrequency
    var categories: [String]  // CleaningCategory rawValues
    var lastRun: Date?
    var nextRun: Date?

    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        frequency: ScheduleFrequency = .weekly,
        categories: [String] = CleaningCategory.allCases.map(\.rawValue)
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.frequency = frequency
        self.categories = categories
    }
}

enum ScheduleFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"

    var interval: TimeInterval {
        switch self {
        case .daily: return 86400
        case .weekly: return 604800
        case .biweekly: return 1209600
        case .monthly: return 2592000
        }
    }
}
