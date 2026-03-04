import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CheckRecord.checkedAt, order: .reverse) private var checks: [CheckRecord]
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        Group {
            if checks.isEmpty {
                ContentUnavailableView(
                    "No Checks Yet",
                    systemImage: "pill",
                    description: Text("Tap + to check your first drug interaction.")
                )
            } else {
                List {
                    ForEach(viewModel.filtered(checks)) { record in
                        Button {
                            navigator.navigate(to: .checkDetail(id: record.id))
                        } label: {
                            CheckHistoryCard(record: record)
                        }
                    }
                    .onDelete(perform: deleteChecks)
                }
            }
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

            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Button {
                        navigator.navigate(to: .drugInput)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor, in: Circle())
                            .shadow(radius: 4)
                    }
                }
            }
        }
    }

    private func deleteChecks(at offsets: IndexSet) {
        let filtered = viewModel.filtered(checks)
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}
