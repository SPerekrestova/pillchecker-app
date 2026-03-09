import Foundation

enum AppConfig {
    private nonisolated(unsafe) static let config: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "AppConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return [:] }
        return dict
    }()

    static let apiBaseURL: String = {
        if let url = config["API_BASE_URL"] as? String, !url.isEmpty {
            return url
        }
        return "http://localhost:8000"
    }()

    static let apiKey: String = {
        if let key = config["API_KEY"] as? String, !key.isEmpty {
            return key
        }
        return ""
    }()
}
