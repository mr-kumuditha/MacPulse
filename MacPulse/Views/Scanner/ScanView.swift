import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(24)

            Divider()

            if viewModel.phase == .idle {
                categorySelectionView
            } else if case .complete = viewModel.phase {
                scanResultsView
            } else {
                scanningView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $licenseManager.showUpgradeSheet) {
            PremiumUpgradeView()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Clean")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Scan and remove junk files to free up space")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if case .complete = viewModel.phase {
                Button("New Scan") {
                    viewModel.phase = .idle
                }
            }
        }
    }

    private var categorySelectionView: some View {
        VStack(spacing: 20) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(CleaningCategory.allCases) { category in
                        CategoryToggleCard(
                            category: category,
                            isSelected: viewModel.selectedCategories.contains(category),
                            isLocked: category.requiresPremium && !licenseManager.isPremium
                        ) {
                            if category.requiresPremium && !licenseManager.isPremium {
                                licenseManager.showUpgradeSheet = true
                            } else {
                                viewModel.toggleCategory(category)
                            }
                        }
                    }
                }
                .padding(24)
            }

            // Start scan button
            Button {
                Task { await viewModel.startScan() }
            } label: {
                Label("Start Scan", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .disabled(viewModel.selectedCategories.isEmpty)
        }
    }

    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: viewModel.progress) {
                Text(viewModel.phase.description)
                    .font(.headline)
            }
            .progressViewStyle(.linear)
            .frame(maxWidth: 400)

            Text(String(format: "%.0f%%", viewModel.progress * 100))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
    }

    private var scanResultsView: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.formattedTotalSize)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(viewModel.totalFiles) files found")
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if let message = viewModel.cleaningResult {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    VStack(alignment: .trailing) {
                        Text("Selected: \(viewModel.formattedSelectedSize)")
                            .font(.headline)
                        Button {
                            Task { await viewModel.clean() }
                        } label: {
                            Label("Clean Selected", systemImage: "trash")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(viewModel.isCleaningInProgress)
                    }
                }
            }
            .padding(24)

            Divider()

            // Results list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.categorySummaries) { summary in
                        CategoryResultCard(
                            summary: summary,
                            isSelected: viewModel.selectedCategories.contains(summary.category)
                        ) {
                            viewModel.toggleCategory(summary.category)
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

struct CategoryToggleCard: View {
    let category: CleaningCategory
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? category.color : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(category.displayName)
                            .fontWeight(.medium)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    Text(category.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(12)
            .background(isSelected ? category.color.opacity(0.08) : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? category.color.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryResultCard: View {
    let summary: CategorySummary
    let isSelected: Bool
    let toggle: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 12) {
                    Button(action: toggle) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: summary.category.icon)
                        .foregroundStyle(summary.category.color)
                        .frame(width: 24)

                    Text(summary.category.displayName)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(summary.fileCount) files")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    Text(summary.formattedSize)
                        .fontWeight(.semibold)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                VStack(spacing: 4) {
                    ForEach(summary.results.prefix(20)) { result in
                        HStack {
                            Text(result.fileName)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Text(result.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    }
                    if summary.results.count > 20 {
                        Text("+ \(summary.results.count - 20) more files")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
