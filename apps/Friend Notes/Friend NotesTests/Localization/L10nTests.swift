import XCTest
@testable import Friend_Notes

final class L10nTests: XCTestCase {
    func testMissingKeyReturnsProvidedFallback() {
        let key = "missing.key.\(UUID().uuidString)"

        let value = L10n.text(key, "Fallback Value")

        XCTAssertEqual(value, "Fallback Value")
    }

    func testFormattedMissingKeyUsesFallbackFormatString() {
        let key = "missing.format.key.\(UUID().uuidString)"

        let value = L10n.text(key, "Count: %d", 3)

        XCTAssertEqual(value, "Count: 3")
    }

    func testKnownKeyDoesNotUseFallbackValue() {
        let value = L10n.text("common.cancel", "__fallback__")

        XCTAssertNotEqual(value, "__fallback__")
        XCTAssertFalse(value.isEmpty)
    }

    func testFormattedKnownKeyInterpolatesArguments() {
        let value = L10n.text("friend.delete.title", "Delete %@?", "Alex")

        XCTAssertTrue(value.contains("Alex"))
    }
}
