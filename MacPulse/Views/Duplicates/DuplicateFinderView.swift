import SwiftUI

struct DuplicateFinderView: View {
    @StateObject private var viewModel = DuplicateFinderViewModel()
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duplicate Finder")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Find and remove duplicate files to reclaim disk space")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            Divider()

            if !licenseManager.hasAccess(to: .duplicateFinder) {
                premiumRequired
            } else {
                content
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            idleView
        case .complete:
            resultsView
        default:
            scanningView
        }
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.on.doc")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Scan your files to find duplicates")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.startScan() }
            } label: {
                Label("Find Duplicates", systemImage: "magnifyingglass")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
    }

    private var scanningView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .controlSize(.large)

            switch viewModel.phase {
            case .indexing(let count):
                Text("Indexing files... \(count) found")
            case .hashing(let progress):
                VStack {
                    Text("Computing file hashes...")
                    ProgressView(value: progress)
                        .frame(maxWidth: 300)
                }
            case .comparing:
                Text("Comparing files...")
            default:
                Text("Processing...")
            }
            Spacer()
        }
        .font(.headline)
        .foregroundStyle(.secondary)
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack {
                VStack(alignment: .leading) {
                    Text("\(viewModel.groups.count) duplicate groups")
                        .font(.headline)
                    Text("Wasted space: \(viewModel.formattedWastedSpace)")
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if let message = viewModel.resultMessage {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                }

                Button("Auto-Select") {
                    viewModel.autoSelectDuplicates()
                }

                Button {
                    Task { await viewModel.deleteSelected() }
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.isDeleting)
            }
            .padding(16)

            Divider()

            if viewModel.groups.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("No duplicates found!")
                        .font(.title3)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.groups) { group in
                            DuplicateGroupCard(group: group)
                        }
                    }
                    .padding(16)
                }
            }

            Button("New Scan") {
                viewModel.phase = .idle
                viewModel.groups = []
            }
            .padding()
        }
    }

    private var premiumRequired: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
            Text("Duplicate Finder is available with MacPulse Pro")
                .foregroundStyle(.secondary)
            Button("Upgrade to Pro") {
                licenseManager.showUpgradeSheet = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { isExpanded.toggle() } label: {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundStyle(.orange)
                    Text("\(group.files.count) copies")
                        .fontWeight(.medium)
                    Text("- \(group.files.first?.fileName ?? "")")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text(group.formattedWastedSpace)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                ForEach(group.files) { file in
                    HStack {
                        Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(file.isSelected ? .blue : .secondary)
                        VStack(alignment: .leading) {
                            Text(file.fileName)
                                .font(.callout)
                            Text(file.directory)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(file.formattedSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
