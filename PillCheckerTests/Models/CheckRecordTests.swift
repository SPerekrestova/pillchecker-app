import XCTest
import SwiftData
@testable import PillChecker

@MainActor
final class CheckRecordTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: CheckRecord.self, configurations: config)
    }

    func testCheckRecordCanBeInsertedAndFetched() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let interaction = SavedInteraction(
            drugA: "Ibuprofen",
            drugB: "Warfarin",
            severity: "MAJOR",
            description: "Bleeding risk",
            management: "Avoid"
        )

        let record = CheckRecord(
            drugA: "Ibuprofen",
            drugB: "Warfarin",
            safe: false,
            interactions: [interaction],
            source: "manual"
        )

        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<CheckRecord>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].drugA, "Ibuprofen")
        XCTAssertEqual(fetched[0].drugB, "Warfarin")
        XCTAssertFalse(fetched[0].safe)
        XCTAssertEqual(fetched[0].interactions.count, 1)
        XCTAssertEqual(fetched[0].source, "manual")
    }

    func testCheckRecordCanBeDeleted() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let record = CheckRecord(
            drugA: "Aspirin",
            drugB: "Lisinopril",
            safe: true,
            interactions: [],
            source: "scan"
        )

        context.insert(record)
        try context.save()

        context.delete(record)
        try context.save()

        let descriptor = FetchDescriptor<CheckRecord>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 0)
    }

    func testCheckRecordDefaultValues() throws {
        let record = CheckRecord(
            drugA: "DrugA",
            drugB: "DrugB",
            safe: true,
            interactions: [],
            source: "manual"
        )

        XCTAssertNotNil(record.id)
        XCTAssertNotNil(record.checkedAt)
    }
}
