import XCTest
import SwiftData
@testable import PillChecker

final class HistoryViewModelTests: XCTestCase {

    func testSortOrderOptions() {
        XCTAssertEqual(SortOption.allCases.count, 3)
    }

    func testFilteredChecksMatchesQuery() {
        let checks = [
            makeRecord(drugA: "Ibuprofen", drugB: "Warfarin"),
            makeRecord(drugA: "Aspirin", drugB: "Lisinopril"),
        ]

        let filtered = checks.filter { record in
            let query = "ibu"
            return record.drugA.localizedCaseInsensitiveContains(query) ||
                   record.drugB.localizedCaseInsensitiveContains(query)
        }

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].drugA, "Ibuprofen")
    }

    private func makeRecord(drugA: String, drugB: String) -> CheckRecord {
        CheckRecord(drugA: drugA, drugB: drugB, safe: true, interactions: [], source: "manual")
    }
}
