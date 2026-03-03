import Foundation
import SwiftData

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case drugA = "Drug A"
    case drugB = "Drug B"

    var id: String { rawValue }
}

@Observable
final class HistoryViewModel {
    var searchQuery = ""
    var sortOption: SortOption = .newest

    func filtered(_ checks: [CheckRecord]) -> [CheckRecord] {
        var result = checks

        if !searchQuery.isEmpty {
            result = result.filter {
                $0.drugA.localizedCaseInsensitiveContains(searchQuery) ||
                $0.drugB.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        switch sortOption {
        case .newest:
            result.sort { $0.checkedAt > $1.checkedAt }
        case .drugA:
            result.sort { $0.drugA.localizedCompare($1.drugA) == .orderedAscending }
        case .drugB:
            result.sort { $0.drugB.localizedCompare($1.drugB) == .orderedAscending }
        }

        return result
    }
}
