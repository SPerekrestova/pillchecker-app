import XCTest
@testable import PillChecker

@MainActor
final class HistoryViewModelTests: XCTestCase {

    func testSortOptionCount() {
        XCTAssertEqual(SortOption.allCases.count, 3)
    }

    func testFilteredByQuery() {
        let vm = HistoryViewModel()
        vm.searchQuery = "ibu"

        let checks = [
            makeRecord(drugA: "Ibuprofen", drugB: "Warfarin"),
            makeRecord(drugA: "Aspirin", drugB: "Lisinopril"),
        ]

        let filtered = vm.filtered(checks)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].drugA, "Ibuprofen")
    }

    func testEmptyQueryReturnsAll() {
        let vm = HistoryViewModel()

        let checks = [
            makeRecord(drugA: "Ibuprofen", drugB: "Warfarin"),
            makeRecord(drugA: "Aspirin", drugB: "Lisinopril"),
        ]

        let filtered = vm.filtered(checks)
        XCTAssertEqual(filtered.count, 2)
    }

    func testSortByDrugA() {
        let vm = HistoryViewModel()
        vm.sortOption = .drugA

        let checks = [
            makeRecord(drugA: "Warfarin", drugB: "X"),
            makeRecord(drugA: "Aspirin", drugB: "Y"),
        ]

        let sorted = vm.filtered(checks)
        XCTAssertEqual(sorted[0].drugA, "Aspirin")
    }

    private func makeRecord(drugA: String, drugB: String) -> CheckRecord {
        CheckRecord(drugA: drugA, drugB: drugB, safe: true, interactions: [], source: "manual")
    }
}
