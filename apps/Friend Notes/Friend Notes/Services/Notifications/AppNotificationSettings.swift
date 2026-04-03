import Foundation

/// Global notification preferences used when scheduling local reminders.
struct AppNotificationSettings {
    /// Master switch for all app-managed notifications.
    var notificationsEnabled: Bool
    /// Enables birthday reminders.
    var globalNotifyBirthday: Bool
    /// Number of days before birthday reminders.
    var globalBirthdayReminderDays: Int
    /// Enables meeting reminders.
    var globalNotifyMeetings: Bool
    /// Number of days before meeting reminders.
    var globalMeetingReminderDays: Int
    /// Enables event reminders.
    var globalNotifyEvents: Bool
    /// Number of days before event reminders.
    var globalEventReminderDays: Int
    /// Enables "long time no meeting" reminders.
    var globalNotifyLongNoMeeting: Bool
    /// Number of weeks before triggering "long time no meeting".
    var globalLongNoMeetingWeeks: Int
    /// Time of day (minutes since midnight) when reminders should fire.
    var globalReminderTimeMinutes: Int
    /// Enables reminder to add a note after a meeting ends.
    var globalNotifyPostMeetingNote: Bool
    /// Enables reminders for pending follow-up tasks at their due date and time.
    var globalNotifyFollowUps: Bool
}
