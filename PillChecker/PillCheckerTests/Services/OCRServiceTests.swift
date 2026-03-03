import XCTest
import UIKit
@testable import PillChecker

final class OCRServiceTests: XCTestCase {

    private let service = OCRService()

    func testRecognizeTextFromImage() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 100))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 100))

            let text = "Ibuprofen 400mg"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36),
                .foregroundColor: UIColor.black,
            ]
            text.draw(at: CGPoint(x: 20, y: 30), withAttributes: attrs)
        }

        let result = try await service.recognizeText(from: image)
        XCTAssertNotNil(result)
        let lowered = result?.lowercased() ?? ""
        XCTAssertTrue(lowered.contains("ibuprofen") || lowered.contains("400"),
                       "Expected OCR to recognize text, got: \(result ?? "nil")")
    }

    func testRecognizeTextFromBlankImageReturnsNil() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }

        let result = try await service.recognizeText(from: image)
        XCTAssertTrue(result == nil || result?.isEmpty == true)
    }
}
