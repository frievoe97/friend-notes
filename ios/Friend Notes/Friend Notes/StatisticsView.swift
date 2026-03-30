import SwiftUI
import SwiftData
import Charts

/// Presents app-wide friend and timeline analytics using Swift Charts.
struct StatisticsView: View {
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var friends: [Friend]
    @Query private var meetings: [Meeting]

    private let calendar = Calendar.current

    /// Current reference date for "past/upcoming" calculations.
    private var now: Date { Date() }

    private var meetingLabel: String { L10n.text("statistics.type.meeting", "Meeting") }
    private var eventLabel: String { L10n.text("statistics.type.event", "Event") }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                overviewSection
                monthlyActivitySection
                topFriendsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle(L10n.text("statistics.title", "Statistics"))
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    /// Top-level metric tiles for quick status overview.
    private var overviewSection: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            summaryTile(
                title: L10n.text("statistics.total_friends", "Friends"),
                value: "\(friends.count)",
                symbol: "person.2.fill"
            )
            summaryTile(
                title: L10n.text("statistics.favorites", "Favorites"),
                value: "\(friends.filter(\.isFavorite).count)",
                symbol: "star.fill"
            )
            summaryTile(
                title: L10n.text("statistics.meetings", "Meetings"),
                value: "\(meetings.filter { $0.kind == .meeting }.count)",
                symbol: "person.2"
            )
            summaryTile(
                title: L10n.text("statistics.events", "Events"),
                value: "\(meetings.filter { $0.kind == .event }.count)",
                symbol: "flag.fill"
            )
            summaryTile(
                title: L10n.text("statistics.upcoming", "Upcoming"),
                value: "\(meetings.filter { $0.startDate >= now }.count)",
                symbol: "calendar.badge.clock"
            )
            summaryTile(
                title: L10n.text("statistics.past", "Past"),
                value: "\(meetings.filter { $0.startDate < now }.count)",
                symbol: "clock.arrow.circlepath"
            )
        }
    }

    /// Grouped monthly chart for meetings/events in the last six months.
    private var monthlyActivitySection: some View {
        let points = monthlyActivityPoints
        return chartCard(title: L10n.text("statistics.activity.title", "Last 6 Months Activity")) {
            if points.allSatisfy({ $0.count == 0 }) {
                Text(L10n.text("statistics.activity.empty", "No activity yet."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", point.count)
                    )
                    .position(by: .value("Type", point.type))
                    .foregroundStyle(by: .value("Type", point.type))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale([
                    meetingLabel: AppTheme.accent,
                    eventLabel: AppTheme.event
                ])
                .chartLegend(position: .top, alignment: .leading)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 220)
            }
        }
    }

    /// Horizontal bar chart for most active relationships.
    private var topFriendsSection: some View {
        let rows = topFriendRows
        return chartCard(title: L10n.text("statistics.top_friends.title", "Most Active Friendships")) {
            if rows.isEmpty {
                Text(L10n.text("statistics.top_friends.empty", "No interactions yet."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else {
                Chart(rows) { row in
                    BarMark(
                        x: .value("Entries", row.total),
                        y: .value("Friend", row.name)
                    )
                    .foregroundStyle(AppTheme.accent.gradient)
                    .cornerRadius(5)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .frame(height: CGFloat(max(200, rows.count * 38)))
            }
        }
    }

    /// Returns grouped monthly points for meetings and events.
    private var monthlyActivityPoints: [ActivityPoint] {
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }

        let months: [Date] = (-5...0).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: startOfCurrentMonth)
        }

        return months.flatMap { monthStart in
            guard let interval = calendar.dateInterval(of: .month, for: monthStart) else {
                return [
                    ActivityPoint(month: monthStart, type: meetingLabel, count: 0),
                    ActivityPoint(month: monthStart, type: eventLabel, count: 0)
                ]
            }

            let monthMeetings = meetings.filter { interval.contains($0.startDate) && $0.kind == .meeting }.count
            let monthEvents = meetings.filter { interval.contains($0.startDate) && $0.kind == .event }.count

            return [
                ActivityPoint(month: monthStart, type: meetingLabel, count: monthMeetings),
                ActivityPoint(month: monthStart, type: eventLabel, count: monthEvents)
            ]
        }
    }

    /// Returns top friends sorted by total interaction count.
    private var topFriendRows: [FriendActivityRow] {
        friends
            .map { friend in
                let meetingCount = friend.meetings.filter { $0.kind == .meeting }.count
                let eventCount = friend.meetings.filter { $0.kind == .event }.count
                return FriendActivityRow(
                    name: friend.displayName,
                    total: meetingCount + eventCount
                )
            }
            .filter { $0.total > 0 }
            .sorted { lhs, rhs in
                if lhs.total != rhs.total { return lhs.total > rhs.total }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(6)
            .map { $0 }
    }

    /// Reusable style wrapper for chart cards.
    ///
    /// - Parameters:
    ///   - title: Card section title.
    ///   - content: Card body content.
    /// - Returns: Styled chart card.
    @ViewBuilder
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(16)
        .appGlassCard(cornerRadius: 16)
    }

    /// Reusable style wrapper for compact summary tiles.
    ///
    /// - Parameters:
    ///   - title: Metric title.
    ///   - value: Metric value text.
    ///   - symbol: SF Symbol used as icon.
    /// - Returns: Styled summary tile.
    @ViewBuilder
    private func summaryTile(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .appGlassCard(cornerRadius: 14)
    }
}

/// Activity point for grouped monthly chart.
private struct ActivityPoint: Identifiable {
    let id = UUID()
    let month: Date
    let type: String
    let count: Int
}

/// Ranked friend row for interaction chart.
private struct FriendActivityRow: Identifiable {
    let id = UUID()
    let name: String
    let total: Int
}
