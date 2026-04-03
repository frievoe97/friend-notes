import SwiftUI
import SwiftData

// MARK: - App Settings

/// Hosts all global app preferences shared across features.
///
/// This screen edits persisted settings (`@AppStorage`) and triggers side effects where needed,
/// for example requesting notification authorization and removing deleted tags from all friends.
struct AppSettingsView: View {
    // MARK: - Persisted Data Sources

    /// All friends in storage, used to cascade tag removals to every profile.
    @Query private var allFriends: [Friend]

    /// Master switch for app-managed local notifications.
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    /// Controls whether birthdays are rendered in the calendar feature.
    @AppStorage("showBirthdaysOnCalendar") private var showBirthdaysOnCalendar = true
    /// JSON-encoded global tag registry managed by ``AppTagStore``.
    @AppStorage(AppTagStore.key) private var definedTagsRaw = "[]"

    /// Enables birthday reminders.
    @AppStorage("globalNotifyBirthday") private var globalNotifyBirthday = true
    /// Days in advance for birthday reminders.
    @AppStorage("globalBirthdayReminderDays") private var globalBirthdayReminderDays = 3
    /// Enables meeting reminders.
    @AppStorage("globalNotifyMeetings") private var globalNotifyMeetings = true
    /// Days in advance for meeting reminders.
    @AppStorage("globalMeetingReminderDays") private var globalMeetingReminderDays = 1
    /// Enables event reminders.
    @AppStorage("globalNotifyEvents") private var globalNotifyEvents = true
    /// Days in advance for event reminders.
    @AppStorage("globalEventReminderDays") private var globalEventReminderDays = 1
    /// Enables inactivity reminders when no meetings happened recently.
    @AppStorage("globalNotifyLongNoMeeting") private var globalNotifyLongNoMeeting = true
    /// Number of inactivity weeks before scheduling a reminder.
    @AppStorage("globalLongNoMeetingWeeks") private var globalLongNoMeetingWeeks = 4
    /// Preferred daily reminder time in minutes since midnight.
    @AppStorage("globalReminderTimeMinutes") private var globalReminderTimeMinutes = 9 * 60
    /// Enables a reminder after meetings to add notes.
    @AppStorage("globalNotifyPostMeetingNote") private var globalNotifyPostMeetingNote = true
    /// Enables reminders for due follow-up tasks.
    @AppStorage("globalNotifyFollowUps") private var globalNotifyFollowUps = true

    // MARK: - View State

    /// Draft value for a new reusable tag.
    @State private var newTag = ""
    /// Expands/collapses the full tag list.
    @State private var showAllTags = false
    /// Inline status shown when notification permission is unavailable.
    @State private var notificationStatusMessage = ""
    /// Tracks which text input should currently be focused.
    @FocusState private var focusedField: FocusField?

    // MARK: - Layout Constants

    /// Maximum number of tags shown before collapsing behind a "show all" action.
    private let tagPreviewLimit = 14
    /// Scroll target used to keep the add-tag row visible when keyboard appears.
    private let addTagInputScrollID = "settings-add-tag-input"
    /// Vertical spacing between controls within a section.
    private let settingsControlSpacing: CGFloat = 20
    /// List row insets used for settings cards.
    private let settingsSectionInset: CGFloat = 12
    /// Internal vertical padding for settings card content.
    private let settingsSectionPadding: CGFloat = 12
    /// Vertical padding for each notification row.
    private let notificationRowPadding: CGFloat = 12
    /// Top spacing before nested notification sub-controls.
    private let notificationSubrowTopSpacing: CGFloat = 10
    /// Leading offset used for nested notification sub-controls.
    private let notificationSubrowLeadingInset: CGFloat = 2

    /// Focus targets in the settings form.
    private enum FocusField {
        case newTag
    }

    /// Decoded globally configured friend tags from app storage.
    private var definedTags: [String] {
        AppTagStore.decode(definedTagsRaw)
    }

    /// Returns globally defined tags in alphabetical order.
    private var sortedTags: [String] {
        definedTags.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Tags currently shown in the chip flow (collapsed or expanded).
    private var visibleTags: [String] {
        showAllTags ? sortedTags : Array(sortedTags.prefix(tagPreviewLimit))
    }

    /// Two-way mapping between persisted minutes and the time picker `Date`.
    ///
    /// - Note: Values are clamped to `00:00...23:59` to keep storage resilient against stale or invalid data.
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                let now = Date()
                let clamped = min(max(globalReminderTimeMinutes, 0), (23 * 60) + 59)
                let hour = clamped / 60
                let minute = clamped % 60
                return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                let hour = components.hour ?? 9
                let minute = components.minute ?? 0
                globalReminderTimeMinutes = min(max((hour * 60) + minute, 0), (23 * 60) + 59)
            }
        )
    }

    /// Root settings screen composed of notifications, calendar, and tag management sections.
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    globalNotificationsSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: settingsSectionInset, leading: 18, bottom: settingsSectionInset, trailing: 18))
                    calendarSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: settingsSectionInset, leading: 18, bottom: settingsSectionInset, trailing: 18))
                    tagsSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: settingsSectionInset, leading: 18, bottom: settingsSectionInset, trailing: 18))
                        .listRowSeparator(.hidden, edges: .bottom)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .compositingGroup()
                .background(AppGradientBackground())
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: focusedField == .newTag ? 112 : 0)
                }
                .onChange(of: focusedField) { _, newValue in
                    guard newValue == .newTag else { return }
                    // Wait one run-loop tick so keyboard/layout updates settle before scrolling.
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(addTagInputScrollID, anchor: .bottom)
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("settings.title", "Settings"))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L10n.text("common.done", "Done")) {
                        focusedField = nil
                        Keyboard.dismiss()
                    }
                }
            }
            .onAppear(perform: normalizeReminderRanges)
            .onChange(of: notificationsEnabled) { _, newValue in
                guard newValue else {
                    notificationStatusMessage = ""
                    return
                }

                // Keep persisted state aligned with system permission state.
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
            VStack(alignment: .leading, spacing: 0) {
                Toggle(L10n.text("settings.notifications.enable", "Enable Notifications"), isOn: $notificationsEnabled)
                    .padding(.vertical, notificationRowPadding + 2)
                if notificationsEnabled {
                    Divider()

                    HStack(alignment: .center) {
                        Text(L10n.text("settings.reminder.time", "Reminder time"))
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer(minLength: 16)

                        FiveMinuteTimePicker(
                            selection: reminderTimeBinding,
                            preferredStyle: .compact
                        )
                    }
                    .frame(minHeight: 44, alignment: .center)
                    .padding(.vertical, 6)

                    Divider()

                    reminderRow(
                        title: L10n.text("settings.reminder.birthdays", "Birthdays"),
                        isOn: $globalNotifyBirthday,
                        days: $globalBirthdayReminderDays
                    )
                    .padding(.vertical, notificationRowPadding)

                    Divider()

                    reminderRow(
                        title: L10n.text("settings.reminder.meetings", "Meetings"),
                        isOn: $globalNotifyMeetings,
                        days: $globalMeetingReminderDays
                    )
                    .padding(.vertical, notificationRowPadding)

                    Divider()

                    reminderRow(
                        title: L10n.text("settings.reminder.events", "Events"),
                        isOn: $globalNotifyEvents,
                        days: $globalEventReminderDays
                    )
                    .padding(.vertical, notificationRowPadding)

                    Divider()

                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(L10n.text("settings.reminder.followups", "To-Dos"), isOn: $globalNotifyFollowUps)
                            .padding(.vertical, 2)

                        if globalNotifyFollowUps {
                            Text(L10n.text("settings.reminder.followups.hint", "Reminders are sent at the task due date and time."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, notificationSubrowTopSpacing)
                                .padding(.leading, notificationSubrowLeadingInset)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, notificationRowPadding)

                    Divider()

                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(L10n.text("settings.reminder.long_no_meeting", "Long Time No Meeting Reminder"), isOn: $globalNotifyLongNoMeeting)
                            .padding(.vertical, 2)

                        if globalNotifyLongNoMeeting {
                            HStack(alignment: .firstTextBaseline) {
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
                            .padding(.top, notificationSubrowTopSpacing)
                            .padding(.leading, notificationSubrowLeadingInset)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, notificationRowPadding)

                    Divider()

                    Toggle(L10n.text("settings.reminder.post_note", "Reminder to Add Note After Meeting"), isOn: $globalNotifyPostMeetingNote)
                        .padding(.vertical, notificationRowPadding)

                    if !notificationStatusMessage.isEmpty {
                        Divider()
                        Text(notificationStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, notificationRowPadding)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, settingsSectionPadding)
        } header: {
            Text(L10n.text("settings.notifications.global.header", "Notifications"))
        }
    }

    /// Section for calendar-specific display preferences.
    private var calendarSection: some View {
        Section {
            VStack(alignment: .leading, spacing: settingsControlSpacing) {
                Toggle(L10n.text("settings.calendar.show_birthdays", "Show Birthdays"), isOn: $showBirthdaysOnCalendar)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, settingsSectionPadding)
        } header: {
            Text(L10n.text("calendar.title", "Calendar"))
        }
    }

    /// Section for managing globally reusable friend tags.
    private var tagsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: settingsControlSpacing) {
                addTagInput

                if definedTags.isEmpty {
                    Text(L10n.text("settings.tags.empty", "No tags defined yet."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(visibleTags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                    removeTag(tag)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }

                    if sortedTags.count > tagPreviewLimit {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAllTags.toggle()
                            }
                        } label: {
                            Text(
                                showAllTags
                                    ? L10n.text("settings.tags.show_less", "Show fewer tags")
                                    : L10n.text("settings.tags.show_all", "Show all tags (%d)", sortedTags.count)
                            )
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, settingsSectionPadding)
        } header: {
            Text(L10n.text("settings.tags.header", "Friend Tags"))
        }
    }

    /// Input row for adding new globally reusable tags.
    ///
    /// - Note: The entire card is tappable to make focusing easy on smaller devices.
    private var addTagInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField("", text: $newTag)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .newTag)
                    .submitLabel(.done)
                    .onSubmit(addTag)

                let canAdd = !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(canAdd ? AppTheme.accent : AppTheme.accent.opacity(0.35))
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .accessibilityLabel(L10n.text("common.add", "Add"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .appGlassCard(cornerRadius: 14)
        .id(addTagInputScrollID)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = .newTag
        }
    }

    /// Adds the current draft tag to the global registry when valid.
    ///
    /// - Note: Duplicate checks are case-insensitive and preserve existing tag casing.
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

    /// Removes a tag globally and cascades the removal to all friend profiles.
    ///
    /// - Parameter tag: Tag value to remove.
    /// - Important: This mutates persisted friend models currently loaded in `allFriends`.
    private func removeTag(_ tag: String) {
        var tags = definedTags
        tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
        definedTagsRaw = AppTagStore.encode(tags)
        for friend in allFriends {
            friend.tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
        }
    }

    /// Builds one reminder row with an enable toggle and optional lead-time picker.
    ///
    /// - Parameters:
    ///   - title: Reminder category title.
    ///   - isOn: Enable/disable binding for the category.
    ///   - days: Lead-time setting in days.
    /// - Returns: A styled reminder configuration row.
    private func reminderRow(title: String, isOn: Binding<Bool>, days: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(L10n.text("settings.reminder.row", "%@ Reminder", title), isOn: isOn)
                .padding(.vertical, 2)

            if isOn.wrappedValue {
                HStack(alignment: .firstTextBaseline) {
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
                .padding(.top, notificationSubrowTopSpacing)
                .padding(.leading, notificationSubrowLeadingInset)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// Normalizes persisted reminder values to supported UI ranges.
    ///
    /// - Important: Call this before rendering controls that depend on closed ranges (`1...7` days).
    private func normalizeReminderRanges() {
        globalBirthdayReminderDays = min(max(globalBirthdayReminderDays, 1), 7)
        globalMeetingReminderDays = min(max(globalMeetingReminderDays, 1), 7)
        globalEventReminderDays = min(max(globalEventReminderDays, 1), 7)
        globalLongNoMeetingWeeks = max(globalLongNoMeetingWeeks, 1)
        globalReminderTimeMinutes = min(max(globalReminderTimeMinutes, 0), (23 * 60) + 59)
    }
}


#Preview {
    AppSettingsView()
}
