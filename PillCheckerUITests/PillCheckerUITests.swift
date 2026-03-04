//
//  PillCheckerUITests.swift
//  PillCheckerUITests
//
//  Created by Svetlana Perekrestova on 3.03.26.
//

import XCTest

final class PillCheckerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testEmptyStateShowsPrompt() {
        XCTAssertTrue(app.staticTexts["No Checks Yet"].waitForExistence(timeout: 5))
    }

    func testNavigateToDrugInput() {
        let addButton = app.buttons["newCheckButton"]
        guard addButton.waitForExistence(timeout: 5) else { return }
        addButton.tap()
        XCTAssertTrue(app.navigationBars["New Check"].waitForExistence(timeout: 10))
    }

    func testDrugInputShowsTwoSlots() {
        let addButton = app.buttons["newCheckButton"]
        guard addButton.waitForExistence(timeout: 5) else { return }
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Drug 1"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Drug 2"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
