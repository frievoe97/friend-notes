import XCTest
@testable import Friend_Notes

final class MeetingModelTests: XCTestCase {
    func testInitUsesOneHourEndDateWhenEndDateIsNil() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)

        let meeting = Meeting(startDate: start, endDate: nil)

        XCTAssertEqual(meeting.endDate, start.addingTimeInterval(60 * 60))
    }

    func testInitClampsEndDateWhenBeforeStartDate() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let endBeforeStart = start.addingTimeInterval(-60)

        let meeting = Meeting(startDate: start, endDate: endBeforeStart)

        XCTAssertEqual(meeting.endDate, start)
    }

    func testKindRoundTripUpdatesRawValue() {
        let meeting = Meeting()

        meeting.kind = .event

        XCTAssertEqual(meeting.kindRaw, MeetingKind.event.rawValue)
        XCTAssertEqual(meeting.kind, .event)
    }

    func testKindFallsBackToMeetingForUnknownRawValue() {
        let meeting = Meeting()
        meeting.kindRaw = "unexpected"

        XCTAssertEqual(meeting.kind, .meeting)
    }

    func testDisplayTitleUsesTrimmedEventTitleForEvents() {
        let event = Meeting(eventTitle: "  Birthday Dinner  ", kind: .event)

        XCTAssertEqual(event.displayTitle, "Birthday Dinner")
    }

    func testDisplayTitleFallsBackToKindTitleWhenEventTitleIsEmpty() {
        let event = Meeting(eventTitle: "   ", kind: .event)

        XCTAssertEqual(event.displayTitle, MeetingKind.event.title)
    }

    func testDisplayTitleJoinsParticipantNamesSortedForMeetings() {
        let charlie = Friend(firstName: "Charlie", lastName: "Zimmer")
        let alex = Friend(firstName: "Alex", lastName: "Anderson")

        let meeting = Meeting(kind: .meeting, friends: [charlie, alex])

        XCTAssertEqual(meeting.displayTitle, "Alex Anderson, Charlie Zimmer")
    }

    func testDisplayTitleFallsBackToKindTitleWhenMeetingHasNoParticipants() {
        let meeting = Meeting(kind: .meeting, friends: [])

        XCTAssertEqual(meeting.displayTitle, MeetingKind.meeting.title)
    }

    func testMeetingKindMetadataValuesStayStable() {
        XCTAssertEqual(MeetingKind.meeting.id, "meeting")
        XCTAssertEqual(MeetingKind.event.id, "event")
        XCTAssertEqual(MeetingKind.meeting.icon, "person.2.fill")
        XCTAssertEqual(MeetingKind.event.icon, "flag.fill")
    }
}
