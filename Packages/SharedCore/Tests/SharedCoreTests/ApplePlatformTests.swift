import XCTest
@testable import SharedCore

final class ApplePlatformTests: XCTestCase {
    func testAllFiveOperatingSystemsAreRepresented() {
        XCTAssertEqual(ApplePlatform.allCases.count, 5)
        XCTAssertEqual(Set(ApplePlatform.allCases.map(\.rawValue)).count, 5)
    }

    func testTheDuoIsPartOfIOS() {
        XCTAssertTrue(ApplePlatform.iOS.displayName.contains("iPhone Duo"))
        XCTAssertFalse(ApplePlatform.allCases.map(\.rawValue).contains("duo"))
    }

    func testLayoutThreshold() {
        XCTAssertEqual(AdaptiveLayout.mode(forWidth: 699.99), .compact)
        XCTAssertEqual(AdaptiveLayout.mode(forWidth: 700), .expanded)
        XCTAssertEqual(AdaptiveLayout.mode(forWidth: 1024), .expanded)
    }

    func testInvalidWidthsDoNotEnableExpandedLayout() {
        XCTAssertEqual(AdaptiveLayout.mode(forWidth: -1), .compact)
        XCTAssertEqual(AdaptiveLayout.mode(forWidth: .nan), .compact)
        XCTAssertEqual(AdaptiveLayout.mode(forWidth: .infinity), .compact)
    }
}

