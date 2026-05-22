import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var licenseManager: LicenseManager
    @ObservedObject private var automation = AutomationEngine.shared
    @AppStorage("autoCleanEnabled") private var autoCleanEnabled = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            automationTab
                .tabItem {
                    Label("Automation", systemImage: "clock.arrow.2.circlepath")
                }

            accountTab
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
        .padding()
    }

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch MacPulse at login", isOn: $launchAtLogin)
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
            }

            Section("Notifications") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }

            Section("Safety") {
                LabeledContent("Protected paths") {
                    Text("System files are always protected")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Deletion mode") {
                    Text("Move to Trash (recoverable)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data") {
                Button("Reset Statistics") {
                    UserDefaults.standard.removeObject(forKey: "totalSpaceCleaned")
                    UserDefaults.standard.removeObject(forKey: "lastScanDate")
                }
                Button("Clear Deletion History") {
                    // Reset safety manager log
                }
            }
        }
        .formStyle(.grouped)
    }

    private var automationTab: some View {
        Form {
            Section("Auto Clean") {
                Toggle("Enable scheduled cleaning", isOn: $autoCleanEnabled)

                if autoCleanEnabled {
                    if !licenseManager.hasAccess(to: .automation) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("Automation requires MacPulse Pro")
                            Spacer()
                            Button("Upgrade") {
                                licenseManager.showUpgradeSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ForEach(automation.schedules) { schedule in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(schedule.frequency.rawValue)
                                        .fontWeight(.medium)
                                    if let lastRun = schedule.lastRun {
                                        Text("Last: \(lastRun.formatted())")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { schedule.isEnabled },
                                    set: { newValue in
                                        var updated = schedule
                                        updated.isEnabled = newValue
                                        automation.updateSchedule(updated)
                                    }
                                ))
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var accountTab: some View {
        Form {
            Section("Subscription") {
                LabeledContent("Plan") {
                    HStack {
                        Text(licenseManager.currentTier.displayName)
                            .fontWeight(.semibold)
                        if licenseManager.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                if licenseManager.currentTier == .trial {
                    LabeledContent("Trial") {
                        Text("\(licenseManager.trialDaysRemaining) days remaining")
                    }
                }

                if !licenseManager.isPremium {
                    Button("Start Free Trial") {
                        licenseManager.startTrial()
                    }
                    .disabled(licenseManager.trialExpiresAt != nil)

                    Button("Upgrade to Pro") {
                        licenseManager.showUpgradeSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Restore Purchases") {
                    Task { await licenseManager.restorePurchases() }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)

            Text("MacPulse")
                .font(.title)
                .fontWeight(.bold)

            Text("System Optimizer")
                .foregroundStyle(.secondary)

            Text("Version \(AppInfo.version) (Build \(AppInfo.build))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Developed by DevTharinda")
                .font(.caption)
                .fontWeight(.medium)

            Text("Copyright 2026 MacPulse. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
