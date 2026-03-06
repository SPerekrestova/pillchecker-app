import XCTest
@testable import PillChecker

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
        } catch {
            XCTFail("Unexpected error type: \(error)")
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
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testTimeoutThrowsAPIError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await client.analyze(text: "test")
            XCTFail("Expected timeout error")
        } catch let error as APIError {
            if case .timeout = error {
                // expected
            } else {
                XCTFail("Expected timeout, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNetworkErrorThrowsAPIError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await client.analyze(text: "test")
            XCTFail("Expected network error")
        } catch let error as APIError {
            if case .networkError = error {
                // expected
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDecodingErrorThrowsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            let badJSON = "not json".data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, badJSON)
        }

        do {
            _ = try await client.analyze(text: "test")
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            if case .decodingError = error {
                // expected
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testErrorDescriptions() {
        XCTAssertEqual(APIError.timeout.errorDescription, "Connection timed out. Check your network.")
        XCTAssertEqual(APIError.validationError.errorDescription, "Invalid request. Please try again.")
        XCTAssertEqual(APIError.serverError(statusCode: 503).errorDescription, "Server error (503). Please try again.")
        XCTAssertNotNil(APIError.networkError(underlying: URLError(.notConnectedToInternet)).errorDescription)
        XCTAssertNotNil(APIError.decodingError(underlying: URLError(.cannotDecodeContentData)).errorDescription)
    }
}
