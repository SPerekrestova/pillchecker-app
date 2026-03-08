import Foundation

@Observable
@MainActor
final class DrugSearchViewModel {
    var query = ""
    var suggestions: [String] = []
    var isSearching = false
    var searchError: String?

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
            searchError = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            defer { isSearching = false }

            searchError = nil

            do {
                let results = try await rxNormClient.suggestThrowing(query: currentQuery)
                guard !Task.isCancelled else { return }
                suggestions = results
            } catch {
                guard !Task.isCancelled else { return }
                suggestions = []
                searchError = "Couldn't load suggestions. Check your connection."
            }
        }
    }
}
