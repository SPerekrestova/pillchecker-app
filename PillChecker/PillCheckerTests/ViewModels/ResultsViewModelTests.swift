import XCTest
@testable import PillChecker

@MainActor
final class ResultsViewModelTests: XCTestCase {

    func testCheckInteractionsSuccess() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        MockURLProtocol.requestHandler = { request in
            let json = """
            {
                "interactions": [
                    {"drug_a": "Ibuprofen", "drug_b": "Warfarin", "severity": "MAJOR", "description": "Risk", "management": "Avoid"}
                ],
                "safe": false
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "Ibuprofen", drugB: "Warfarin")

        XCTAssertNotNil(vm.result)
        XCTAssertFalse(vm.result!.safe)
        XCTAssertEqual(vm.result!.interactions.count, 1)
        XCTAssertFalse(vm.isLoading)
    }

    func testCheckInteractionsError() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "A", drugB: "B")

        XCTAssertNil(vm.result)
        XCTAssertNotNil(vm.error)
    }
}
