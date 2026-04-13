import Foundation

@Observable
@MainActor
final class ResultsViewModel {
    var result: InteractionsResponse?
    var isLoading = false
    var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func checkInteractions(drugA: String, drugB: String) async {
        isLoading = true
        error = nil
        result = nil

        do {
            result = try await apiClient.checkInteractions(drugs: [drugA, drugB])
            if let apiError = result?.error {
                self.error = apiError
                result = nil
            }
        } catch {
            self.error = (error as? APIError)?.errorDescription ?? "Something went wrong."
        }

        isLoading = false
    }
}
