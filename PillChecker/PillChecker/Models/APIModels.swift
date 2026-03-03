import Foundation

struct AnalyzeRequest: Codable {
    let text: String
}

struct AnalyzeResponse: Codable {
    let drugs: [DrugResult]
    let rawText: String

    enum CodingKeys: String, CodingKey {
        case drugs
        case rawText = "raw_text"
    }
}

struct InteractionsRequest: Codable {
    let drugs: [String]
}

struct InteractionsResponse: Codable {
    let interactions: [InteractionResult]
    let safe: Bool
}
