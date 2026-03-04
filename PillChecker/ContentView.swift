//
//  ContentView.swift
//  PillChecker
//
//  Created by Svetlana Perekrestova on 3.03.26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppNavigator.self) private var navigator
    @State private var drugInputViewModel = DrugInputViewModel()

    private let apiClient = APIClient(baseURL: AppConfig.apiBaseURL)
    private let ocrService = OCRService()
    private let rxNormClient = RxNormClient()

    var body: some View {
        @Bindable var nav = navigator
        NavigationStack(path: $nav.path) {
            HistoryView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .drugInput:
                        DrugInputView(viewModel: drugInputViewModel)

                    case .scan(let slot):
                        ScanMedicineView(
                            slot: slot,
                            drugInputViewModel: drugInputViewModel,
                            apiClient: apiClient,
                            ocrService: ocrService
                        )

                    case .search(let slot):
                        DrugSearchView(
                            slot: slot,
                            drugInputViewModel: drugInputViewModel,
                            rxNormClient: rxNormClient
                        )

                    case .results(let drugA, let drugB):
                        ResultsView(
                            drugA: drugA,
                            drugB: drugB,
                            source: drugInputViewModel.hasScanned ? "scan" : "manual",
                            apiClient: apiClient
                        )

                    case .checkDetail(let id):
                        CheckDetailView(recordID: id)
                    }
                }
        }
        .onChange(of: navigator.path.isEmpty) { _, isEmpty in
            if isEmpty { drugInputViewModel.reset() }
        }
    }
}
