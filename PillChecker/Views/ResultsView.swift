import SwiftUI
import SwiftData

struct ResultsView: View {
    let drugA: String
    let drugB: String
    let source: String
    let apiClient: APIClient
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ResultsViewModel

    init(drugA: String, drugB: String, source: String, apiClient: APIClient) {
        self.drugA = drugA
        self.drugB = drugB
        self.source = source
        self.apiClient = apiClient
        self._viewModel = State(initialValue: ResultsViewModel(apiClient: apiClient))
    }

    var body: some View {
        Group {
            if let result = viewModel.result {
                resultsContent(result)
            } else if viewModel.error != nil {
                errorView
            } else {
                loadingView
            }
        }
        .navigationTitle("Results")
        .task {
            await checkInteractions()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "pill.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.accent)
                .symbolEffect(.pulse)
            Text("Checking interactions...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error with retry

    private var errorView: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(viewModel.error ?? "Something went wrong.")
        } actions: {
            Button("Try Again") {
                Task { await checkInteractions() }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Results

    private func resultsContent(_ result: InteractionsResponse) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if result.safe {
                    SafeResultView(drugA: drugA, drugB: drugB)
                } else {
                    ForEach(Array(result.interactions.enumerated()), id: \.element.id) { index, interaction in
                        InteractionCard(
                            interaction: SavedInteraction(
                                drugA: interaction.drugA,
                                drugB: interaction.drugB,
                                severity: interaction.severity,
                                description: interaction.description,
                                management: interaction.management
                            ),
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }

                Button {
                    saveAndDismiss(result)
                } label: {
                    Text("Save & Done")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func checkInteractions() async {
        await viewModel.checkInteractions(drugA: drugA, drugB: drugB)
        if let result = viewModel.result {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(result.safe ? .success : .warning)
        }
    }

    private func saveAndDismiss(_ result: InteractionsResponse) {
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
