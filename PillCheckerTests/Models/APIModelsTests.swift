import XCTest
@testable import PillChecker

final class APIModelsTests: XCTestCase {

    func testDrugResultDecodesFromJSON() throws {
        let json = """
        {
            "rxcui": "5640",
            "name": "Ibuprofen",
            "dosage": "400 mg",
            "form": "Tablet",
            "source": "ner",
            "confidence": 0.95
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(DrugResult.self, from: json)
        XCTAssertEqual(result.rxcui, "5640")
        XCTAssertEqual(result.name, "Ibuprofen")
        XCTAssertEqual(result.dosage, "400 mg")
        XCTAssertEqual(result.form, "Tablet")
        XCTAssertEqual(result.source, "ner")
        XCTAssertEqual(result.confidence, 0.95)
    }

    func testDrugResultDecodesNullFields() throws {
        let json = """
        {
            "rxcui": null,
            "name": "Aspirin",
            "dosage": null,
            "form": null,
            "source": "rxnorm_fallback",
            "confidence": 0.8
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(DrugResult.self, from: json)
        XCTAssertNil(result.rxcui)
        XCTAssertNil(result.dosage)
        XCTAssertNil(result.form)
    }

    func testAnalyzeResponseDecodes() throws {
        let json = """
        {
            "drugs": [
                {
                    "rxcui": "5640",
                    "name": "Ibuprofen",
                    "dosage": null,
                    "form": null,
                    "source": "ner",
                    "confidence": 0.9
                }
            ],
            "raw_text": "BRUFEN Ibuprofen 400mg"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AnalyzeResponse.self, from: json)
        XCTAssertEqual(response.drugs.count, 1)
        XCTAssertEqual(response.drugs[0].name, "Ibuprofen")
        XCTAssertEqual(response.rawText, "BRUFEN Ibuprofen 400mg")
    }

    func testInteractionResultDecodes() throws {
        let json = """
        {
            "drug_a": "Ibuprofen",
            "drug_b": "Warfarin",
            "severity": "MAJOR",
            "description": "Increases bleeding risk",
            "management": "Avoid combination"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(InteractionResult.self, from: json)
        XCTAssertEqual(result.drugA, "Ibuprofen")
        XCTAssertEqual(result.drugB, "Warfarin")
        XCTAssertEqual(result.severity, "MAJOR")
    }

    func testInteractionsResponseDecodes() throws {
        let json = """
        {
            "interactions": [
                {
                    "drug_a": "Ibuprofen",
                    "drug_b": "Warfarin",
                    "severity": "MAJOR",
                    "description": "Risk",
                    "management": "Avoid"
                }
            ],
            "safe": false
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        XCTAssertEqual(response.safe, false)
        XCTAssertEqual(response.interactions.count, 1)
    }

    func testInteractionResultIdIsOrderIndependent() {
        let ab = InteractionResult(drugA: "Aspirin", drugB: "Ibuprofen", severity: "MAJOR", description: "d", management: "m", uncertain: nil)
        let ba = InteractionResult(drugA: "Ibuprofen", drugB: "Aspirin", severity: "MAJOR", description: "d", management: "m", uncertain: nil)
        XCTAssertEqual(ab.id, ba.id, "ID should be the same regardless of drug order")
    }

    func testInteractionsResponseSafeDecodes() throws {
        let json = """
        {
            "interactions": [],
            "safe": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        XCTAssertEqual(response.safe, true)
        XCTAssertTrue(response.interactions.isEmpty)
    }

    func testDrugResultDecodesNeedsConfirmation() throws {
        let json = """
        {
            "rxcui": "5640",
            "name": "Ibuprofen",
            "dosage": null,
            "form": null,
            "source": "ner",
            "confidence": 0.72,
            "needs_confirmation": true
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(DrugResult.self, from: json)
        XCTAssertEqual(result.needsConfirmation, true)
    }

    func testDrugResultNeedsConfirmationDefaultsToNilWhenAbsent() throws {
        let json = """
        {
            "rxcui": "5640",
            "name": "Ibuprofen",
            "dosage": null,
            "form": null,
            "source": "ner",
            "confidence": 0.95
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(DrugResult.self, from: json)
        XCTAssertNil(result.needsConfirmation)
    }

    func testInteractionResultDecodesUncertain() throws {
        let json = """
        {
            "drug_a": "Ibuprofen",
            "drug_b": "Warfarin",
            "severity": "MAJOR",
            "description": "Risk",
            "management": "Avoid",
            "uncertain": true
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(InteractionResult.self, from: json)
        XCTAssertEqual(result.uncertain, true)
    }

    func testInteractionsResponseDecodesLimitations() throws {
        let json = """
        {
            "interactions": [],
            "safe": true,
            "limitations": ["Pairwise only", "Not a substitute for medical advice"]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        XCTAssertEqual(response.limitations?.count, 2)
        XCTAssertEqual(response.limitations?[0], "Pairwise only")
    }

    func testInteractionsResponseSafeNull() throws {
        let json = """
        {
            "interactions": [],
            "safe": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        XCTAssertNil(response.safe)
    }

    func testAnalyzeResponseDecodesDataSources() throws {
        let json = """
        {
            "drugs": [],
            "raw_text": "Ibuprofen 400mg",
            "data_sources": {
                "ner_model": "PharmaDetect-BioPatient-108M"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AnalyzeResponse.self, from: json)
        let ds = try XCTUnwrap(response.dataSources)
        XCTAssertEqual(ds.nerModel, "PharmaDetect-BioPatient-108M")
    }

    func testAnalyzeResponseDataSourcesDefaultsToNil() throws {
        let json = """
        {
            "drugs": [],
            "raw_text": "text"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AnalyzeResponse.self, from: json)
        XCTAssertNil(response.dataSources)
    }

    func testInteractionsResponseDecodesDataSources() throws {
        let json = """
        {
            "interactions": [],
            "safe": true,
            "data_sources": {
                "drugbank_version": "5.1.12",
                "severity_classifier": "DeBERTa-v3-base-zs"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        let ds = try XCTUnwrap(response.dataSources)
        XCTAssertEqual(ds.drugbankVersion, "5.1.12")
        XCTAssertEqual(ds.severityClassifier, "DeBERTa-v3-base-zs")
    }

    func testInteractionsResponseDataSourcesNullVersion() throws {
        let json = """
        {
            "interactions": [],
            "safe": true,
            "data_sources": {
                "drugbank_version": null,
                "severity_classifier": "DeBERTa-v3-base-zs"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        let ds = try XCTUnwrap(response.dataSources)
        XCTAssertNil(ds.drugbankVersion)
        XCTAssertEqual(ds.severityClassifier, "DeBERTa-v3-base-zs")
    }

    func testInteractionsResponseDecodesError() throws {
        let json = """
        {
            "interactions": [],
            "safe": null,
            "error": "DrugBank service unavailable"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        XCTAssertEqual(response.error, "DrugBank service unavailable")
        XCTAssertNil(response.safe)
    }

    func testInteractionsResponseErrorDefaultsToNil() throws {
        let json = """
        {
            "interactions": [],
            "safe": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(InteractionsResponse.self, from: json)
        XCTAssertNil(response.error)
    }

    func testAnalyzeResponseDecodesNote() throws {
        let json = """
        {
            "drugs": [],
            "raw_text": "阿莫西林",
            "note": "Non-Latin text detected; only Latin-script drug names are supported"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AnalyzeResponse.self, from: json)
        let note = try XCTUnwrap(response.note)
        XCTAssertTrue(note.contains("Latin"))
    }
}
