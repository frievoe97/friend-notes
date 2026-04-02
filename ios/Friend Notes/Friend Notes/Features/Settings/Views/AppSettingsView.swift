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
    @AppStorage("globalEventReminderDays") private var globalEventReminderDays = 1
    @AppStorage("globalNotifyLongNoMeeting") private var globalNotifyLongNoMeeting = true
    @AppStorage("globalLongNoMeetingWeeks") private var globalLongNoMeetingWeeks = 4
    @AppStorage("globalReminderTimeMinutes") private var globalReminderTimeMinutes = 9 * 60
    @AppStorage("globalNotifyPostMeetingNote") private var globalNotifyPostMeetingNote = true

    @State private var newTag = ""
    @State private var showAllTags = false
    @State private var notificationStatusMessage = ""
    @FocusState private var focusedField: FocusField?
    private let tagPreviewLimit = 14
    private let addTagInputScrollID = "settings-add-tag-input"

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

    /// Binding that maps persisted reminder minutes to a `Date` used by time pickers.
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

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                HStack {
                    Text(L10n.text("settings.reminder.time", "Reminder time"))
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    DatePicker(
                        L10n.text("settings.reminder.time", "Reminder time"),
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

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
            VStack(alignment: .leading, spacing: 12) {
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
        } header: {
            Text(L10n.text("settings.tags.header", "Friend Tags"))
        }
    }

    /// Input row for adding new globally reusable tags.
    private var addTagInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.text("settings.tags.add_placeholder", "Add tag"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                TextField("", text: $newTag)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .newTag)
                    .submitLabel(.done)
                    .onSubmit(addTag)

                let canAdd = !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(canAdd ? AppTheme.accent : AppTheme.accent.opacity(0.35))
                        .frame(width: 24, height: 24)
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
        globalReminderTimeMinutes = min(max(globalReminderTimeMinutes, 0), (23 * 60) + 59)
    }
}


#Preview {
    AppSettingsView()
}
