import SwiftUI
import SwiftData

struct ResultsView: View {
    let drugA: String
    let drugB: String
    let source: String
    let apiClient: APIClient
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @State private var result: InteractionsResponse?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Checking interactions...")
            } else if let error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let result {
                ScrollView {
                    VStack(spacing: 16) {
                        if result.safe {
                            SafeResultView(drugA: drugA, drugB: drugB)
                        } else {
                            ForEach(result.interactions) { interaction in
                                InteractionCard(interaction: SavedInteraction(
                                    drugA: interaction.drugA,
                                    drugB: interaction.drugB,
                                    severity: interaction.severity,
                                    description: interaction.description,
                                    management: interaction.management
                                ))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Results")
        .toolbar {
            if result != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .task {
            isLoading = true
            do {
                result = try await apiClient.checkInteractions(drugs: [drugA, drugB])
            } catch {
                self.error = (error as? APIError)?.errorDescription ?? "Something went wrong."
            }
            isLoading = false
        }
    }

    private func saveAndDismiss() {
        guard let result else { return }

        let interactions = result.interactions.map {
            SavedInteraction(
                drugA: $0.drugA,
                drugB: $0.drugB,
                severity: $0.severity,
                description: $0.description,
                management: $0.management
            )
        }

        let record = CheckRecord(
            drugA: drugA,
            drugB: drugB,
            safe: result.safe,
            interactions: interactions,
            source: source
        )

        modelContext.insert(record)
        navigator.popToRoot()
    }
}
