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
}
