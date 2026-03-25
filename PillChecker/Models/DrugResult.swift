import Foundation

struct DrugResult: Codable, Identifiable, Hashable {
    let rxcui: String?
    let name: String
    let dosage: String?
    let form: String?
    let source: String
    let confidence: Double
    let needsConfirmation: Bool?

    var id: String { rxcui ?? name }

    enum CodingKeys: String, CodingKey {
        case rxcui, name, dosage, form, source, confidence
        case needsConfirmation = "needs_confirmation"
    }
}
