import Foundation
import UserNotifications
import SwiftData

/// Schedules and manages all app-owned local notifications.
///
/// `NotificationService` is the single authority for creating, replacing, and clearing local
/// reminders derived from app data (`Friend`, `Meeting`, `FollowUpTask`) and global settings.
///
/// - Important: The service only touches requests whose identifiers start with `friendsapp.`.
/// - Important: Notification IDs include stable model identifiers so rescheduling stays idempotent.
final class NotificationService {
    /// Shared singleton instance used across the app lifecycle.
    static let shared = NotificationService()

    // MARK: - Dependencies and Constants

    /// System notification center used for authorization, scheduling, and cleanup.
    private let center = UNUserNotificationCenter.current()
    /// Identifier namespace used to scope this service's notification ownership.
    private let prefix = "friendsapp."
    /// Maximum lag (seconds) tolerated for same-minute catch-up scheduling.
    private let reminderCatchUpGraceSeconds: TimeInterval = 120
    /// Delay added to immediate catch-up reminders to avoid firing at the exact scheduling tick.
    private let immediateCatchUpDelaySeconds: TimeInterval = 6

    /// Enforces singleton usage.
    private init() {}

    // MARK: - Public API

    /// Requests notification authorization if needed.
    ///
    /// - Returns: `true` when authorization is granted, otherwise `false`.
    ///
    /// - Note: Errors are intentionally swallowed and mapped to `false` to keep scheduling call sites simple.
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

    /// Removes all pending and delivered notifications owned by this app.
    ///
    /// - Important: Only notifications with the internal `friendsapp.` prefix are removed.
    func clearManagedNotifications() async {
        let ids = await managedNotificationIDs()
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// Rebuilds the entire reminder set from current models and global settings.
    ///
    /// - Parameters:
    ///   - friends: Current friend records used for birthday and "long time no meeting" reminders.
    ///   - meetings: Current timeline entries used for meeting/event reminders.
    ///   - followUpTasks: Current follow-up tasks used for due-date reminders.
    ///   - settings: Global notification preferences.
    ///
    /// - Important: Existing managed notifications are always cleared first to avoid duplicate schedules.
    /// - Note: When notifications are disabled or system permission is missing, scheduling exits safely.
    func rescheduleAll(
        friends: [Friend],
        meetings: [Meeting],
        followUpTasks: [FollowUpTask],
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
                   reminderTimeMinutes: settings.globalReminderTimeMinutes,
                   referenceDate: now
               ) {
                let content = UNMutableNotificationContent()
                content.title = L10n.text("notification.birthday.title", "Geburtstag: %@", friend.displayName)
                content.body = L10n.text("notification.birthday.body", "%@ hat bald Geburtstag.", friend.displayName)
                content.sound = .default
                content.userInfo = friendRouteUserInfo(friend)

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "\(prefix)birthday.\(friend.persistentModelID)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                _ = await add(request)
            }

            if settings.globalNotifyLongNoMeeting {
                let lastMeetingEnd = friend.meetings
                    .map(\.endDate)
                    .filter { $0 <= now }
                    .max() ?? friend.createdAt
                let weeks = max(1, settings.globalLongNoMeetingWeeks)
                if let fireDate = longNoMeetingReminderDate(
                    lastMeetingEnd: lastMeetingEnd,
                    reminderWeeks: weeks,
                    reminderTimeMinutes: settings.globalReminderTimeMinutes,
                    referenceDate: now,
                    calendar: calendar
                ) {
                    let content = UNMutableNotificationContent()
                    content.title = L10n.text("notification.long_no_meeting.title", "Long Time No See")
                    content.body = weeks == 1
                        ? L10n.text(
                            "notification.long_no_meeting.body.one",
                            "Du hast %@ seit 1 Woche nicht gesehen.",
                            friend.displayName
                        )
                        : L10n.text(
                            "notification.long_no_meeting.body.other",
                            "Du hast %@ seit %d Wochen nicht gesehen.",
                            friend.displayName,
                            weeks
                        )
                    content.sound = .default
                    content.userInfo = friendRouteUserInfo(friend)

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
                      let preferredFireDate = reminderDate(
                        on: baseDate,
                        reminderTimeMinutes: settings.globalReminderTimeMinutes,
                        calendar: calendar
                      ),
                      let fireDate = resolvedFireDate(
                        preferredDate: preferredFireDate,
                        anchorDate: baseDate,
                        referenceDate: now,
                        calendar: calendar
                      ) else { continue }

                let content = UNMutableNotificationContent()
                content.title = meeting.kind == .meeting
                    ? L10n.text("notification.meeting.title", "Meeting Reminder")
                    : L10n.text("notification.event.title", "Event Reminder")
                let startText = meeting.startDate.formatted(date: .abbreviated, time: .shortened)
                let participantNames = localizedNameList(meeting.friends.map(\.displayName))
                if meeting.kind == .meeting {
                    if participantNames.isEmpty {
                        content.body = L10n.text(
                            "notification.meeting.body.no_friends",
                            "You have a meeting on %@.",
                            startText
                        )
                    } else {
                        content.body = L10n.text(
                            "notification.meeting.body.with_friends",
                            "You have a meeting with %@ on %@.",
                            participantNames,
                            startText
                        )
                    }
                } else {
                    let subject = meeting.displayTitle
                    if participantNames.isEmpty {
                        content.body = L10n.text(
                            "notification.event.body.no_friends",
                            "Your event \"%@\" starts on %@.",
                            subject,
                            startText
                        )
                    } else {
                        content.body = L10n.text(
                            "notification.event.body.with_friends",
                            "Your event \"%@\" with %@ starts on %@.",
                            subject,
                            participantNames,
                            startText
                        )
                    }
                }
                content.sound = .default
                content.userInfo = meetingRouteUserInfo(meeting)

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "\(prefix)event.\(meeting.persistentModelID)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                _ = await add(request)
            }

            if meeting.kind == .meeting, settings.globalNotifyPostMeetingNote {
                if let preferredFireDate = reminderDate(
                    on: meeting.endDate,
                    reminderTimeMinutes: settings.globalReminderTimeMinutes,
                    calendar: calendar
                ),
                   let fireDate = resolvedFireDate(
                    preferredDate: preferredFireDate,
                    anchorDate: meeting.endDate,
                    referenceDate: now,
                    calendar: calendar
                   ) {
                    let content = UNMutableNotificationContent()
                    content.title = L10n.text("notification.post_note.title", "Meeting Note Reminder")
                    let participantNames = localizedNameList(meeting.friends.map(\.displayName))
                    content.body = participantNames.isEmpty
                        ? L10n.text(
                            "notification.post_note.body.no_friends",
                            "Add a note for your meeting now."
                        )
                        : L10n.text(
                            "notification.post_note.body.with_friends",
                            "Add a note for your meeting with %@ now.",
                            participantNames
                        )
                    content.sound = .default
                    content.userInfo = meetingRouteUserInfo(meeting)

                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let identifier = "\(prefix)postnote.\(meeting.persistentModelID)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    _ = await add(request)
                }
            }
        }

        if settings.globalNotifyFollowUps {
            for task in followUpTasks where !task.isCompleted {
                guard let fireDate = resolvedFireDate(
                    preferredDate: task.dueDate,
                    anchorDate: task.dueDate,
                    referenceDate: now,
                    calendar: calendar
                ) else { continue }

                let content = UNMutableNotificationContent()
                content.title = L10n.text("notification.followup.title", "To-Do Reminder")
                if let friend = task.friend {
                    content.body = L10n.text(
                        "notification.followup.body.with_friend",
                        "To-Do due for %@: %@",
                        friend.displayName,
                        task.displayTitle
                    )
                } else {
                    content.body = L10n.text(
                        "notification.followup.body.no_friend",
                        "To-Do due: %@",
                        task.displayTitle
                    )
                }
                content.sound = .default
                content.userInfo = followUpRouteUserInfo(task)

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "\(prefix)followup.\(task.persistentModelID)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                _ = await add(request)
            }
        }
    }

    // MARK: - Date Resolution

    /// Calculates the next birthday reminder date.
    ///
    /// - Parameters:
    ///   - birthday: The stored birthday date.
    ///   - reminderDays: Days before birthday when reminder should fire.
    ///   - reminderTimeMinutes: Preferred daily reminder time in minutes since midnight.
    ///   - referenceDate: Baseline timestamp used to pick the next valid occurrence.
    /// - Returns: A future reminder date in local time, or `nil` when no valid date can be derived.
    ///
    /// - Note: `reminderDays` is clamped to `1...7`.
    private func nextBirthdayReminderDate(
        birthday: Date,
        reminderDays: Int,
        reminderTimeMinutes: Int,
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
              let preferredReminderDate = reminderDate(
                on: baseReminderDate,
                reminderTimeMinutes: reminderTimeMinutes,
                calendar: calendar
              ) else {
            return nil
        }
        return resolvedFireDate(
            preferredDate: preferredReminderDate,
            anchorDate: baseReminderDate,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    /// Resolves the next reminder date for "long time no meeting".
    ///
    /// - Parameters:
    ///   - lastMeetingEnd: Most recent known meeting end for the friend.
    ///   - reminderWeeks: Number of inactive weeks before reminding.
    ///   - reminderTimeMinutes: Preferred daily reminder time in minutes since midnight.
    ///   - referenceDate: Baseline timestamp used to derive "overdue" state.
    ///   - calendar: Calendar used for date arithmetic and day-boundary checks.
    /// - Returns: The next valid fire date, or `nil` when date construction fails.
    ///
    /// - Note: Overdue reminders are scheduled today, with a short same-minute catch-up fallback.
    private func longNoMeetingReminderDate(
        lastMeetingEnd: Date,
        reminderWeeks: Int,
        reminderTimeMinutes: Int,
        referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        let weeks = max(1, reminderWeeks)
        guard let thresholdDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: referenceDate) else {
            return nil
        }

        // Already overdue: remind at today's configured time (or tomorrow when today's window has passed).
        if lastMeetingEnd <= thresholdDate {
            guard let todayReminder = reminderDate(
                on: referenceDate,
                reminderTimeMinutes: reminderTimeMinutes,
                calendar: calendar
            ) else {
                return nil
            }

            if todayReminder > referenceDate {
                return todayReminder
            }

            let lag = referenceDate.timeIntervalSince(todayReminder)
            if lag >= 0, lag <= reminderCatchUpGraceSeconds {
                return referenceDate.addingTimeInterval(immediateCatchUpDelaySeconds)
            }

            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) else {
                return nil
            }
            return reminderDate(
                on: tomorrow,
                reminderTimeMinutes: reminderTimeMinutes,
                calendar: calendar
            )
        }

        // Not overdue yet: schedule exactly when the no-meeting threshold is reached.
        guard let baseDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: lastMeetingEnd),
              let preferredFireDate = reminderDate(
                on: baseDate,
                reminderTimeMinutes: reminderTimeMinutes,
                calendar: calendar
              ) else {
            return nil
        }

        return resolvedFireDate(
            preferredDate: preferredFireDate,
            anchorDate: baseDate,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    /// Normalizes a date to the configured reminder time in local calendar context.
    ///
    /// - Parameters:
    ///   - date: Source date.
    ///   - reminderTimeMinutes: Preferred daily reminder time in minutes since midnight.
    ///   - calendar: Calendar used for date component extraction.
    /// - Returns: A date on the same day at the configured reminder time, or `nil` if date composition fails.
    private func reminderDate(on date: Date, reminderTimeMinutes: Int, calendar: Calendar) -> Date? {
        let clampedMinutes = min(max(reminderTimeMinutes, 0), (23 * 60) + 59)
        let hour = clampedMinutes / 60
        let minute = clampedMinutes % 60
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: hour,
            minute: minute
        ))
    }

    /// Resolves a final fire date, allowing a short same-day catch-up window.
    ///
    /// - Parameters:
    ///   - preferredDate: Ideal fire date computed from reminder settings.
    ///   - anchorDate: Business date that the reminder belongs to (for same-day validation).
    ///   - referenceDate: Current timestamp used to decide whether catch-up is still valid.
    ///   - calendar: Calendar used for day-boundary checks.
    /// - Returns: A future fire date, or `nil` when the reminder should be skipped.
    ///
    /// - Note: This avoids dropping reminders when rescheduling happens moments after the target minute.
    private func resolvedFireDate(
        preferredDate: Date,
        anchorDate: Date,
        referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        if preferredDate > referenceDate {
            return preferredDate
        }
        guard calendar.isDate(anchorDate, inSameDayAs: referenceDate) else {
            return nil
        }
        let lag = referenceDate.timeIntervalSince(preferredDate)
        guard lag >= 0, lag <= reminderCatchUpGraceSeconds else {
            return nil
        }
        return referenceDate.addingTimeInterval(immediateCatchUpDelaySeconds)
    }

    // MARK: - Route Payload Metadata

    /// Creates notification route metadata for friend-targeted notifications.
    private func friendRouteUserInfo(_ friend: Friend) -> [AnyHashable: Any] {
        [
            "route_type": "friend",
            "route_id": "\(friend.persistentModelID)",
            "route_tab": "friends"
        ]
    }

    /// Creates notification route metadata for meeting/event-targeted notifications.
    private func meetingRouteUserInfo(_ meeting: Meeting) -> [AnyHashable: Any] {
        [
            "route_type": "meeting",
            "route_id": "\(meeting.persistentModelID)",
            "route_tab": "calendar"
        ]
    }

    /// Creates notification route metadata for follow-up-task-targeted notifications.
    private func followUpRouteUserInfo(_ task: FollowUpTask) -> [AnyHashable: Any] {
        [
            "route_type": "followup",
            "route_id": "\(task.persistentModelID)",
            "route_tab": "friends"
        ]
    }

    /// Returns a localized natural-language list (for example "A, B, and C").
    private func localizedNameList(_ names: [String]) -> String {
        let cleanedNames = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return ListFormatter.localizedString(byJoining: cleanedNames)
    }

    // MARK: - UNUserNotificationCenter Bridges

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
