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

    func testSortByNewest() {
        let vm = HistoryViewModel()
        vm.sortOption = .newest

        let older = makeRecord(drugA: "Aspirin", drugB: "X")
        // Ensure different timestamps
        let newer = CheckRecord(drugA: "Warfarin", drugB: "Y", safe: true, interactions: [], source: "manual")

        let sorted = vm.filtered([older, newer])
        // Newer record should come first (default sort is newest)
        XCTAssertEqual(sorted[0].drugA, "Warfarin")
    }

    func testSortByDrugB() {
        let vm = HistoryViewModel()
        vm.sortOption = .drugB

        let checks = [
            makeRecord(drugA: "X", drugB: "Warfarin"),
            makeRecord(drugA: "Y", drugB: "Aspirin"),
        ]

        let sorted = vm.filtered(checks)
        XCTAssertEqual(sorted[0].drugB, "Aspirin")
        XCTAssertEqual(sorted[1].drugB, "Warfarin")
    }

    func testFilterAndSortCombined() {
        let vm = HistoryViewModel()
        vm.searchQuery = "aspirin"
        vm.sortOption = .drugA

        let checks = [
            makeRecord(drugA: "Warfarin", drugB: "Aspirin"),
            makeRecord(drugA: "Aspirin", drugB: "Ibuprofen"),
            makeRecord(drugA: "Lisinopril", drugB: "Metformin"),
        ]

        let result = vm.filtered(checks)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].drugA, "Aspirin")
        XCTAssertEqual(result[1].drugA, "Warfarin")
    }

    func testFilterMatchesDrugB() {
        let vm = HistoryViewModel()
        vm.searchQuery = "warfarin"

        let checks = [
            makeRecord(drugA: "Aspirin", drugB: "Warfarin"),
            makeRecord(drugA: "Lisinopril", drugB: "Metformin"),
        ]

        let result = vm.filtered(checks)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].drugB, "Warfarin")
    }

    private func makeRecord(drugA: String, drugB: String) -> CheckRecord {
        CheckRecord(drugA: drugA, drugB: drugB, safe: true, interactions: [], source: "manual")
    }
}
