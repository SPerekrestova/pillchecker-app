import XCTest
@testable import PillChecker

@MainActor
final class DrugInputViewModelTests: XCTestCase {

    func testInitialSlotsAreEmpty() {
        let vm = DrugInputViewModel()
        XCTAssertFalse(vm.slots[0].isFilled)
        XCTAssertFalse(vm.slots[1].isFilled)
        XCTAssertFalse(vm.bothFilled)
    }

    func testBothFilledWhenBothSlotsHaveDrugs() {
        let vm = DrugInputViewModel()
        vm.slots[0].manualName = "Aspirin"
        vm.slots[1].manualName = "Ibuprofen"
        XCTAssertTrue(vm.bothFilled)
    }

    func testDrugNamesReturnsFilledSlotNames() {
        let vm = DrugInputViewModel()
        vm.slots[0].manualName = "Aspirin"
        vm.slots[1].manualName = "Ibuprofen"
        XCTAssertEqual(vm.drugNames, ["Aspirin", "Ibuprofen"])
    }

    func testResetClearsBothSlots() {
        let vm = DrugInputViewModel()
        vm.slots[0].manualName = "Aspirin"
        vm.slots[1].manualName = "Ibuprofen"
        vm.reset()
        XCTAssertFalse(vm.slots[0].isFilled)
        XCTAssertFalse(vm.slots[1].isFilled)
    }

    func testHasScannedTracksOCRUsage() {
        let vm = DrugInputViewModel()
        XCTAssertFalse(vm.hasScanned)
        vm.setDrug(index: 0, drug: DrugResult(
            rxcui: nil, name: "Ibuprofen",
            dosage: nil, form: nil, source: "ner", confidence: 0.9
        ))
        XCTAssertTrue(vm.hasScanned)
    }

    func testSetDrugFillsSlotAndMarksScanned() {
        let vm = DrugInputViewModel()
        let drug = DrugResult(rxcui: "5640", name: "Ibuprofen", dosage: "400mg", form: "tablet", source: "ner", confidence: 0.95)

        vm.setDrug(index: 0, drug: drug)

        XCTAssertEqual(vm.slots[0].drug?.name, "Ibuprofen")
        XCTAssertNil(vm.slots[0].manualName)
        XCTAssertTrue(vm.slots[0].isScanned)
        XCTAssertTrue(vm.slots[0].isFilled)
    }

    func testSetManualNameFillsSlotAndClearsDrug() {
        let vm = DrugInputViewModel()
        let drug = DrugResult(rxcui: "5640", name: "Ibuprofen", dosage: nil, form: nil, source: "ner", confidence: 0.9)
        vm.setDrug(index: 0, drug: drug)

        vm.setManualName(index: 0, name: "Aspirin")

        XCTAssertNil(vm.slots[0].drug)
        XCTAssertEqual(vm.slots[0].manualName, "Aspirin")
        XCTAssertFalse(vm.slots[0].isScanned)
        XCTAssertTrue(vm.slots[0].isFilled)
    }

    func testClearSlotResetsSlot() {
        let vm = DrugInputViewModel()
        vm.setManualName(index: 1, name: "Warfarin")
        XCTAssertTrue(vm.slots[1].isFilled)

        vm.clearSlot(index: 1)

        XCTAssertFalse(vm.slots[1].isFilled)
        XCTAssertNil(vm.slots[1].drug)
        XCTAssertNil(vm.slots[1].manualName)
        XCTAssertFalse(vm.slots[1].isScanned)
    }

    func testDuplicateDrugDetected() {
        let vm = DrugInputViewModel()
        vm.setManualName(index: 0, name: "Aspirin")
        vm.setManualName(index: 1, name: "aspirin")
        XCTAssertTrue(vm.hasDuplicateDrugs)
        XCTAssertFalse(vm.canCheck)
    }

    func testDifferentDrugsAllowCheck() {
        let vm = DrugInputViewModel()
        vm.setManualName(index: 0, name: "Aspirin")
        vm.setManualName(index: 1, name: "Ibuprofen")
        XCTAssertFalse(vm.hasDuplicateDrugs)
        XCTAssertTrue(vm.canCheck)
    }

    func testCanCheckRequiresBothFilledAndNoDuplicates() {
        let vm = DrugInputViewModel()
        vm.setManualName(index: 0, name: "Aspirin")
        XCTAssertFalse(vm.canCheck, "One slot filled should not allow check")
    }

    func testBothFilledRequiresBothSlots() {
        let vm = DrugInputViewModel()
        vm.setManualName(index: 0, name: "Aspirin")
        XCTAssertFalse(vm.bothFilled, "One slot filled should not satisfy bothFilled")

        vm.setManualName(index: 1, name: "Warfarin")
        XCTAssertTrue(vm.bothFilled)
    }

    func testSetManualNameAfterScanUsesEditedName() {
        let vm = DrugInputViewModel()
        let drug = DrugResult(
            rxcui: "5640", name: "Ibuprofen",
            dosage: nil, form: nil, source: "ner", confidence: 0.9
        )
        vm.setDrug(index: 0, drug: drug)
        XCTAssertEqual(vm.slots[0].displayName, "Ibuprofen")

        // User edits the name — view should call setManualName
        vm.setManualName(index: 0, name: "Paracetamol")
        XCTAssertEqual(vm.slots[0].displayName, "Paracetamol")
        XCTAssertNil(vm.slots[0].drug)
        XCTAssertFalse(vm.slots[0].isScanned)
    }
}
