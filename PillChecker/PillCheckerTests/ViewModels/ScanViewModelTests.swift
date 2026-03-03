import XCTest
@testable import PillChecker

@MainActor
final class ScanViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = ScanViewModel(apiClient: APIClient(baseURL: "https://test"), ocrService: OCRService())
        XCTAssertNil(vm.capturedImage)
        XCTAssertNil(vm.recognizedText)
        XCTAssertNil(vm.extractedDrug)
        XCTAssertFalse(vm.isProcessing)
        XCTAssertNil(vm.error)
        XCTAssertEqual(vm.editableDrugName, "")
    }

    func testAnalyzeTextSuccess() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(baseURL: "https://test", session: session)

        MockURLProtocol.requestHandler = { request in
            let json = """
            {
                "drugs": [{"rxcui": "5640", "name": "Ibuprofen", "dosage": null, "form": null, "source": "ner", "confidence": 0.9}],
                "raw_text": "Ibuprofen 400mg"
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let vm = ScanViewModel(apiClient: client, ocrService: OCRService())
        await vm.analyzeText("Ibuprofen 400mg")

        XCTAssertEqual(vm.extractedDrug?.name, "Ibuprofen")
        XCTAssertEqual(vm.editableDrugName, "Ibuprofen")
        XCTAssertFalse(vm.isProcessing)
    }
}
