import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startSmartScan)) { _ in
            appState.selectedNavigation = .smartClean
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNavigation {
        case .dashboard:
            DashboardView()
        case .smartClean:
            ScanView()
        case .duplicates:
            DuplicateFinderView()
        case .storage:
            StorageAnalyzerView()
        case .monitor:
            SystemMonitorView()
        case .startup:
            StartupManagerView()
        case .uninstaller:
            AppUninstallerView()
        case .privacy:
            PrivacyCleanerView()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        List(AppState.NavigationItem.allCases, selection: $appState.selectedNavigation) { item in
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.rawValue)
                        .font(.body)
                    Text(item.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: item.icon)
                    .foregroundStyle(item == appState.selectedNavigation ? .white : .accentColor)
                    .frame(width: 20)
            }
            .tag(item)
            .padding(.vertical, 2)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            if !licenseManager.isPremium {
                upgradeButton
            }
        }
    }

    private var upgradeButton: some View {
        Button {
            licenseManager.showUpgradeSheet = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text("Upgrade to Pro")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding()
    }
}
