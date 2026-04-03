import XCTest
@testable import Friend_Notes

final class AppNotificationSettingsTests: XCTestCase {
    func testInitializerStoresAllValues() {
        let settings = AppNotificationSettings(
            notificationsEnabled: true,
            globalNotifyBirthday: false,
            globalBirthdayReminderDays: 2,
            globalNotifyMeetings: true,
            globalMeetingReminderDays: 3,
            globalNotifyEvents: false,
            globalEventReminderDays: 4,
            globalNotifyLongNoMeeting: true,
            globalLongNoMeetingWeeks: 5,
            globalReminderTimeMinutes: 10 * 60,
            globalNotifyPostMeetingNote: false,
            globalNotifyFollowUps: true
        )

        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertFalse(settings.globalNotifyBirthday)
        XCTAssertEqual(settings.globalBirthdayReminderDays, 2)
        XCTAssertTrue(settings.globalNotifyMeetings)
        XCTAssertEqual(settings.globalMeetingReminderDays, 3)
        XCTAssertFalse(settings.globalNotifyEvents)
        XCTAssertEqual(settings.globalEventReminderDays, 4)
        XCTAssertTrue(settings.globalNotifyLongNoMeeting)
        XCTAssertEqual(settings.globalLongNoMeetingWeeks, 5)
        XCTAssertEqual(settings.globalReminderTimeMinutes, 10 * 60)
        XCTAssertFalse(settings.globalNotifyPostMeetingNote)
        XCTAssertTrue(settings.globalNotifyFollowUps)
    }

    func testStructUsesValueSemantics() {
        let original = AppNotificationSettings(
            notificationsEnabled: true,
            globalNotifyBirthday: true,
            globalBirthdayReminderDays: 3,
            globalNotifyMeetings: true,
            globalMeetingReminderDays: 1,
            globalNotifyEvents: true,
            globalEventReminderDays: 1,
            globalNotifyLongNoMeeting: true,
            globalLongNoMeetingWeeks: 4,
            globalReminderTimeMinutes: 9 * 60,
            globalNotifyPostMeetingNote: true,
            globalNotifyFollowUps: true
        )

        var copy = original
        copy.notificationsEnabled = false
        copy.globalReminderTimeMinutes = 8 * 60
        copy.globalNotifyFollowUps = false

        XCTAssertTrue(original.notificationsEnabled)
        XCTAssertEqual(original.globalReminderTimeMinutes, 9 * 60)
        XCTAssertTrue(original.globalNotifyFollowUps)
        XCTAssertFalse(copy.notificationsEnabled)
        XCTAssertEqual(copy.globalReminderTimeMinutes, 8 * 60)
        XCTAssertFalse(copy.globalNotifyFollowUps)
    }
}
