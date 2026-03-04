import Foundation

enum Route: Hashable {
    case drugInput
    case scan(slot: Int)
    case search(slot: Int)
    case results(drugA: String, drugB: String)
    case checkDetail(id: UUID)
}
