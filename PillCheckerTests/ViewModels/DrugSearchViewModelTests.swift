import XCTest
@testable import PillChecker

@MainActor
final class DrugSearchViewModelTests: XCTestCase {

    func testInitialState() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = RxNormClient(session: session)

        let vm = DrugSearchViewModel(rxNormClient: client)
        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.suggestions.isEmpty)
        XCTAssertFalse(vm.isSearching)
    }
}
