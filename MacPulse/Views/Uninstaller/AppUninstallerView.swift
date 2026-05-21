import SwiftUI

struct AppUninstallerView: View {
    @StateObject private var viewModel = UninstallerViewModel()
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Uninstaller")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Completely remove apps and their leftover files")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            Divider()

            if !licenseManager.hasAccess(to: .appUninstaller) {
                premiumRequiredView
            } else {
                uninstallerContent
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            if licenseManager.hasAccess(to: .appUninstaller) {
                await viewModel.loadApps()
            }
        }
    }

    private var uninstallerContent: some View {
        HSplitView {
            appListView
                .frame(minWidth: 300, idealWidth: 350)
            appDetailView
        }
    }

    private var appListView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search apps...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)

                Picker("Sort:", selection: $viewModel.sortOrder) {
                    ForEach(UninstallerViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .frame(width: 110)
            }
            .padding(12)

            Divider()

            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading apps...")
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.filteredApps) { app in
                            AppRow(app: app, isSelected: viewModel.selectedApp?.id == app.id) {
                                Task { await viewModel.selectApp(app) }
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    @ViewBuilder
    private var appDetailView: some View {
        if let app = viewModel.selectedApp {
            VStack(spacing: 0) {
                // App header
                HStack(spacing: 16) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let version = app.version {
                            Text("Version \(version)")
                                .foregroundStyle(.secondary)
                        }
                        Text(app.formattedSize)
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Button {
                            Task { await viewModel.uninstallSelected(includeLeftovers: true) }
                        } label: {
                            Label("Complete Uninstall", systemImage: "trash.fill")
                                .frame(width: 180)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(viewModel.isUninstalling)

                        Button {
                            viewModel.revealInFinder(app.path)
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                                .frame(width: 180)
                        }
                    }
                }
                .padding(24)

                Divider()

                if let message = viewModel.resultMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                        Spacer()
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                }

                // Leftovers
                if !viewModel.leftovers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Files")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(viewModel.leftovers) { leftover in
                                    HStack {
                                        Image(systemName: "doc")
                                            .foregroundStyle(.secondary)
                                        VStack(alignment: .leading) {
                                            Text((leftover.path as NSString).lastPathComponent)
                                                .font(.callout)
                                            Text(leftover.type.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(leftover.formattedSize)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                } else {
                    Spacer()
                    Text("No leftover files found")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        } else {
            VStack {
                Spacer()
                Image(systemName: "arrow.left")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Select an app to see details")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private var premiumRequiredView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
            Text("App Uninstaller is available with MacPulse Pro")
                .foregroundStyle(.secondary)
            Button("Upgrade to Pro") {
                licenseManager.showUpgradeSheet = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

struct AppRow: View {
    let app: InstalledApp
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 10) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.fill")
                        .font(.title2)
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(app.name)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(app.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
