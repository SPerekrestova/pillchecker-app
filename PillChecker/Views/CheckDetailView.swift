import SwiftUI
import SwiftData

struct CheckDetailView: View {
    let recordID: UUID
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @Query private var allChecks: [CheckRecord]
    @State private var showDeleteConfirmation = false

    private var record: CheckRecord? {
        allChecks.first { $0.id == recordID }
    }

    var body: some View {
        Group {
            if let record {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(record.source == "scan" ? "AI Scan" : "Manual")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15), in: Capsule())

                            Text(record.checkedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(record.drugA) + \(record.drugB)")
                            .font(.title2.bold())

                        Divider()

                        if record.safe {
                            SafeResultView(drugA: record.drugA, drugB: record.drugB)
                        } else {
                            ForEach(Array(record.interactions.enumerated()), id: \.offset) { _, interaction in
                                InteractionCard(interaction: interaction)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("Not Found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("Check Detail")
        .toolbar {
            if record != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .alert("Delete Check?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let record {
                    modelContext.delete(record)
                    navigator.pop()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
