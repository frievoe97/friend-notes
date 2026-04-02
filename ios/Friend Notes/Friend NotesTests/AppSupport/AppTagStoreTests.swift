import XCTest
@testable import Friend_Notes

final class AppTagStoreTests: XCTestCase {
    func testEncodeDecodeRoundTripPreservesOrderAndContent() {
        let tags = ["Best Friend", "Work", "Travel"]

        let encoded = AppTagStore.encode(tags)
        let decoded = AppTagStore.decode(encoded)

        XCTAssertEqual(decoded, tags)
    }

    func testDecodeReturnsEmptyArrayForInvalidJSON() {
        let decoded = AppTagStore.decode("this-is-not-json")

        XCTAssertEqual(decoded, [])
    }

    func testDecodeReturnsEmptyArrayForNonArrayJSON() {
        let decoded = AppTagStore.decode("{\"tags\": [\"A\"]}")

        XCTAssertEqual(decoded, [])
    }

    func testEncodeEmptyArrayProducesStableJSON() {
        let encoded = AppTagStore.encode([])

        XCTAssertEqual(encoded, "[]")
    }
}
