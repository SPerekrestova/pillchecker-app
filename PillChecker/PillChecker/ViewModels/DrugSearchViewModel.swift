import Foundation

@Observable
@MainActor
final class DrugSearchViewModel {
    var query = ""
    var suggestions: [String] = []
    var isSearching = false

    private let rxNormClient: RxNormClient
    private var searchTask: Task<Void, Never>?

    init(rxNormClient: RxNormClient) {
        self.rxNormClient = rxNormClient
    }

    func search() {
        searchTask?.cancel()

        let currentQuery = query
        guard currentQuery.trimmingCharacters(in: .whitespaces).count >= 2 else {
            suggestions = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            let results = await rxNormClient.suggest(query: currentQuery)
            guard !Task.isCancelled else { return }

            suggestions = results
            isSearching = false
        }
    }
}
