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

    private var network = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 0) {
            if !network.isConnected {
                OfflineBanner()
            }

            Group {
                if let result = viewModel.result {
                    resultsContent(result)
                } else if viewModel.error != nil {
                    errorView
                } else {
                    loadingView
                }
            }
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("Results")
        .task {
            await checkInteractions()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 56, height: 56)
                Image(systemName: "pill.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse)
            }
            Text("Checking interactions...")
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
            Text("This usually takes a moment")
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
        .padding()
    }

    // MARK: - Error with retry

    private var errorView: some View {
        ErrorStateView(message: viewModel.error ?? "Something went wrong.") {
            Task { await checkInteractions() }
        }
    }

    // MARK: - Results

    private func resultsContent(_ result: InteractionsResponse) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if result.safe == true {
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

                Text("For informational purposes only. Not a substitute for professional medical advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

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
            generator.notificationOccurred(result.safe == true ? .success : .warning)
            UIAccessibility.post(
                notification: .screenChanged,
                argument: result.safe == true ? "No known interactions found" : "Interactions found"
            )
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
            safe: result.safe ?? false,
            interactions: interactions,
            source: source
        )

        modelContext.insert(record)
        navigator.popToRoot()
    }
}
