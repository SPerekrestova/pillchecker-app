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
            Image(systemName: "pill.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.accent)
                .symbolEffect(.pulse)
            Text("Checking interactions...")
                .foregroundStyle(.secondary)
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
                if result.safe == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.caution)
                        Text("Interaction data temporarily unavailable.")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Please try again later.")
                            .font(.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .cardStyle()
                } else if result.safe == true {
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
                            animationDelay: Double(index) * 0.1,
                            uncertain: interaction.uncertain ?? false
                        )
                    }
                }

                Text("For informational purposes only. Not a substitute for professional medical advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let limitations = result.limitations, !limitations.isEmpty {
                    DisclosureGroup("Important Information") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(limitations.enumerated()), id: \.offset) { _, item in
                                Text("• \(item)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if let ds = result.dataSources {
                                Divider()
                                    .padding(.vertical, 2)
                                if let version = ds.drugbankVersion {
                                    Text("Source: DrugBank \(version)")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Text("Classifier: \(ds.severityClassifier)")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal)
                }

                Button {
                    saveAndDismiss(result)
                } label: {
                    Text(result.safe == nil ? "Dismiss" : "Save & Done")
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
