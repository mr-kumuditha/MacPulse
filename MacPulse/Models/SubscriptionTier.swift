import Foundation

enum SubscriptionTier: String, Codable {
    case free = "free"
    case trial = "trial"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .trial: return "Trial"
        case .premium: return "Pro"
        }
    }

    var features: [PremiumFeature] {
        switch self {
        case .free:
            return [.smartClean, .basicMonitor]
        case .trial, .premium:
            return PremiumFeature.allCases
        }
    }
}

enum PremiumFeature: String, CaseIterable, Identifiable {
    case smartClean = "Smart Clean"
    case duplicateFinder = "Duplicate Finder"
    case advancedCleanup = "Advanced Cleanup"
    case realtimeMonitor = "Real-time Monitor"
    case automation = "Automation Engine"
    case privacyClean = "Privacy Cleaner"
    case appUninstaller = "App Uninstaller"
    case basicMonitor = "Basic Monitor"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .smartClean: return "Scan and clean common junk files"
        case .duplicateFinder: return "Find and remove duplicate files"
        case .advancedCleanup: return "Deep cleaning including app leftovers and iOS backups"
        case .realtimeMonitor: return "Live CPU, RAM, disk, and network monitoring"
        case .automation: return "Scheduled cleaning and smart notifications"
        case .privacyClean: return "Browser history, cookies, and session cleanup"
        case .appUninstaller: return "Complete application removal with leftovers"
        case .basicMonitor: return "Disk usage overview"
        }
    }

    var icon: String {
        switch self {
        case .smartClean: return "sparkles"
        case .duplicateFinder: return "doc.on.doc"
        case .advancedCleanup: return "wrench.and.screwdriver"
        case .realtimeMonitor: return "waveform.path.ecg"
        case .automation: return "clock.arrow.2.circlepath"
        case .privacyClean: return "hand.raised.fill"
        case .appUninstaller: return "trash"
        case .basicMonitor: return "gauge.open.with.lines.needle.33percent.and.arrowtriangle"
        }
    }

    var isFree: Bool {
        switch self {
        case .smartClean, .basicMonitor: return true
        default: return false
        }
    }
}
