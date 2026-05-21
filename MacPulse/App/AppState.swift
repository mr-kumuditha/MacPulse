import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    enum NavigationItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case smartClean = "Smart Clean"
        case duplicates = "Duplicates"
        case storage = "Storage"
        case monitor = "Monitor"
        case startup = "Startup"
        case uninstaller = "Uninstaller"
        case privacy = "Privacy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "gauge.open.with.lines.needle.33percent.and.arrowtriangle"
            case .smartClean: return "sparkles"
            case .duplicates: return "doc.on.doc"
            case .storage: return "internaldrive"
            case .monitor: return "waveform.path.ecg"
            case .startup: return "power"
            case .uninstaller: return "trash"
            case .privacy: return "hand.raised.fill"
            }
        }

        var description: String {
            switch self {
            case .dashboard: return "Overview"
            case .smartClean: return "Clean junk files"
            case .duplicates: return "Find duplicates"
            case .storage: return "Analyze storage"
            case .monitor: return "System monitor"
            case .startup: return "Startup items"
            case .uninstaller: return "Remove apps"
            case .privacy: return "Privacy cleanup"
            }
        }
    }

    @Published var selectedNavigation: NavigationItem = .dashboard
    @Published var isScanning = false
    @Published var lastScanDate: Date?
    @Published var totalSpaceCleaned: Int64 = 0

    private init() {
        loadState()
    }

    func recordCleaning(bytes: Int64) {
        totalSpaceCleaned += bytes
        lastScanDate = Date()
        saveState()
    }

    private func loadState() {
        totalSpaceCleaned = Int64(UserDefaults.standard.integer(forKey: "totalSpaceCleaned"))
        if let date = UserDefaults.standard.object(forKey: "lastScanDate") as? Date {
            lastScanDate = date
        }
    }

    private func saveState() {
        UserDefaults.standard.set(Int(totalSpaceCleaned), forKey: "totalSpaceCleaned")
        UserDefaults.standard.set(lastScanDate, forKey: "lastScanDate")
    }
}
