import SwiftUI

struct DrugSearchView: View {
    let slot: Int
    let drugInputViewModel: DrugInputViewModel
    @Environment(AppNavigator.self) private var navigator
    @State private var viewModel: DrugSearchViewModel

    init(slot: Int, drugInputViewModel: DrugInputViewModel, rxNormClient: RxNormClient) {
        self.slot = slot
        self.drugInputViewModel = drugInputViewModel
        self._viewModel = State(initialValue: DrugSearchViewModel(rxNormClient: rxNormClient))
    }

    private var network = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 0) {
            if !network.isConnected {
                OfflineBanner()
            }

            HStack {
                TextField("Type drug name...", text: $viewModel.query)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Drug name search")
                    .onSubmit { selectCustom() }
                    .onChange(of: viewModel.query) {
                        viewModel.search()
                    }

                if viewModel.isSearching {
                    ProgressView()
                        .padding(.leading, 4)
                }
            }
            .padding()

            if let error = viewModel.searchError {
                ErrorStateView(message: error) {
                    viewModel.search()
                }
                .padding(.top, 32)
            } else if !viewModel.suggestions.isEmpty {
                List(viewModel.suggestions, id: \.self) { name in
                    Button {
                        select(name: name)
                    } label: {
                        Text(name)
                    }
                }
                .listStyle(.plain)
            } else if !viewModel.query.isEmpty && viewModel.query.count >= 2 && !viewModel.isSearching {
                VStack(spacing: 8) {
                    Text("No suggestions found.")
                        .foregroundStyle(.secondary)
                    Text("Press return to use \"\(viewModel.query)\"")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
            }

            Spacer()
        }
        .navigationTitle("Search Drug")
    }

    private func select(name: String) {
        drugInputViewModel.setManualName(index: slot, name: name)
        navigator.pop()
    }

    private func selectCustom() {
        let name = viewModel.query.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        drugInputViewModel.setManualName(index: slot, name: name)
        navigator.pop()
    }
}
