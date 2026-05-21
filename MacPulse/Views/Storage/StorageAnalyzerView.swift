import SwiftUI

struct StorageAnalyzerView: View {
    @StateObject private var viewModel = StorageViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Analyzer")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Visualize disk usage and find large files")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                HStack(spacing: 8) {
                    Text("Min size:")
                        .font(.caption)
                    Picker("", selection: $viewModel.minimumSizeMB) {
                        Text("10 MB").tag(10.0)
                        Text("50 MB").tag(50.0)
                        Text("100 MB").tag(100.0)
                        Text("500 MB").tag(500.0)
                        Text("1 GB").tag(1024.0)
                    }
                    .frame(width: 100)
                }

                Button {
                    Task { await viewModel.scan() }
                } label: {
                    Label(viewModel.isScanning ? "Scanning..." : "Analyze", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning)
            }
            .padding(24)

            Divider()

            if viewModel.isScanning {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning files... \(viewModel.filesFound) found")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if viewModel.largeFiles.isEmpty && viewModel.breakdown.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "internaldrive")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("Click Analyze to scan your storage")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                resultsView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var resultsView: some View {
        HSplitView {
            // Storage breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Storage Breakdown")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.breakdown) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.blue)
                                Text(item.category)
                                Spacer()
                                Text(item.formattedSize)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .frame(minWidth: 250, idealWidth: 280)

            // Large files list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Large Files")
                        .font(.headline)
                    Spacer()

                    Picker("Sort:", selection: $viewModel.sortOrder) {
                        ForEach(StorageViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .frame(width: 120)

                    if viewModel.totalWaste > 0 {
                        Button {
                            Task { await viewModel.deleteSelected() }
                        } label: {
                            Label("Move to Trash (\(viewModel.formattedTotalWaste))", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(16)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewModel.sortedFiles.enumerated()), id: \.element.id) { index, file in
                            LargeFileRow(file: file) {
                                viewModel.toggleFile(at: index)
                            } reveal: {
                                viewModel.revealInFinder(file.path)
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}

struct LargeFileRow: View {
    let file: LargeFile
    let toggle: () -> Void
    let reveal: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggle) {
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(file.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: file.category.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.fileName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(file.directory)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let days = file.daysSinceModified {
                Text("\(days)d ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(file.formattedSize)
                .fontWeight(.semibold)
                .frame(width: 80, alignment: .trailing)

            Button(action: reveal) {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(file.isSelected ? Color.blue.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
