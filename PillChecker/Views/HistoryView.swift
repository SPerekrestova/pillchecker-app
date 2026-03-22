import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CheckRecord.checkedAt, order: .reverse) private var checks: [CheckRecord]
    @State private var viewModel = HistoryViewModel()
    @State private var pendingDeleteIDs: [UUID] = []
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if checks.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.accentSoft)
                            .frame(width: 64, height: 64)
                        Image(systemName: "pill.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.accent)
                    }
                    Text("No checks yet")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tap + to check your first drug interaction.")
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.filtered(checks)) { record in
                        Button {
                            navigator.navigate(to: .checkDetail(id: record.id))
                        } label: {
                            CheckHistoryCard(record: record)
                        }
                    }
                    .onDelete { offsets in
                        let filtered = viewModel.filtered(checks)
                        pendingDeleteIDs = offsets.map { filtered[$0].id }
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .alert("Delete Check?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                for check in checks where pendingDeleteIDs.contains(check.id) {
                    modelContext.delete(check)
                }
                pendingDeleteIDs = []
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteIDs = []
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .navigationTitle("PillChecker")
        .searchable(text: $viewModel.searchQuery, prompt: "Search drugs")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Sort", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    navigator.navigate(to: .drugInput)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("newCheckButton")
                .accessibilityLabel("New Check")
            }
        }
    }
}
