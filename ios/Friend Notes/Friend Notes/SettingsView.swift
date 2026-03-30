import SwiftUI
import SwiftData

// MARK: - App Settings

/// Hosts global app preferences such as notifications, calendar options, and shared tags.
struct AppSettingsView: View {
    @Query private var allFriends: [Friend]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("showBirthdaysOnCalendar") private var showBirthdaysOnCalendar = true
    @AppStorage(AppTagStore.key) private var definedTagsRaw = "[]"

    @AppStorage("globalNotifyBirthday") private var globalNotifyBirthday = true
    @AppStorage("globalBirthdayReminderDays") private var globalBirthdayReminderDays = 3
    @AppStorage("globalNotifyMeetings") private var globalNotifyMeetings = true
    @AppStorage("globalMeetingReminderDays") private var globalMeetingReminderDays = 1
    @AppStorage("globalNotifyEvents") private var globalNotifyEvents = true
    @AppStorage("globalEventReminderDays") private var globalEventReminderDays = 2
    @AppStorage("globalNotifyLongNoMeeting") private var globalNotifyLongNoMeeting = false
    @AppStorage("globalLongNoMeetingWeeks") private var globalLongNoMeetingWeeks = 4
    @AppStorage("globalNotifyPostMeetingNote") private var globalNotifyPostMeetingNote = true

    @State private var newTag = ""
    @State private var notificationStatusMessage = ""

    /// Decoded globally configured friend tags from app storage.
    private var definedTags: [String] {
        AppTagStore.decode(definedTagsRaw)
    }

    var body: some View {
        NavigationStack {
            List {
                globalNotificationsSection
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                calendarSection
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                tagsSection
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .compositingGroup()
            .background(AppGradientBackground())
            .navigationTitle(L10n.text("settings.title", "Settings"))
            .onAppear(perform: normalizeReminderRanges)
            .onChange(of: notificationsEnabled) { _, newValue in
                guard newValue else {
                    notificationStatusMessage = ""
                    return
                }
                Task {
                    let granted = await NotificationService.shared.requestAuthorizationIfNeeded()
                    await MainActor.run {
                        if !granted {
                            notificationsEnabled = false
                            notificationStatusMessage = L10n.text("settings.notifications.denied", "Notifications denied. Enable them in iOS Settings.")
                        } else {
                            notificationStatusMessage = ""
                        }
                    }
                }
            }
        }
    }

    /// Section for global reminder categories and lead-time configuration.
    private var globalNotificationsSection: some View {
        Section {
            Toggle(L10n.text("settings.notifications.enable", "Enable Notifications"), isOn: $notificationsEnabled)
            if notificationsEnabled {
                reminderRow(
                    title: L10n.text("settings.reminder.birthdays", "Birthdays"),
                    isOn: $globalNotifyBirthday,
                    days: $globalBirthdayReminderDays
                )

                reminderRow(
                    title: L10n.text("settings.reminder.meetings", "Meetings"),
                    isOn: $globalNotifyMeetings,
                    days: $globalMeetingReminderDays
                )

                reminderRow(
                    title: L10n.text("settings.reminder.events", "Events"),
                    isOn: $globalNotifyEvents,
                    days: $globalEventReminderDays
                )

                Toggle(L10n.text("settings.reminder.long_no_meeting", "Long Time No Meeting Reminder"), isOn: $globalNotifyLongNoMeeting)
                if globalNotifyLongNoMeeting {
                    HStack {
                        Text(L10n.text("settings.after", "After"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker(L10n.text("settings.weeks", "Weeks"), selection: $globalLongNoMeetingWeeks) {
                            ForEach(1...26, id: \.self) { value in
                                Text(weeksLabel(value)).tag(value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .font(.subheadline)
                }
                Toggle(L10n.text("settings.reminder.post_note", "Reminder to Add Note After Meeting"), isOn: $globalNotifyPostMeetingNote)

                if !notificationStatusMessage.isEmpty {
                    Text(notificationStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(L10n.text("settings.notifications.global.header", "Global Notifications"))
        }
    }

    /// Section for calendar-specific display preferences.
    private var calendarSection: some View {
        Section {
            Toggle(L10n.text("settings.calendar.show_birthdays", "Show Birthdays"), isOn: $showBirthdaysOnCalendar)
        } header: {
            Text(L10n.text("calendar.title", "Calendar"))
        }
    }

    /// Section for managing globally reusable friend tags.
    private var tagsSection: some View {
        Section {
            if definedTags.isEmpty {
                Text(L10n.text("settings.tags.empty", "No tags defined yet."))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(definedTags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        Button(role: .destructive) {
                            removeTag(tag)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(AppTheme.danger)
                        }
                    }
                }
            }

            HStack {
                TextField(L10n.text("settings.tags.add_placeholder", "Add tag"), text: $newTag)
                    .submitLabel(.done)
                    .onSubmit(addTag)
                if !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(L10n.text("common.add", "Add"), action: addTag)
                }
            }
        } header: {
            Text(L10n.text("settings.tags.header", "Friend Tags"))
        }
    }

    /// Adds a tag to the global registry if it is non-empty and unique.
    ///
    /// - Note: Duplicate checks are case-insensitive.
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var tags = definedTags
        guard !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            newTag = ""
            return
        }
        tags.append(trimmed)
        tags.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        definedTagsRaw = AppTagStore.encode(tags)
        newTag = ""
    }

    /// Removes a tag globally and from all friend profiles.
    ///
    /// - Parameter tag: Tag value to remove.
    private func removeTag(_ tag: String) {
        var tags = definedTags
        tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
        definedTagsRaw = AppTagStore.encode(tags)
        for friend in allFriends {
            friend.tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
        }
    }

    /// Builds one reminder row with enable toggle and optional lead-time picker.
    ///
    /// - Parameters:
    ///   - title: Reminder category title.
    ///   - isOn: Enable/disable binding for the category.
    ///   - days: Lead-time setting in days.
    /// - Returns: A styled reminder configuration row.
    private func reminderRow(title: String, isOn: Binding<Bool>, days: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(L10n.text("settings.reminder.row", "%@ Reminder", title), isOn: isOn)
            if isOn.wrappedValue {
                HStack {
                    Text(L10n.text("settings.when", "When"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker(L10n.text("settings.reminder.days", "Reminder Days"), selection: days) {
                        ForEach(1...7, id: \.self) { value in
                            Text(reminderDaysLabel(value)).tag(value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 2)
    }

    /// Produces a localized label for day-offset picker values.
    ///
    /// - Parameter value: Number of days before target date.
    /// - Returns: Human-readable day offset text.
    private func reminderDaysLabel(_ value: Int) -> String {
        value == 1
            ? L10n.text("settings.reminder.day_before.one", "1 day before")
            : L10n.text("settings.reminder.day_before.other", "%d days before", value)
    }

    /// Produces a localized label for week picker values.
    ///
    /// - Parameter value: Number of weeks.
    /// - Returns: Human-readable week count text.
    private func weeksLabel(_ value: Int) -> String {
        value == 1
            ? L10n.text("settings.weeks.value.one", "1 week")
            : L10n.text("settings.weeks.value.other", "%d weeks", value)
    }

    /// Clamps persisted reminder values into supported picker ranges.
    private func normalizeReminderRanges() {
        globalBirthdayReminderDays = min(max(globalBirthdayReminderDays, 1), 7)
        globalMeetingReminderDays = min(max(globalMeetingReminderDays, 1), 7)
        globalEventReminderDays = min(max(globalEventReminderDays, 1), 7)
        globalLongNoMeetingWeeks = max(globalLongNoMeetingWeeks, 1)
    }
}

// MARK: - Friend Settings

/// Minimal per-friend settings screen for display-related toggles.
struct FriendSettingsView: View {
    @Bindable var friend: Friend

    var body: some View {
        List {
            displaySection
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .compositingGroup()
        .background(AppGradientBackground())
        .navigationTitle(L10n.text("friend.settings.title", "Friend Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Section containing presentation preferences for a friend.
    private var displaySection: some View {
        Section {
            Toggle(L10n.text("friend.settings.pin", "Pin to Top"), isOn: $friend.isFavorite)
        } header: {
            Text(L10n.text("friend.settings.display", "Display"))
        }
    }
}

#Preview {
    AppSettingsView()
}
