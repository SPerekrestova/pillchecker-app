import Foundation

struct AnalyzeRequest: Codable {
    let text: String
}

struct AnalyzeDataSources: Codable {
    let nerModel: String

    enum CodingKeys: String, CodingKey {
        case nerModel = "ner_model"
    }
}

struct InteractionsDataSources: Codable {
    let drugbankVersion: String?
    let severityClassifier: String

    enum CodingKeys: String, CodingKey {
        case drugbankVersion = "drugbank_version"
        case severityClassifier = "severity_classifier"
    }
}

struct AnalyzeResponse: Codable {
    let drugs: [DrugResult]
    let rawText: String
    let note: String?
    let dataSources: AnalyzeDataSources?

    enum CodingKeys: String, CodingKey {
        case drugs
        case rawText = "raw_text"
        case note
        case dataSources = "data_sources"
    }
}

struct InteractionsRequest: Codable {
    let drugs: [String]
}

struct InteractionsResponse: Codable {
    let interactions: [InteractionResult]
    let safe: Bool?
    let error: String?
    let limitations: [String]?
    let dataSources: InteractionsDataSources?

    enum CodingKeys: String, CodingKey {
        case interactions
        case safe
        case error
        case limitations
        case dataSources = "data_sources"
    }
}
