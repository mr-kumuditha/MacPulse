import SwiftUI

@main
struct MacPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var licenseManager = LicenseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(licenseManager)
                .frame(minWidth: 900, minHeight: 620)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // Sparkle integration point
                }
            }
            CommandMenu("Scan") {
                Button("Smart Scan") {
                    NotificationCenter.default.post(name: .startSmartScan, object: nil)
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])

                Button("Quick Clean") {
                    NotificationCenter.default.post(name: .startQuickClean, object: nil)
                }
                .keyboardShortcut("K", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("MacPulse", systemImage: "bolt.shield.fill") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(licenseManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(licenseManager)
        }
    }
}

extension Notification.Name {
    static let startSmartScan = Notification.Name("startSmartScan")
    static let startQuickClean = Notification.Name("startQuickClean")
}
