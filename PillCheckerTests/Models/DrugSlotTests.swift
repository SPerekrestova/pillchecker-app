import XCTest
@testable import PillChecker

@MainActor
final class DrugSlotTests: XCTestCase {

    func testEmptySlotDisplayNameIsNil() {
        let slot = DrugSlot()
        XCTAssertNil(slot.displayName)
        XCTAssertFalse(slot.isFilled)
    }

    func testSlotWithDrugShowsDrugName() {
        let slot = DrugSlot()
        slot.drug = DrugResult(
            rxcui: "5640", name: "Ibuprofen",
            dosage: nil, form: nil, source: "ner", confidence: 0.9, needsConfirmation: nil
        )
        XCTAssertEqual(slot.displayName, "Ibuprofen")
        XCTAssertTrue(slot.isFilled)
    }

    func testSlotWithManualNameShowsManualName() {
        let slot = DrugSlot()
        slot.manualName = "Aspirin"
        XCTAssertEqual(slot.displayName, "Aspirin")
        XCTAssertTrue(slot.isFilled)
    }

    func testDrugNameTakesPriorityOverManualName() {
        let slot = DrugSlot()
        slot.manualName = "Aspirin"
        slot.drug = DrugResult(
            rxcui: nil, name: "Ibuprofen",
            dosage: nil, form: nil, source: "ner", confidence: 0.9, needsConfirmation: nil
        )
        XCTAssertEqual(slot.displayName, "Ibuprofen")
    }

    func testClearResetsSlot() {
        let slot = DrugSlot()
        slot.drug = DrugResult(
            rxcui: nil, name: "Ibuprofen",
            dosage: nil, form: nil, source: "ner", confidence: 0.9, needsConfirmation: nil
        )
        slot.isScanned = true
        slot.clear()
        XCTAssertNil(slot.drug)
        XCTAssertNil(slot.manualName)
        XCTAssertFalse(slot.isScanned)
        XCTAssertFalse(slot.isFilled)
    }
}
