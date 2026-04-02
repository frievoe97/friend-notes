import XCTest
@testable import Friend_Notes

final class FriendEntryModelTests: XCTestCase {
    func testInitializerAssignsProvidedValues() {
        let entry = FriendEntry(title: "Pizza", note: "No olives", category: "foods", order: 3)

        XCTAssertEqual(entry.title, "Pizza")
        XCTAssertEqual(entry.note, "No olives")
        XCTAssertEqual(entry.category, "foods")
        XCTAssertEqual(entry.order, 3)
    }

    func testInitializerCreatesTimestampCloseToNow() {
        let before = Date()
        let entry = FriendEntry(title: "Jogging", category: "hobbies")
        let after = Date()

        XCTAssertGreaterThanOrEqual(entry.createdAt, before)
        XCTAssertLessThanOrEqual(entry.createdAt, after)
    }

    func testInitializerLeavesFriendRelationshipNilByDefault() {
        let entry = FriendEntry(title: "Jazz", category: "musics")

        XCTAssertNil(entry.friend)
    }
}
