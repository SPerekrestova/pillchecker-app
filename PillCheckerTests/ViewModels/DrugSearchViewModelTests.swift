import XCTest
@testable import PillChecker

@MainActor
final class DrugSearchViewModelTests: XCTestCase {

    private var session: URLSession!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
    }

    func testInitialState() {
        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)
        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.suggestions.isEmpty)
        XCTAssertFalse(vm.isSearching)
    }

    func testShortQueryClearsSuggestions() {
        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        vm.suggestions = ["Previous"]
        vm.query = "a"
        vm.search()

        XCTAssertTrue(vm.suggestions.isEmpty, "Short query should clear suggestions")
    }

    func testWhitespaceOnlyQueryClearsSuggestions() {
        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        vm.suggestions = ["Previous"]
        vm.query = "   "
        vm.search()

        XCTAssertTrue(vm.suggestions.isEmpty)
    }

    func testSearchReturnsSuggestions() async throws {
        MockURLProtocol.requestHandler = { request in
            let url = request.url!.absoluteString
            if url.contains("approximateTerm") {
                let json = """
                {"approximateGroup": {"candidate": [{"rxcui": "5640", "score": "100"}]}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            } else {
                let json = """
                {"properties": {"name": "Ibuprofen"}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            }
        }

        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        vm.query = "ibuprofen"
        vm.search()

        // Wait for debounce (300ms) + network
        try await Task.sleep(for: .milliseconds(600))

        XCTAssertFalse(vm.suggestions.isEmpty, "Should have suggestions after search")
        XCTAssertTrue(vm.suggestions.contains("Ibuprofen"))
        XCTAssertFalse(vm.isSearching)
    }

    func testSearchSetsErrorOnNetworkFailure() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        vm.query = "ibuprofen"
        vm.search()

        // Wait for debounce (300ms) + network
        try await Task.sleep(for: .milliseconds(600))

        XCTAssertNotNil(vm.searchError, "searchError should be set on network failure")
        XCTAssertTrue(vm.suggestions.isEmpty, "suggestions should be empty on error")
        XCTAssertFalse(vm.isSearching)
    }

    func testSearchClearsErrorOnSuccess() async throws {
        // First set up a failure to populate searchError
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        vm.query = "ibuprofen"
        vm.search()
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertNotNil(vm.searchError)

        // Now set up success
        MockURLProtocol.requestHandler = { request in
            let url = request.url!.absoluteString
            if url.contains("approximateTerm") {
                let json = """
                {"approximateGroup": {"candidate": [{"rxcui": "5640", "score": "100"}]}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            } else {
                let json = """
                {"properties": {"name": "Ibuprofen"}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            }
        }

        vm.query = "ibuprofen"
        vm.search()
        try await Task.sleep(for: .milliseconds(600))

        XCTAssertNil(vm.searchError, "searchError should be cleared on success")
        XCTAssertFalse(vm.suggestions.isEmpty)
    }

    func testShortQueryClearsError() {
        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        vm.searchError = "Some error"
        vm.query = "a"
        vm.search()

        XCTAssertNil(vm.searchError, "Short query should clear searchError")
    }

    func testSearchCancelsPreviousTask() async throws {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let url = request.url!.absoluteString
            if url.contains("approximateTerm") {
                let json = """
                {"approximateGroup": {"candidate": [{"rxcui": "5640", "score": "100"}]}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            } else {
                let json = """
                {"properties": {"name": "Aspirin"}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            }
        }

        let client = RxNormClient(session: session)
        let vm = DrugSearchViewModel(rxNormClient: client)

        // Fire first search then immediately override
        vm.query = "ibu"
        vm.search()
        vm.query = "aspirin"
        vm.search()

        // Wait for debounce + network
        try await Task.sleep(for: .milliseconds(600))

        // Only the last search should produce results
        XCTAssertFalse(vm.isSearching)
    }
}
