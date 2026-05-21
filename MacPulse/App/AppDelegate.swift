import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.info("MacPulse launched", category: .app)
        configureAppearance()
        SystemMonitor.shared.startMonitoring()
        AutomationEngine.shared.loadSchedules()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.info("MacPulse terminating", category: .app)
        SystemMonitor.shared.stopMonitoring()
        AutomationEngine.shared.saveSchedules()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false // Keep running in menu bar
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(self)
                    return false
                }
            }
        }
        return true
    }

    private func configureAppearance() {
        NSApplication.shared.appearance = nil // Follow system
    }
}
