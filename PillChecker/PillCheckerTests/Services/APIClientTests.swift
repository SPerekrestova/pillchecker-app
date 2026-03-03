import XCTest
@testable import PillChecker

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            XCTFail("No request handler set")
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class APIClientTests: XCTestCase {

    private var client: APIClient!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        client = APIClient(baseURL: "https://test.api", session: session)
    }

    func testAnalyzeSuccess() async throws {
        let responseJSON = """
        {
            "drugs": [{"rxcui": "5640", "name": "Ibuprofen", "dosage": null, "form": null, "source": "ner", "confidence": 0.9}],
            "raw_text": "test text"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/analyze")
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result = try await client.analyze(text: "BRUFEN Ibuprofen")
        XCTAssertEqual(result.drugs.count, 1)
        XCTAssertEqual(result.drugs[0].name, "Ibuprofen")
    }

    func testCheckInteractionsSuccess() async throws {
        let responseJSON = """
        {
            "interactions": [
                {"drug_a": "Ibuprofen", "drug_b": "Warfarin", "severity": "MAJOR", "description": "Risk", "management": "Avoid"}
            ],
            "safe": false
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/interactions")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result = try await client.checkInteractions(drugs: ["Ibuprofen", "Warfarin"])
        XCTAssertFalse(result.safe)
        XCTAssertEqual(result.interactions.count, 1)
    }

    func testServerErrorThrowsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await client.analyze(text: "test")
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    func testValidationErrorThrowsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await client.analyze(text: "test")
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .validationError = error {
                // expected
            } else {
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }
}
