import Foundation
import Observation

@Observable
final class DrugSlot {
    var drug: DrugResult?
    var manualName: String?
    var isScanned: Bool = false

    var displayName: String? {
        let name = drug?.name ?? manualName
        let trimmed = name?.trimmingCharacters(in: .whitespaces)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    var isFilled: Bool {
        displayName != nil
    }

    func clear() {
        drug = nil
        manualName = nil
        isScanned = false
    }
}
