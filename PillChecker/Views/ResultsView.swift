import SwiftUI
import SwiftData

struct ResultsView: View {
    let drugA: String
    let drugB: String
    let source: String
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ResultsViewModel

    init(drugA: String, drugB: String, source: String, apiClient: APIClient) {
        self.drugA = drugA
        self.drugB = drugB
        self.source = source
        self._viewModel = State(initialValue: ResultsViewModel(apiClient: apiClient))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Checking interactions...")
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let result = viewModel.result {
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
            if viewModel.result != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.checkInteractions(drugA: drugA, drugB: drugB)
        }
    }

    private func saveAndDismiss() {
        guard let result = viewModel.result else { return }

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
