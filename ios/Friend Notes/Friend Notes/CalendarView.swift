import SwiftUI
import SwiftData

/// Controls whether the calendar screen shows the month grid or the upcoming list.
private enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case calendar
    case upcoming

    /// Stable identifier for segmented control and `ForEach` usage.
    var id: String { rawValue }

    /// Localized title shown in the display mode picker.
    var title: String {
        switch self {
        case .calendar: return L10n.text("calendar.mode.calendar", "Calendar")
        case .upcoming: return L10n.text("calendar.mode.upcoming", "Upcoming")
        }
    }
}

/// Presents calendar-based and list-based timeline browsing for meetings, events, and birthdays.
struct CalendarView: View {
    @AppStorage("showBirthdaysOnCalendar") private var showBirthdaysOnCalendar = true
    @Query(sort: [SortDescriptor(\Meeting.startDate), SortDescriptor(\Meeting.endDate)]) private var meetings: [Meeting]
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var friends: [Friend]

    @State private var displayedMonth: Date = {
        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var selectedDate: Date = Date()
    @State private var showingAddMeeting = false
    @State private var showingAddEvent = false
    @State private var displayMode: CalendarDisplayMode = .calendar

    private let cal = Calendar.current
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdayHeaderHeight: CGFloat = 28
    private let monthCellHeight: CGFloat = 46
    private let monthGridSpacing: CGFloat = 2

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                Group {
                    switch displayMode {
                    case .calendar:
                        calendarBody
                    case .upcoming:
                        upcomingList
                    }
                }
            }
            .background(AppGradientBackground())
            .navigationTitle(L10n.text("calendar.title", "Calendar"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddMeeting = true
                        } label: {
                            Label(L10n.text("meeting.new.title", "New Meeting"), systemImage: "person.2.fill")
                        }

                        Button {
                            showingAddEvent = true
                        } label: {
                            Label(L10n.text("event.new.title", "New Event"), systemImage: "flag.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel(L10n.text("common.add", "Add"))
                }
            }
            .sheet(isPresented: $showingAddMeeting) {
                AddMeetingView(initialDate: selectedDate)
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(initialDate: selectedDate)
            }
            .onChange(of: displayedMonth) { _, newMonth in
                if cal.isDate(newMonth, equalTo: Date(), toGranularity: .month) {
                    selectedDate = Date()
                } else {
                    let comps = cal.dateComponents([.year, .month], from: newMonth)
                    selectedDate = cal.date(from: comps) ?? newMonth
                }
            }
        }
    }

    /// Segmented control used to switch between month calendar and upcoming list.
    private var modePicker: some View {
        Picker("", selection: $displayMode) {
            ForEach(CalendarDisplayMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    /// Full month calendar layout including month navigation and selected-day details.
    private var calendarBody: some View {
        VStack(spacing: 0) {
            monthNavigation
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            VStack(spacing: 0) {
                weekdayHeader
                monthGrid
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)

            Divider()

            ScrollView {
                dayEventsList
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scrollDisabled(selectedDayBirthdays.isEmpty && selectedDayEntries.isEmpty)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Header row with previous/next month navigation and current month label.
    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.year().month(.wide))
                .font(.title3.weight(.semibold))

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    /// Weekday initials row aligned to the current locale's first weekday.
    private var weekdayHeader: some View {
        LazyVGrid(columns: gridColumns, spacing: 0) {
            ForEach(Array(orderedWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: weekdayHeaderHeight)
            }
        }
    }

    /// Returns weekday symbols rotated to match `Calendar.firstWeekday`.
    ///
    /// - Returns: Ordered short weekday symbols for the calendar header.
    private var orderedWeekdaySymbols: [String] {
        let symbols = cal.veryShortWeekdaySymbols
        let offset = cal.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    /// Grid of days for the displayed month with visual state indicators.
    private var monthGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: monthGridSpacing) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    let dayEntries = entriesOn(date)
                    DayCell(
                        date: date,
                        isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                        isToday: cal.isDateInToday(date),
                        hasMeeting: dayEntries.contains(where: { $0.kind == .meeting }),
                        hasEvent: dayEntries.contains(where: { $0.kind == .event }),
                        hasBirthday: showBirthdaysOnCalendar && !birthdaysOn(date).isEmpty
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear.frame(height: monthCellHeight)
                }
            }
        }
    }

    /// Detail list for birthdays and entries on the currently selected day.
    private var dayEventsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide).year())
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.bottom, 14)

            if selectedDayBirthdays.isEmpty && selectedDayEntries.isEmpty {
                Text(L10n.text("calendar.day.empty", "No events"))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                ForEach(selectedDayBirthdays) { friend in
                    NavigationLink(destination: FriendDetailView(friend: friend)) {
                        BirthdayEventRow(
                            friend: friend,
                            displayYear: cal.component(.year, from: selectedDate)
                        )
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 68)
                }
                ForEach(selectedDayEntries) { entry in
                    NavigationLink(destination: MeetingDetailView(meeting: entry)) {
                        MeetingEventRow(meeting: entry)
                    }
                    .buttonStyle(.plain)
                    if entry.persistentModelID != selectedDayEntries.last?.persistentModelID {
                        Divider().padding(.leading, 68)
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }

    /// Birthday entries shown for the currently selected day.
    private var selectedDayBirthdays: [Friend] {
        showBirthdaysOnCalendar ? birthdaysOn(selectedDate) : []
    }

    /// Meeting/event entries shown for the currently selected day.
    private var selectedDayEntries: [Meeting] {
        entriesOn(selectedDate)
    }

    /// Chronological timeline grouped by calendar week (future entries only).
    private var upcomingList: some View {
        let items = timelineEvents()
        let sections = timelineWeekSections(for: items)
        return ScrollView {
            if items.isEmpty {
                Text(L10n.text("calendar.timeline.empty", "No events yet."))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
            } else {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                    ForEach(sections) { section in
                        Section {
                            VStack(spacing: 10) {
                                ForEach(section.items) { item in
                                    timelineRow(for: item)
                                }
                            }
                        } header: {
                            timelineWeekHeader(section: section, isFirst: section.id == sections.first?.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    /// Creates the pinned week header style used in timeline mode.
    ///
    /// - Parameters:
    ///   - section: Timeline section represented by the header.
    ///   - isFirst: Whether the section is the first visible section.
    /// - Returns: Styled week header with an opaque background for legibility.
    private func timelineWeekHeader(section: TimelineWeekSection, isFirst: Bool) -> some View {
        HStack {
            Text(weekHeaderTitle(for: section.weekStart))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }

    /// Builds the appropriate navigation row for one timeline item.
    ///
    /// - Parameter item: Timeline item to render.
    /// - Returns: Styled navigation link row.
    @ViewBuilder
    private func timelineRow(for item: UpcomingEventItem) -> some View {
        switch item.kind {
        case .birthday(let friend):
            NavigationLink(destination: FriendDetailView(friend: friend)) {
                UpcomingRow(
                    icon: "birthday.cake.fill",
                    iconColor: AppTheme.birthday,
                    title: birthdayListTitle(friend: friend, at: item.date),
                    subtitle: nil,
                    date: item.date
                )
            }
            .buttonStyle(.plain)
        case .entry(let meeting):
            NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                UpcomingRow(
                    icon: meeting.kind == .meeting ? "person.2.fill" : "flag.fill",
                    iconColor: meeting.kind == .meeting ? AppTheme.accent : AppTheme.event,
                    title: meeting.displayTitle,
                    subtitle: item.subtitle,
                    date: item.date
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Computes a month grid model including leading/trailing placeholders.
    ///
    /// - Returns: Optional dates where `nil` values represent empty grid cells.
    private var daysInMonth: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekdayIdx = cal.component(.weekday, from: firstDay) - 1
        let calFirstIdx = cal.firstWeekday - 1
        let offset = (firstWeekdayIdx - calFirstIdx + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in 0..<range.count {
            days.append(cal.date(byAdding: .day, value: day, to: firstDay))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    /// Returns timeline entries occurring on a given calendar day.
    ///
    /// - Parameter date: Day to inspect.
    /// - Returns: Entries sorted by start time ascending.
    private func entriesOn(_ date: Date) -> [Meeting] {
        meetings
            .filter { cal.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Returns friends whose birthday month/day matches a given date.
    ///
    /// - Parameter date: Day used for month/day comparison.
    /// - Returns: Friends with matching birthdays.
    private func birthdaysOn(_ date: Date) -> [Friend] {
        friends.filter { friend in
            guard let bday = friend.birthday else { return false }
            return cal.component(.month, from: bday) == cal.component(.month, from: date)
                && cal.component(.day, from: bday) == cal.component(.day, from: date)
        }
    }

    /// Builds a merged timeline list that includes only future birthdays and entries.
    ///
    /// - Returns: Timeline items sorted by date ascending.
    private func timelineEvents() -> [UpcomingEventItem] {
        let now = Date()
        var result: [UpcomingEventItem] = []

        if showBirthdaysOnCalendar {
            for friend in friends {
                guard let birthday = friend.birthday else { continue }
                let month = cal.component(.month, from: birthday)
                let day = cal.component(.day, from: birthday)
                let currentYear = cal.component(.year, from: now)

                let thisYearBirthday = cal.date(from: DateComponents(
                    year: currentYear, month: month, day: day, hour: 14
                ))
                guard let thisYearBirthday else { continue }

                let nextBirthday: Date
                if thisYearBirthday >= now {
                    nextBirthday = thisYearBirthday
                } else {
                    nextBirthday = cal.date(from: DateComponents(
                        year: currentYear + 1, month: month, day: day, hour: 14
                    )) ?? thisYearBirthday
                }
                result.append(.init(date: nextBirthday, kind: .birthday(friend), subtitle: nil))
            }
        }

        for meeting in meetings where meeting.startDate >= now {
            result.append(.init(
                date: meeting.startDate,
                kind: .entry(meeting),
                subtitle: meetingTimelineSubtitle(for: meeting)
            ))
        }

        return result.sorted { $0.date < $1.date }
    }

    /// Groups timeline items by the start date of their calendar week.
    ///
    /// - Parameter items: Flat timeline item list.
    /// - Returns: Week sections sorted chronologically.
    private func timelineWeekSections(for items: [UpcomingEventItem]) -> [TimelineWeekSection] {
        let grouped = Dictionary(grouping: items) { startOfWeek(for: $0.date) }
        return grouped
            .keys
            .sorted()
            .map { weekStart in
                let sectionItems = (grouped[weekStart] ?? []).sorted { $0.date < $1.date }
                return TimelineWeekSection(weekStart: weekStart, items: sectionItems)
            }
    }

    /// Computes the localized calendar-week header string.
    ///
    /// - Parameter weekStart: Start date of the week.
    /// - Returns: Header label like `KW 14 · 2026`.
    private func weekHeaderTitle(for weekStart: Date) -> String {
        let week = cal.component(.weekOfYear, from: weekStart)
        let year = cal.component(.yearForWeekOfYear, from: weekStart)
        let weekString = String(week)
        let yearString = String(year)
        return L10n.text("calendar.week.header", "Week %@ · %@", weekString, yearString)
    }

    /// Calculates the week start date for a given date.
    ///
    /// - Parameter date: Source date.
    /// - Returns: First day of the containing week.
    private func startOfWeek(for date: Date) -> Date {
        cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    }

    /// Handles display mode selection.
    ///
    /// - Parameter mode: Requested display mode.
    private func selectDisplayMode(_ mode: CalendarDisplayMode) {
        if displayMode == mode { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayMode = mode
        }
    }

    /// Creates the subtitle shown below timeline titles for meetings/events.
    ///
    /// - Parameter meeting: Meeting/event model.
    /// - Returns: Localized subtitle including people and time.
    private func meetingTimelineSubtitle(for meeting: Meeting) -> String {
        let timeLabel = meeting.kind == .meeting
            ? "\(meeting.startDate.formatted(date: .omitted, time: .shortened))-\(meeting.endDate.formatted(date: .omitted, time: .shortened))"
            : meeting.startDate.formatted(date: .omitted, time: .shortened)

        if meeting.friends.isEmpty {
            return "\(meeting.kind.title) • \(timeLabel)"
        }
        return "\(meeting.friends.map(\.displayName).joined(separator: ", ")) • \(timeLabel)"
    }

    /// Creates a birthday title in the preferred compact format (e.g. `30. Geburtstag von Mia`).
    ///
    /// - Parameters:
    ///   - friend: Birthday person.
    ///   - date: Birthday occurrence date.
    /// - Returns: Localized display title with age when available.
    private func birthdayListTitle(friend: Friend, at date: Date) -> String {
        guard let birthday = friend.birthday,
              let birthYear = cal.dateComponents([.year], from: birthday).year else {
            return L10n.text("calendar.birthday.title", "%@ Birthday", friend.displayName)
        }
        let years = cal.component(.year, from: date) - birthYear
        if years > 0 {
            return L10n.text("calendar.birthday.title.with_age", "%dth birthday of %@", years, friend.displayName)
        }
        return L10n.text("calendar.birthday.title", "%@ Birthday", friend.displayName)
    }
}

// MARK: - Models

/// Represents one row item in the upcoming timeline list.
private struct UpcomingEventItem: Identifiable {
    /// Distinguishes birthday entries from persisted meeting/event entries.
    enum ItemKind {
        case birthday(Friend)
        case entry(Meeting)
    }

    /// Stable identity used for list rendering and scroll anchoring.
    var id: String {
        switch kind {
        case .birthday(let friend):
            let stamp = Int(date.timeIntervalSinceReferenceDate)
            return "birthday-\(friend.persistentModelID)-\(stamp)"
        case .entry(let meeting):
            return "entry-\(meeting.persistentModelID)"
        }
    }
    let date: Date
    let kind: ItemKind
    let subtitle: String?
}

/// Represents one calendar-week section in timeline mode.
private struct TimelineWeekSection: Identifiable {
    let weekStart: Date
    let items: [UpcomingEventItem]

    var id: Date { weekStart }
}

// MARK: - Day Cell

/// Single calendar day cell with selection/today state and dot indicators.
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasMeeting: Bool
    let hasEvent: Bool
    let hasBirthday: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(date, format: .dateTime.day())
                .font(.callout.weight((isToday || isSelected) ? .bold : .regular))
                .foregroundStyle((isToday || isSelected) ? AppTheme.accent : .primary)
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle()
                            .fill(.clear)
                            .glassEffect(.regular, in: Circle())
                    }
                }
            HStack(spacing: 3) {
                if hasBirthday { Circle().fill(AppTheme.birthday).frame(width: 4, height: 4) }
                if hasMeeting  { Circle().fill(AppTheme.accent).frame(width: 4, height: 4) }
                if hasEvent  { Circle().fill(AppTheme.event).frame(width: 4, height: 4) }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
    }
}

// MARK: - Event Row: Birthday

/// Row used to display a birthday in the selected-day event list.
struct BirthdayEventRow: View {
    let friend: Friend
    let displayYear: Int

    /// Calculates displayed age for the selected year when birth year exists.
    ///
    /// - Returns: Age value for `displayYear`, or `nil` when birthday is unavailable.
    private var age: Int? {
        guard let bday = friend.birthday else { return nil }
        return displayYear - Calendar.current.component(.year, from: bday)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "birthday.cake.fill")
                .foregroundStyle(AppTheme.birthday)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.body.weight(.medium))
                if let age, age > 0 {
                    Text(L10n.text("calendar.birthday.turns", "Turns %d", age))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Event Row: Meeting/Event

/// Row used to display a meeting or event in daily lists.
struct MeetingEventRow: View {
    let meeting: Meeting

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: meeting.kind == .meeting ? "person.2.fill" : "flag.fill")
                .foregroundStyle(meeting.kind == .meeting ? AppTheme.accent : AppTheme.event)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(
                    meeting.kind == .meeting
                        ? "\(meeting.startDate.formatted(date: .omitted, time: .shortened)) - \(meeting.endDate.formatted(date: .omitted, time: .shortened))"
                        : meeting.startDate.formatted(date: .omitted, time: .shortened)
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !meeting.friends.isEmpty {
                    Text(meeting.friends.map(\.displayName).joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Upcoming Row

/// Reusable card row for the upcoming list mode.
private struct UpcomingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(date, format: .dateTime.day().month().year())
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .appGlassCard(cornerRadius: 12)
    }
}
