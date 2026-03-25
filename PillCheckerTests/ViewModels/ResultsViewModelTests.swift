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
        XCTAssertEqual(vm.result!.safe, false)
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

    func testIsLoadingFalseAfterSuccess() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        MockURLProtocol.requestHandler = { request in
            let json = """
            {"interactions": [], "safe": true}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "A", drugB: "B")

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
        XCTAssertNotNil(vm.result)
        XCTAssertEqual(vm.result!.safe, true)
    }

    func testPreviousResultClearedOnNewCheck() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        // First call succeeds
        MockURLProtocol.requestHandler = { request in
            let json = """
            {"interactions": [], "safe": true}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "A", drugB: "B")
        XCTAssertNotNil(vm.result)

        // Second call fails
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await vm.checkInteractions(drugA: "C", drugB: "D")
        XCTAssertNil(vm.result, "Previous result should be cleared on new check")
        XCTAssertNotNil(vm.error)
    }

    func testAPIErrorShowsSpecificDescription() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "A", drugB: "B")

        XCTAssertEqual(vm.error, "Connection timed out. Check your network.")
    }

    func testNonAPIErrorShowsGenericMessage() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "A", drugB: "B")

        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    func testRetryAfterErrorSucceeds() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        // First call fails
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = ResultsViewModel(apiClient: client)
        await vm.checkInteractions(drugA: "A", drugB: "B")
        XCTAssertNotNil(vm.error)
        XCTAssertNil(vm.result)

        // Retry succeeds
        MockURLProtocol.requestHandler = { request in
            let json = """
            {"interactions": [], "safe": true}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        await vm.checkInteractions(drugA: "A", drugB: "B")
        XCTAssertNil(vm.error, "Error should be cleared after successful retry")
        XCTAssertNotNil(vm.result)
        XCTAssertEqual(vm.result!.safe, true)
    }
}
