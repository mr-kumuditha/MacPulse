import SwiftUI

struct PrivacyCleanerView: View {
    @StateObject private var viewModel = PrivacyViewModel()
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy Cleaner")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Remove browsing traces and protect your privacy")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if !viewModel.items.isEmpty {
                    HStack(spacing: 8) {
                        Button("Select All") { viewModel.toggleAll(true) }
                        Button("Deselect All") { viewModel.toggleAll(false) }
                    }
                }
            }
            .padding(24)

            Divider()

            if !licenseManager.hasAccess(to: .privacyClean) {
                premiumRequiredView
            } else if viewModel.isScanning {
                VStack {
                    Spacer()
                    ProgressView("Scanning browsers...")
                    Spacer()
                }
            } else if viewModel.items.isEmpty {
                idleView
            } else {
                resultsView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Scan your browsers for privacy data")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(Browser.allCases) { browser in
                    VStack(spacing: 4) {
                        Image(systemName: browser.icon)
                            .font(.title2)
                        Text(browser.rawValue)
                            .font(.caption)
                        Text(browser.isInstalled ? "Installed" : "Not found")
                            .font(.caption2)
                            .foregroundStyle(browser.isInstalled ? .green : .secondary)
                    }
                    .frame(width: 80)
                }
            }

            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Scan Browsers", systemImage: "magnifyingglass")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Browser filter
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: viewModel.selectedBrowser == nil) {
                    viewModel.selectedBrowser = nil
                }
                ForEach(Browser.allCases) { browser in
                    FilterChip(
                        title: browser.rawValue,
                        isSelected: viewModel.selectedBrowser == browser
                    ) {
                        viewModel.selectedBrowser = browser
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                        PrivacyItemRow(item: item) {
                            viewModel.items[index].isSelected.toggle()
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // Action bar
            HStack {
                if let message = viewModel.resultMessage {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Selected: \(viewModel.formattedTotalSize)")
                        .font(.headline)
                }
                Spacer()

                Button("New Scan") {
                    Task { await viewModel.scan() }
                }

                Button {
                    Task { await viewModel.clean() }
                } label: {
                    Label("Clean Selected", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.isCleaning || viewModel.totalSize == 0)
            }
            .padding(16)
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
            Text("Privacy Cleaner is available with MacPulse Pro")
                .foregroundStyle(.secondary)
            Button("Upgrade to Pro") {
                licenseManager.showUpgradeSheet = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

struct PrivacyItemRow: View {
    let item: PrivacyItem
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: item.browser.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.browser.rawValue)
                        .fontWeight(.medium)
                    Text("-")
                        .foregroundStyle(.secondary)
                    Text(item.category.rawValue)
                }
                Text(item.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.formattedSize)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.quaternary))
        }
        .buttonStyle(.plain)
    }
}
