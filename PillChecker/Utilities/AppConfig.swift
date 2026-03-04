import Foundation

enum AppConfig {
    static let apiBaseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "http://localhost:8000"
    }()
}
