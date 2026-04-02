import XCTest
@testable import Friend_Notes

final class GiftIdeaModelTests: XCTestCase {
    func testInitializerAppliesProvidedValues() {
        let idea = GiftIdea(title: "Book", note: "Signed edition", url: "https://example.com", isGifted: true)

        XCTAssertEqual(idea.title, "Book")
        XCTAssertEqual(idea.note, "Signed edition")
        XCTAssertEqual(idea.url, "https://example.com")
        XCTAssertTrue(idea.isGifted)
    }

    func testInitializerUsesExpectedDefaults() {
        let before = Date()
        let idea = GiftIdea()
        let after = Date()

        XCTAssertEqual(idea.title, "")
        XCTAssertEqual(idea.note, "")
        XCTAssertEqual(idea.url, "")
        XCTAssertFalse(idea.isGifted)
        XCTAssertNil(idea.friend)
        XCTAssertGreaterThanOrEqual(idea.createdAt, before)
        XCTAssertLessThanOrEqual(idea.createdAt, after)
    }
}
