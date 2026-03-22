import SwiftUI
import SwiftData

struct CheckDetailView: View {
    let recordID: UUID
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @Query private var matchingChecks: [CheckRecord]
    @State private var showDeleteConfirmation = false

    init(recordID: UUID) {
        self.recordID = recordID
        let id = recordID
        _matchingChecks = Query(filter: #Predicate<CheckRecord> { $0.id == id })
    }

    private var record: CheckRecord? {
        matchingChecks.first
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
                                .background(Theme.accentSoft, in: Capsule())

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
                            ForEach(Array(record.interactions.enumerated()), id: \.element) { index, interaction in
                                InteractionCard(interaction: interaction, animationDelay: Double(index) * 0.1)
                            }
                        }

                        Text("For informational purposes only. Not a substitute for professional medical advice.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
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
