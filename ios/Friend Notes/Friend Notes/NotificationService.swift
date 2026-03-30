import Foundation
import UserNotifications
import SwiftData

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
    /// Enables reminder to add a note after a meeting ends.
    var globalNotifyPostMeetingNote: Bool
}

/// Schedules and manages app-owned local notifications for friends and timeline entries.
final class NotificationService {
    /// Shared singleton instance used across the app lifecycle.
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let prefix = "friendsapp."

    private init() {}

    /// Requests notification authorization if needed.
    ///
    /// - Returns: `true` when authorization is granted, otherwise `false`.
    ///
    /// - Note: Errors are handled internally and mapped to `false`.
    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        } catch {
            return false
        }
    }

    /// Removes all pending and delivered notifications created by this app module.
    ///
    /// - Important: Only notifications with the internal `friendsapp.` identifier prefix are removed.
    func clearManagedNotifications() async {
        let ids = await managedNotificationIDs()
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// Clears and reschedules all app-managed notifications from current models and settings.
    ///
    /// - Parameters:
    ///   - friends: Current friend records used for birthday and "long time no meeting" reminders.
    ///   - meetings: Current timeline entries used for meeting/event reminders.
    ///   - settings: Global notification preferences.
    ///
    /// - Note: When permissions are missing or disabled in settings, scheduling exits safely without throwing.
    func rescheduleAll(
        friends: [Friend],
        meetings: [Meeting],
        settings: AppNotificationSettings
    ) async {
        await clearManagedNotifications()
        guard settings.notificationsEnabled else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let now = Date()
        let calendar = Calendar.current

        for friend in friends {
            if settings.globalNotifyBirthday,
               let birthday = friend.birthday,
               let fireDate = nextBirthdayReminderDate(
                   birthday: birthday,
                   reminderDays: settings.globalBirthdayReminderDays,
                   referenceDate: now
               ) {
                let content = UNMutableNotificationContent()
                content.title = L10n.text("notification.birthday.title", "Geburtstag: %@", friend.displayName)
                content.body = L10n.text("notification.birthday.body", "%@ hat bald Geburtstag.", friend.displayName)
                content.sound = .default

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "\(prefix)birthday.\(friend.persistentModelID)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                _ = await add(request)
            }

            if settings.globalNotifyLongNoMeeting {
                let lastMeetingEnd = friend.meetings.map(\.endDate).max() ?? friend.createdAt
                let weeks = max(1, settings.globalLongNoMeetingWeeks)
                if let baseDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: lastMeetingEnd),
                   let fireDate = atTwoPM(on: baseDate, calendar: calendar),
                   fireDate > now {
                    let content = UNMutableNotificationContent()
                    content.title = L10n.text("notification.long_no_meeting.title", "Long Time No See")
                    content.body = weeks == 1
                        ? L10n.text(
                            "notification.long_no_meeting.body.one",
                            "You haven't met %@ for 1 week.",
                            friend.displayName
                        )
                        : L10n.text(
                            "notification.long_no_meeting.body.other",
                            "You haven't met %@ for %d weeks.",
                            friend.displayName,
                            weeks
                        )
                    content.sound = .default

                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let identifier = "\(prefix)longnomeeting.\(friend.persistentModelID)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    _ = await add(request)
                }
            }
        }

        for meeting in meetings {
            guard meeting.startDate > now else { continue }

            let shouldNotify: Bool
            let reminderDays: Int
            if meeting.kind == .meeting {
                shouldNotify = settings.globalNotifyMeetings
                reminderDays = settings.globalMeetingReminderDays
            } else {
                shouldNotify = settings.globalNotifyEvents
                reminderDays = settings.globalEventReminderDays
            }

            if shouldNotify {
                let days = min(max(1, reminderDays), 7)
                guard let baseDate = calendar.date(byAdding: .day, value: -days, to: meeting.startDate),
                      let fireDate = atTwoPM(on: baseDate, calendar: calendar),
                      fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = meeting.kind == .meeting
                    ? L10n.text("notification.meeting.title", "Treffen Erinnerung")
                    : L10n.text("notification.event.title", "Ereignis Erinnerung")
                let startText = meeting.startDate.formatted(date: .abbreviated, time: .shortened)
                let subject = meeting.displayTitle
                if meeting.friends.isEmpty {
                    content.body = L10n.text(
                        "notification.event.body.no_friends",
                        "%@ startet am %@.",
                        subject,
                        startText
                    )
                } else {
                    content.body = L10n.text(
                        "notification.event.body.with_friends",
                        "%@ mit %@ startet am %@.",
                        subject,
                        meeting.friends.map(\.displayName).joined(separator: ", "),
                        startText
                    )
                }
                content.sound = .default

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "\(prefix)event.\(meeting.persistentModelID)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                _ = await add(request)
            }

            if meeting.kind == .meeting, settings.globalNotifyPostMeetingNote {
                if let fireDate = atTwoPM(on: meeting.endDate, calendar: calendar),
                   fireDate > now {
                    let content = UNMutableNotificationContent()
                    content.title = L10n.text("notification.post_note.title", "Notiz zum Treffen")
                    content.body = L10n.text("notification.post_note.body", "Füge eine Notiz zum Treffen hinzu.")
                    content.sound = .default

                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let identifier = "\(prefix)postnote.\(meeting.persistentModelID)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    _ = await add(request)
                }
            }
        }
    }

    /// Calculates the next birthday reminder date.
    ///
    /// - Parameters:
    ///   - birthday: The stored birthday date.
    ///   - reminderDays: Days before birthday when reminder should fire.
    ///   - referenceDate: Baseline timestamp used to pick the next valid occurrence.
    /// - Returns: A future reminder date in local time, or `nil` when no valid date can be derived.
    ///
    /// - Note: The time component is normalized to the configured daily reminder time.
    private func nextBirthdayReminderDate(
        birthday: Date,
        reminderDays: Int,
        referenceDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        let currentYear = calendar.component(.year, from: referenceDate)

        var nextBirthday = calendar.date(from: DateComponents(
            year: currentYear,
            month: month,
            day: day,
            hour: 9,
            minute: 0
        ))

        if let candidate = nextBirthday, candidate < referenceDate {
            nextBirthday = calendar.date(from: DateComponents(
                year: currentYear + 1,
                month: month,
                day: day,
                hour: 9,
                minute: 0
            ))
        }

        guard let birthdayDate = nextBirthday else { return nil }
        let days = min(max(1, reminderDays), 7)
        guard let baseReminderDate = calendar.date(byAdding: .day, value: -days, to: birthdayDate),
              let reminderDate = atTwoPM(on: baseReminderDate, calendar: calendar) else {
            return nil
        }
        return reminderDate > referenceDate ? reminderDate : nil
    }

    /// Normalizes a date to the app's fixed reminder time in local calendar context.
    ///
    /// - Parameters:
    ///   - date: Source date.
    ///   - calendar: Calendar used for date component extraction.
    /// - Returns: A date on the same day at the configured reminder time, or `nil` if date composition fails.
    private func atTwoPM(on date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: 9,
            minute: 0
        ))
    }

    /// Adds a local notification request to `UNUserNotificationCenter`.
    ///
    /// - Parameter request: The request to enqueue.
    /// - Returns: `true` on success, `false` if the system returns an error.
    private func add(_ request: UNNotificationRequest) async -> Bool {
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                center.add(request) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }

    /// Collects identifiers of all managed notifications (pending + delivered).
    ///
    /// - Returns: Unique notification IDs owned by this service.
    private func managedNotificationIDs() async -> [String] {
        let pending = await pendingRequests().map(\.identifier)
        let delivered = await deliveredNotifications().map(\.request.identifier)
        return Array(Set((pending + delivered).filter { $0.hasPrefix(prefix) }))
    }

    /// Fetches pending notification requests.
    ///
    /// - Returns: All pending requests currently known to `UNUserNotificationCenter`.
    private func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    /// Fetches delivered notifications.
    ///
    /// - Returns: All delivered notifications currently known to `UNUserNotificationCenter`.
    private func deliveredNotifications() async -> [UNNotification] {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
    }
}
