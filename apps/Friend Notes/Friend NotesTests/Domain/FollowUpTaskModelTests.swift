import XCTest
@testable import Friend_Notes

final class FollowUpTaskModelTests: XCTestCase {
    func testInitializerAppliesProvidedValues() {
        let dueDate = Date(timeIntervalSince1970: 1_700_000_000)
        let task = FollowUpTask(
            title: "Send recap",
            note: "Include action items",
            dueDate: dueDate,
            isCompleted: true
        )

        XCTAssertEqual(task.title, "Send recap")
        XCTAssertEqual(task.note, "Include action items")
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    func testInitializerUsesExpectedDefaults() {
        let before = Date()
        let task = FollowUpTask()
        let after = Date()

        XCTAssertEqual(task.title, "")
        XCTAssertEqual(task.note, "")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertNil(task.friend)
        XCTAssertGreaterThanOrEqual(task.createdAt, before)
        XCTAssertLessThanOrEqual(task.createdAt, after)
    }

    func testDisplayTitleFallsBackWhenTitleIsWhitespace() {
        let task = FollowUpTask(title: "   ", note: "", dueDate: Date())

        XCTAssertEqual(task.displayTitle, L10n.text("followup.untitled", "Untitled Follow-up Task"))
    }
}
