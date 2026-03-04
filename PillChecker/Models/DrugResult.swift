import Foundation

struct DrugResult: Codable, Identifiable, Hashable {
    let rxcui: String?
    let name: String
    let dosage: String?
    let form: String?
    let source: String
    let confidence: Double

    var id: String { rxcui ?? name }
}
