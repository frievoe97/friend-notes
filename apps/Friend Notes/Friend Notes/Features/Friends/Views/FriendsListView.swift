import SwiftUI
import SwiftData
import Combine

// MARK: - Friends List

/// Shows the searchable friend list and supports contact creation.
struct FriendsListView: View {
    /// Available friend list sort modes.
    private enum FriendSortOption: String, CaseIterable, Identifiable {
        case nameAscending
        case nameDescending
        case lastSeenAscending
        case lastSeenDescending
        case nextMeeting
        case nextEvent

        /// Stable identifier for picker bindings.
        var id: String { rawValue }

        /// Localized display title for sort menu options.
        var title: String {
            switch self {
            case .nameAscending:
                return L10n.text("friends.sort.name_asc", "Name ↑")
            case .nameDescending:
                return L10n.text("friends.sort.name_desc", "Name ↓")
            case .lastSeenAscending:
                return L10n.text("friends.sort.last_seen_asc", "Last Seen ↑")
            case .lastSeenDescending:
                return L10n.text("friends.sort.last_seen_desc", "Last Seen ↓")
            case .nextMeeting:
                return L10n.text("friends.sort.next_meeting", "Next Meeting ↑")
            case .nextEvent:
                return L10n.text("friends.sort.next_event", "Next Event ↑")
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var friends: [Friend]
    @State private var showingAddFriend = false
    @State private var searchText = ""
    @State private var sortOption: FriendSortOption = .nameAscending

    /// Filters and sorts friends for list presentation.
    ///
    /// - Returns: Friends matching the current search text, favorites first, then by selected sort mode.
    var filteredFriends: [Friend] {
        let baseFriends: [Friend]
        if searchText.isEmpty {
            baseFriends = friends
        } else {
            baseFriends = friends.filter { friend in
                friend.firstName.localizedCaseInsensitiveContains(searchText) ||
                friend.lastName.localizedCaseInsensitiveContains(searchText) ||
                friend.nickname.localizedCaseInsensitiveContains(searchText) ||
                friend.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                friend.entries.contains { $0.title.localizedCaseInsensitiveContains(searchText) || $0.note.localizedCaseInsensitiveContains(searchText) }
            }
        }

        let now = Date()
        let lastSeenByFriendID = Dictionary(
            uniqueKeysWithValues: baseFriends.map { friend in
                (friend.persistentModelID, lastSeenMeetingDate(for: friend, now: now))
            }
        )

        return baseFriends.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }

            switch sortOption {
            case .nameAscending:
                return compareByName(lhs, rhs, ascending: true)
            case .nameDescending:
                return compareByName(lhs, rhs, ascending: false)
            case .lastSeenAscending:
                return compareByLastSeen(lhs, rhs, ascending: true, lookup: lastSeenByFriendID)
            case .lastSeenDescending:
                return compareByLastSeen(lhs, rhs, ascending: false, lookup: lastSeenByFriendID)
            case .nextMeeting:
                return compareByNextDate(
                    nextUpcomingDate(for: lhs, kind: .meeting, now: now),
                    nextUpcomingDate(for: rhs, kind: .meeting, now: now),
                    fallback: { compareByName(lhs, rhs, ascending: true) }
                )
            case .nextEvent:
                return compareByNextDate(
                    nextUpcomingDate(for: lhs, kind: .event, now: now),
                    nextUpcomingDate(for: rhs, kind: .event, now: now),
                    fallback: { compareByName(lhs, rhs, ascending: true) }
                )
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground()

                Group {
                    if friends.isEmpty {
                        emptyState
                    } else {
                        List {
                            let firstFriendID = filteredFriends.first?.persistentModelID
                            let lastFriendID = filteredFriends.last?.persistentModelID

                            ForEach(filteredFriends) { friend in
                                NavigationLink(destination: FriendDetailView(friend: friend)) {
                                    FriendRow(friend: friend)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(friend.persistentModelID == firstFriendID ? .hidden : .visible, edges: .top)
                                .listRowSeparator(friend.persistentModelID == lastFriendID ? .hidden : .visible, edges: .bottom)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .compositingGroup()
                        .searchable(text: $searchText, prompt: L10n.text("friends.search.placeholder", "Search friends or tags"))
                    }
                }
            }
            .navigationTitle(L10n.text("friends.title", "Friends"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddFriend = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showingAddFriend) {
                AddFriendView()
            }
        }
    }

    /// Sort selection menu shown in the navigation bar.
    private var sortMenu: some View {
        Menu {
            Picker(
                L10n.text("friends.sort.menu", "Sort"),
                selection: $sortOption
            ) {
                ForEach(FriendSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
        .accessibilityLabel(L10n.text("friends.sort.menu", "Sort"))
    }

    /// Placeholder content shown when no friends exist yet.
    private var emptyState: some View {
        ContentUnavailableView {
            Label(L10n.text("friends.empty.title", "No Friends Yet"), systemImage: "person.2")
        } description: {
            Text(L10n.text("friends.empty.desc", "Tap + to add your first friend."))
        }
    }

    /// Returns the latest past meeting date for a friend.
    ///
    /// - Parameters:
    ///   - friend: Friend to inspect.
    ///   - now: Current reference date.
    /// - Returns: Latest meeting date in the past, or `nil` when none exist.
    private func lastSeenMeetingDate(for friend: Friend, now: Date) -> Date? {
        friend.meetings
            .filter { $0.kind == .meeting && $0.startDate <= now }
            .map(\.startDate)
            .max()
    }

    /// Compares two friends by name.
    ///
    /// - Parameters:
    ///   - lhs: Left friend.
    ///   - rhs: Right friend.
    ///   - ascending: Sort direction.
    /// - Returns: `true` when `lhs` should appear before `rhs`.
    private func compareByName(_ lhs: Friend, _ rhs: Friend, ascending: Bool) -> Bool {
        let order = lhs.sortName.localizedCaseInsensitiveCompare(rhs.sortName)
        if order != .orderedSame {
            return ascending ? order == .orderedAscending : order == .orderedDescending
        }
        return lhs.createdAt < rhs.createdAt
    }

    /// Compares two friends by latest past meeting date.
    ///
    /// - Parameters:
    ///   - lhs: Left friend.
    ///   - rhs: Right friend.
    ///   - ascending: Sort direction (`true` = oldest first, `false` = newest first).
    ///   - lookup: Precomputed latest meeting date per friend model identifier.
    /// - Returns: `true` when `lhs` should appear before `rhs`.
    private func compareByLastSeen(
        _ lhs: Friend,
        _ rhs: Friend,
        ascending: Bool,
        lookup: [PersistentIdentifier: Date?]
    ) -> Bool {
        let lhsDate = lookup[lhs.persistentModelID] ?? nil
        let rhsDate = lookup[rhs.persistentModelID] ?? nil

        switch (lhsDate, rhsDate) {
        case let (.some(left), .some(right)):
            if left != right {
                return ascending ? left < right : left > right
            }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }

        return compareByName(lhs, rhs, ascending: true)
    }

    /// Returns the earliest upcoming meeting/event date of the given kind for a friend.
    private func nextUpcomingDate(for friend: Friend, kind: MeetingKind, now: Date) -> Date? {
        friend.meetings
            .filter { $0.kind == kind && $0.startDate > now }
            .map(\.startDate)
            .min()
    }

    /// Compares two optional dates ascending; friends with dates rank before those without.
    private func compareByNextDate(_ lhsDate: Date?, _ rhsDate: Date?, fallback: () -> Bool) -> Bool {
        switch (lhsDate, rhsDate) {
        case let (.some(l), .some(r)):
            return l != r ? l < r : fallback()
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return fallback()
        }
    }

}

// MARK: - Friend Row

/// Compact row view used in the friends list.
