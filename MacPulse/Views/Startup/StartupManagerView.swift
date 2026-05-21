import SwiftUI

struct StartupManagerView: View {
    @StateObject private var viewModel = StartupManagerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Startup Manager")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Manage applications and services that launch at startup")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                HStack(spacing: 12) {
                    Text("\(viewModel.enabledCount) enabled")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Picker("Filter", selection: $viewModel.filterType) {
                        Text("All").tag(nil as StartupItemType?)
                        ForEach(StartupItemType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as StartupItemType?)
                        }
                    }
                    .frame(width: 160)

                    Button {
                        Task { await viewModel.loadItems() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .padding(24)

            Divider()

            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading startup items...")
                    Spacer()
                }
            } else if viewModel.filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "power")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No startup items found")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredItems) { item in
                            StartupItemRow(item: item) {
                                Task { await viewModel.toggleItem(item) }
                            }
                        }
                    }
                    .padding(24)
                }
            }

            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.callout)
                    Spacer()
                    Button("Dismiss") { viewModel.errorMessage = nil }
                }
                .padding()
                .background(.orange.opacity(0.1))
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await viewModel.loadItems()
        }
    }
}

struct StartupItemRow: View {
    let item: StartupItem
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(item.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                    Text(item.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in toggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
