import Foundation

@Observable
final class DrugInputViewModel {
    var slots: [DrugSlot] = [DrugSlot(), DrugSlot()]
    var hasScanned = false

    var bothFilled: Bool {
        slots[0].isFilled && slots[1].isFilled
    }

    var drugNames: [String] {
        slots.compactMap { $0.displayName }
    }

    func setDrug(index: Int, drug: DrugResult) {
        slots[index].drug = drug
        slots[index].manualName = nil
        slots[index].isScanned = true
        hasScanned = true
    }

    func setManualName(index: Int, name: String) {
        slots[index].drug = nil
        slots[index].manualName = name
        slots[index].isScanned = false
    }

    func clearSlot(index: Int) {
        slots[index].clear()
    }

    func reset() {
        slots = [DrugSlot(), DrugSlot()]
        hasScanned = false
    }
}
