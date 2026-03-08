import Foundation

struct InteractionResult: Codable, Identifiable, Hashable {
    let drugA: String
    let drugB: String
    let severity: String
    let description: String
    let management: String

    var id: String {
        let sorted = [drugA, drugB].sorted()
        return "\(sorted[0])-\(sorted[1])"
    }

    enum CodingKeys: String, CodingKey {
        case drugA = "drug_a"
        case drugB = "drug_b"
        case severity, description, management
    }
}
