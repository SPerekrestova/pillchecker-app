import Foundation

@Observable
@MainActor
final class DrugInputViewModel {
    var slots: [DrugSlot] = [DrugSlot(), DrugSlot()]

    var hasScanned: Bool {
        slots.contains { $0.isScanned }
    }

    var bothFilled: Bool {
        slots[0].isFilled && slots[1].isFilled
    }

    var hasDuplicateDrugs: Bool {
        guard let name0 = slots[0].displayName, let name1 = slots[1].displayName else {
            return false
        }
        return name0.localizedCaseInsensitiveCompare(name1) == .orderedSame
    }

    var canCheck: Bool {
        bothFilled && !hasDuplicateDrugs
    }

    var drugNames: [String] {
        slots.compactMap { $0.displayName }
    }

    func setDrug(index: Int, drug: DrugResult) {
        slots[index].drug = drug
        slots[index].manualName = nil
        slots[index].isScanned = true
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
    }
}
