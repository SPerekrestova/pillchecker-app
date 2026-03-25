import UIKit

@Observable
@MainActor
final class ScanViewModel {
    var capturedImage: UIImage?
    var recognizedText: String?
    var extractedDrug: DrugResult?
    var editableDrugName: String = ""
    var isProcessing = false
    var error: String?
    var note: String?
    var showCamera = false

    private let apiClient: APIClient
    private let ocrService: OCRService

    init(apiClient: APIClient, ocrService: OCRService) {
        self.apiClient = apiClient
        self.ocrService = ocrService
    }

    func processImage(_ image: UIImage) async {
        capturedImage = image
        guard let cgImage = image.cgImage else {
            error = "Could not process image."
            return
        }
        isProcessing = true
        error = nil

        do {
            let text = try await ocrService.recognizeText(from: cgImage)
            recognizedText = text

            guard let text, !text.isEmpty else {
                error = "No text found in image. Try again or type manually."
                isProcessing = false
                return
            }

            await analyzeText(String(text.prefix(5000)))
        } catch {
            self.error = "Failed to read text from image."
            isProcessing = false
        }
    }

    func analyzeText(_ text: String) async {
        isProcessing = true
        error = nil

        do {
            let response = try await apiClient.analyze(text: text)
            recognizedText = response.rawText
            note = response.note

            if let drug = response.drugs.first {
                extractedDrug = drug
                editableDrugName = drug.name
            } else {
                error = "No drugs found in text. Try editing the name."
            }
        } catch {
            self.error = (error as? APIError)?.errorDescription ?? "Analysis failed."
        }

        isProcessing = false
    }

    func retake() {
        capturedImage = nil
        recognizedText = nil
        extractedDrug = nil
        editableDrugName = ""
        error = nil
        note = nil
    }
}
