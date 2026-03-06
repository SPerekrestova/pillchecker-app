import XCTest
import SwiftUI
@testable import PillChecker

@MainActor
final class AppNavigatorTests: XCTestCase {

    func testInitialPathIsEmpty() {
        let nav = AppNavigator()
        XCTAssertTrue(nav.path.isEmpty)
    }

    func testNavigateAppendsToPath() {
        let nav = AppNavigator()
        nav.navigate(to: .drugInput)
        XCTAssertEqual(nav.path.count, 1)
    }

    func testMultipleNavigationsStack() {
        let nav = AppNavigator()
        nav.navigate(to: .drugInput)
        nav.navigate(to: .scan(slot: 0))
        XCTAssertEqual(nav.path.count, 2)
    }

    func testPopRemovesLast() {
        let nav = AppNavigator()
        nav.navigate(to: .drugInput)
        nav.navigate(to: .scan(slot: 0))
        nav.pop()
        XCTAssertEqual(nav.path.count, 1)
    }

    func testPopOnEmptyPathDoesNothing() {
        let nav = AppNavigator()
        nav.pop()
        XCTAssertTrue(nav.path.isEmpty)
    }

    func testPopToRootClearsPath() {
        let nav = AppNavigator()
        nav.navigate(to: .drugInput)
        nav.navigate(to: .scan(slot: 0))
        nav.navigate(to: .results(drugA: "A", drugB: "B"))
        nav.popToRoot()
        XCTAssertTrue(nav.path.isEmpty)
    }
}
