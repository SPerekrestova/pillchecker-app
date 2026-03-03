import Foundation
import SwiftData

struct SavedInteraction: Codable, Hashable {
    let drugA: String
    let drugB: String
    let severity: String
    let description: String
    let management: String
}

@Model
final class CheckRecord {
    var id: UUID
    var drugA: String
    var drugB: String
    var safe: Bool
    var interactions: [SavedInteraction]
    var checkedAt: Date
    var source: String

    init(
        drugA: String,
        drugB: String,
        safe: Bool,
        interactions: [SavedInteraction],
        source: String
    ) {
        self.id = UUID()
        self.drugA = drugA
        self.drugB = drugB
        self.safe = safe
        self.interactions = interactions
        self.checkedAt = Date()
        self.source = source
    }
}
