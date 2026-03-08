import Foundation

enum APIError: Error, LocalizedError {
    case networkError(underlying: Error)
    case serverError(statusCode: Int)
    case validationError
    case unauthorized
    case decodingError(underlying: Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .networkError: return "Can't reach server. Check your connection."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .validationError: return "Invalid request. Please try again."
        case .unauthorized: return "Not authorized. Check API key."
        case .decodingError: return "Unexpected response. Please try again."
        case .timeout: return "Connection timed out. Check your network."
        }
    }
}

final class APIClient: Sendable {
    let baseURL: String
    private let apiKey: String
    private let session: URLSession

    init(baseURL: String, apiKey: String = "", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    func analyze(text: String) async throws -> AnalyzeResponse {
        let body = AnalyzeRequest(text: text)
        return try await post("/analyze", body: body)
    }

    func checkInteractions(drugs: [String]) async throws -> InteractionsResponse {
        let body = InteractionsRequest(drugs: drugs)
        return try await post("/interactions", body: body)
    }

    private func post<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request
    ) async throws -> Response {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.networkError(underlying: URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.timeout
        } catch {
            throw APIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(underlying: URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode == 422 {
            throw APIError.validationError
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.decodingError(underlying: error)
        }
    }
}
