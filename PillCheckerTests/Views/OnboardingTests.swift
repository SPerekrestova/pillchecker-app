import XCTest
@testable import PillChecker

final class OnboardingTests: XCTestCase {

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    }

    func testOnboardingNotSeenByDefault() {
        let seen = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        XCTAssertFalse(seen)
    }

    func testMarkOnboardingSeenPersists() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
    }
}
