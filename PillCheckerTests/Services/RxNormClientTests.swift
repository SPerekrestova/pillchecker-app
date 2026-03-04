import XCTest
@testable import PillChecker

final class RxNormClientTests: XCTestCase {

    private var client: RxNormClient!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        client = RxNormClient(session: session)
    }

    func testShortQueryReturnsEmpty() async {
        let results = await client.suggest(query: "a")
        XCTAssertTrue(results.isEmpty)
    }

    func testEmptyQueryReturnsEmpty() async {
        let results = await client.suggest(query: "")
        XCTAssertTrue(results.isEmpty)
    }

    func testSuggestReturnsDrugNames() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let url = request.url!.absoluteString

            if url.contains("approximateTerm") {
                let json = """
                {
                    "approximateGroup": {
                        "candidate": [
                            {"rxcui": "5640", "score": "100"},
                            {"rxcui": "1191", "score": "90"}
                        ]
                    }
                }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            } else if url.contains("5640/properties") {
                let json = """
                {"properties": {"name": "Ibuprofen"}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            } else if url.contains("1191/properties") {
                let json = """
                {"properties": {"name": "Aspirin"}}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json)
            }

            XCTFail("Unexpected URL: \(url)")
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let results = await client.suggest(query: "ibu")
        XCTAssertTrue(results.contains("Ibuprofen"))
        XCTAssertTrue(results.contains("Aspirin"))
    }

    func testNetworkErrorReturnsEmpty() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let results = await client.suggest(query: "test")
        XCTAssertTrue(results.isEmpty)
    }
}
