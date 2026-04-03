import SwiftUI
import SwiftData

/// Lists upcoming and past meetings/events for a single friend.
///
/// - Note: This screen derives sections from the bound model and opens create flows with friend preselection.
struct FriendMeetingsView: View {
    /// Bound friend model that provides meeting/event relationships.
    @Bindable var friend: Friend
    /// Controls expansion of the past section.
    @State private var isPastExpanded = false
    /// Controls truncation for large upcoming lists.
    @State private var showAllUpcoming = false
    /// Presents the add-meeting sheet.
    @State private var showingAddMeeting = false
    /// Presents the add-event sheet.
    @State private var showingAddEvent = false

    /// Default number of upcoming items shown before expanding.
    private let upcomingLimit = 5

    /// Start-of-day anchor used to split upcoming and past entries consistently.
    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Future or same-day entries sorted ascending by start date.
    private var upcoming: [Meeting] {
        friend.meetings
            .filter { $0.startDate >= startOfToday }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Historical entries sorted descending by start date.
    private var past: [Meeting] {
        friend.meetings
            .filter { $0.startDate < startOfToday }
            .sorted { $0.startDate > $1.startDate }
    }

    /// Upcoming entries shown after applying collapse/expand behavior.
    private var visibleUpcoming: [Meeting] {
        showAllUpcoming ? upcoming : Array(upcoming.prefix(upcomingLimit))
    }

    var body: some View {
        List {
            if !upcoming.isEmpty {
                Section(L10n.text("meeting.section.upcoming", "Upcoming")) {
                    ForEach(visibleUpcoming) { meeting in
                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                            meetingRow(meeting)
                        }
                        .listRowBackground(AppTheme.subtleFill)
                    }
                    if upcoming.count > upcomingLimit {
                        if !showAllUpcoming {
                            Button {
                                withAnimation { showAllUpcoming = true }
                            } label: {
                                Text(L10n.text("friend.history.upcoming.show_all", "Show more (%d)", upcoming.count))
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                            }
                            .listRowBackground(AppTheme.subtleFill)
                        } else {
                            Button {
                                withAnimation { showAllUpcoming = false }
                            } label: {
                                Text(L10n.text("friend.history.upcoming.show_less", "Show fewer upcoming"))
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                            }
                            .listRowBackground(AppTheme.subtleFill)
                        }
                    }
                }
            }
            if !past.isEmpty {
                Section {
                    if isPastExpanded {
                        ForEach(past) { meeting in
                            NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                                meetingRow(meeting)
                            }
                            .listRowBackground(AppTheme.subtleFill)
                        }
                    }
                } header: {
                    Button {
                        withAnimation { isPastExpanded.toggle() }
                    } label: {
                        HStack {
                            Text(L10n.text("meeting.section.past", "Past"))
                            Spacer()
                            Image(systemName: isPastExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(L10n.text("friend.section.history", "Meetings / Events"))
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
                }
                .accessibilityLabel(L10n.text("common.add", "Add"))
            }
        }
        .overlay {
            if upcoming.isEmpty && past.isEmpty {
                ContentUnavailableView {
                    Label(
                        L10n.text("friend.section.history", "Meetings / Events"),
                        systemImage: "clock.arrow.circlepath"
                    )
                } description: {
                    Text(L10n.text("list.detail.empty", "Tap + to add an entry."))
                }
            }
        }
        .sheet(isPresented: $showingAddMeeting) {
            AddMeetingView(initialDate: Date(), preselectedFriends: [friend])
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(initialDate: Date(), preselectedFriends: [friend])
        }
        .appScreenBackground()
    }

    /// Renders one timeline row for a meeting or event entry.
    ///
    /// - Parameter meeting: Timeline entry displayed in the row.
    /// - Returns: Styled row with title, schedule, and optional note preview.
    private func meetingRow(_ meeting: Meeting) -> some View {
        HStack(spacing: 12) {
            Image(systemName: meeting.kind == .meeting ? "person.2.fill" : "flag.fill")
                .font(.title3)
                .foregroundStyle(meeting.kind == .meeting ? AppTheme.accent : AppTheme.event)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(meeting.displayTitle)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(
                    meeting.kind == .meeting
                        ? "\(meeting.startDate.formatted(date: .abbreviated, time: .shortened)) – \(meeting.endDate.formatted(date: .omitted, time: .shortened))"
                        : meeting.startDate.formatted(date: .abbreviated, time: .shortened)
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if !meeting.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(meeting.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
