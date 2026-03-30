import SwiftUI
import SwiftData

// MARK: - Root

/// Hosts the app's root tabs and keeps local notification scheduling in sync with data changes.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFriends: [Friend]
    @Query private var allMeetings: [Meeting]
    @State private var hasSeededDebugData = false

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("globalNotifyBirthday") private var globalNotifyBirthday = true
    @AppStorage("globalBirthdayReminderDays") private var globalBirthdayReminderDays = 3
    @AppStorage("globalNotifyMeetings") private var globalNotifyMeetings = true
    @AppStorage("globalMeetingReminderDays") private var globalMeetingReminderDays = 1
    @AppStorage("globalNotifyEvents") private var globalNotifyEvents = true
    @AppStorage("globalEventReminderDays") private var globalEventReminderDays = 2
    @AppStorage("globalNotifyLongNoMeeting") private var globalNotifyLongNoMeeting = false
    @AppStorage("globalLongNoMeetingWeeks") private var globalLongNoMeetingWeeks = 4
    @AppStorage("globalNotifyPostMeetingNote") private var globalNotifyPostMeetingNote = true

    /// Builds a stable signature string for all friends to detect scheduling-relevant changes.
    ///
    /// - Returns: A deterministic hash-like string derived from friend fields used by notifications.
    private var friendsSignature: String {
        allFriends.map { friend in
            [
                "\(friend.persistentModelID)",
                friend.firstName,
                friend.lastName,
                friend.nickname,
                "\(friend.birthday?.timeIntervalSince1970 ?? 0)",
                "\(friend.meetings.count)"
            ].joined(separator: "|")
        }
        .joined(separator: "||")
    }

    /// Builds a stable signature string for all meetings/events to detect scheduling-relevant changes.
    ///
    /// - Returns: A deterministic hash-like string derived from meeting fields used by notifications.
    private var meetingsSignature: String {
        allMeetings.map { meeting in
            let friendIDs = meeting.friends.map { "\($0.persistentModelID)" }.joined(separator: ",")
            return [
                "\(meeting.persistentModelID)",
                "\(meeting.startDate.timeIntervalSince1970)",
                "\(meeting.endDate.timeIntervalSince1970)",
                meeting.kindRaw,
                meeting.eventTitle,
                friendIDs
            ].joined(separator: "|")
        }
        .joined(separator: "||")
    }

    /// Materializes persisted app settings into a notification scheduler configuration object.
    ///
    /// - Returns: Notification settings consumed by `NotificationService`.
    private var appNotificationSettings: AppNotificationSettings {
        AppNotificationSettings(
            notificationsEnabled: notificationsEnabled,
            globalNotifyBirthday: globalNotifyBirthday,
            globalBirthdayReminderDays: globalBirthdayReminderDays,
            globalNotifyMeetings: globalNotifyMeetings,
            globalMeetingReminderDays: globalMeetingReminderDays,
            globalNotifyEvents: globalNotifyEvents,
            globalEventReminderDays: globalEventReminderDays,
            globalNotifyLongNoMeeting: globalNotifyLongNoMeeting,
            globalLongNoMeetingWeeks: globalLongNoMeetingWeeks,
            globalNotifyPostMeetingNote: globalNotifyPostMeetingNote
        )
    }

    /// Aggregates settings and data signatures into a single change token.
    ///
    /// - Returns: A combined signature used to trigger full notification rescheduling.
    private var refreshSignature: String {
        [
            "\(globalNotifyBirthday)",
            "\(globalBirthdayReminderDays)",
            "\(globalNotifyMeetings)",
            "\(globalMeetingReminderDays)",
            "\(globalNotifyEvents)",
            "\(globalEventReminderDays)",
            "\(globalNotifyLongNoMeeting)",
            "\(globalLongNoMeetingWeeks)",
            "\(globalNotifyPostMeetingNote)",
            friendsSignature,
            meetingsSignature
        ].joined(separator: "||")
    }

    var body: some View {
        mainTabs
            .task {
                await refreshNotificationSchedule()
            }
            .onAppear {
                seedDebugDataIfNeeded()
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                Task {
                    if newValue {
                        _ = await NotificationService.shared.requestAuthorizationIfNeeded()
                        await refreshNotificationSchedule()
                    } else {
                        await NotificationService.shared.clearManagedNotifications()
                    }
                }
            }
            .onChange(of: refreshSignature) { _, _ in
                Task {
                    await refreshNotificationSchedule()
                }
            }
    }

    /// Renders the root tab view for friends, calendar, and global settings.
    private var mainTabs: some View {
        TabView {
            FriendsListView()
                .tabItem { Label(L10n.text("tab.friends", "Friends"), systemImage: "person.2.fill") }

            CalendarView()
                .tabItem { Label(L10n.text("tab.calendar", "Calendar"), systemImage: "calendar") }

            AppSettingsView()
                .tabItem { Label(L10n.text("tab.settings", "Settings"), systemImage: "gearshape.fill") }
        }
        .background {
            AppGradientBackground()
                .ignoresSafeArea()
        }
    }

    /// Rebuilds all managed local notifications based on current data and settings.
    private func refreshNotificationSchedule() async {
        await NotificationService.shared.rescheduleAll(
            friends: allFriends,
            meetings: allMeetings,
            settings: appNotificationSettings
        )
    }

    /// Inserts sample data once during debug runs when storage is empty.
    private func seedDebugDataIfNeeded() {
        #if DEBUG
        guard !hasSeededDebugData else { return }
        hasSeededDebugData = true
        guard allFriends.isEmpty else { return }
        DummyDataSeeder.insertDummyData(context: modelContext)
        #endif
    }
}

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
                return L10n.text("friends.sort.next_meeting", "Nächstes Treffen ↑")
            case .nextEvent:
                return L10n.text("friends.sort.next_event", "Nächstes Event ↑")
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
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
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
        } actions: {
            Button(L10n.text("friends.empty.action", "Add Friend")) { showingAddFriend = true }
                .buttonStyle(.borderedProminent)
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
struct FriendRow: View {
    let friend: Friend
    @AppStorage(AppTagStore.key) private var definedTagsRaw = "[]"

    /// Returns friend tags that still exist in the global tag registry.
    ///
    /// - Returns: Case-insensitive intersection of friend tags and globally defined tags.
    private var activeTags: [String] {
        let allowed = Set(AppTagStore.decode(definedTagsRaw).map { $0.lowercased() })
        return friend.tags.filter { allowed.contains($0.lowercased()) }
    }

    private var lastSeenText: String? {
        let now = Date()
        guard let lastDate = friend.meetings
            .filter({ $0.kind == .meeting && $0.startDate <= now })
            .map(\.startDate)
            .max()
        else { return nil }

        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: lastDate, to: now).day ?? 0
        if days == 0 { return L10n.text("friends.last_seen.today", "today") }
        if days == 1 { return L10n.text("friends.last_seen.day.one", "1 day ago") }
        if days < 7 { return L10n.text("friends.last_seen.day.other", "%d days ago", days) }
        let weeks = days / 7
        if weeks == 1 { return L10n.text("friends.last_seen.week.one", "1 week ago") }
        if weeks < 5 { return L10n.text("friends.last_seen.week.other", "%d weeks ago", weeks) }
        let months = cal.dateComponents([.month], from: lastDate, to: now).month ?? 0
        if months == 1 { return L10n.text("friends.last_seen.month.one", "1 month ago") }
        if months < 12 { return L10n.text("friends.last_seen.month.other", "%d months ago", months) }
        let years = cal.dateComponents([.year], from: lastDate, to: now).year ?? 0
        return years == 1
            ? L10n.text("friends.last_seen.year.one", "1 year ago")
            : L10n.text("friends.last_seen.year.other", "%d years ago", years)
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: friend.displayName, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(friend.displayName)
                        .font(.body.weight(.medium))
                    if friend.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                if !friend.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !friend.fullName.isEmpty {
                    Text(friend.fullName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let lastSeen = lastSeenText {
                    Text(lastSeen)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !activeTags.isEmpty {
                    inlineTags
                } else if let latestNote = friend.latestNote {
                    Text(latestNote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Renders up to three tags inline and collapses the rest into a `+N` indicator.
    private var inlineTags: some View {
        HStack(spacing: 5) {
            ForEach(Array(activeTags.prefix(3)), id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppTheme.subtleFill, in: Capsule())
                    .lineLimit(1)
            }
            if activeTags.count > 3 {
                Text("+\(activeTags.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, Meeting.self, GiftIdea.self, FriendEntry.self], inMemory: true)
}

/// Creates preview/debug seed data for local development.
private enum DummyDataSeeder {
    /// Inserts realistic demo data with rich friend profiles, notes, gifts, meetings, and events.
    ///
    /// - Parameter context: Target SwiftData model context.
    static func insertDummyData(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let existingTagsRaw = UserDefaults.standard.string(forKey: AppTagStore.key) ?? "[]"
        if AppTagStore.decode(existingTagsRaw).isEmpty {
            let defaultTags = [
                "Best Friend", "Family", "Work", "Travel", "Gym", "Study",
                "Music", "Foodie", "Tech", "Sports", "Neighbors", "Creative"
            ]
            UserDefaults.standard.set(AppTagStore.encode(defaultTags), forKey: AppTagStore.key)
        }

        func day(_ offset: Int, _ hour: Int, _ minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        @discardableResult
        func makeFriend(
            firstName: String,
            lastName: String,
            nickname: String = "",
            tags: [String],
            birthday: Date,
            favorite: Bool = false
        ) -> Friend {
            let friend = Friend(
                firstName: firstName,
                lastName: lastName,
                nickname: nickname,
                tags: tags,
                birthday: birthday,
                isFavorite: favorite
            )
            context.insert(friend)
            return friend
        }

        func makeMeeting(
            dayOffset: Int,
            startHour: Int,
            startMinute: Int,
            durationMinutes: Int,
            note: String,
            friends: [Friend]
        ) -> Meeting {
            let start = day(dayOffset, startHour, startMinute)
            let end = calendar.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
            return Meeting(
                eventTitle: "",
                startDate: start,
                endDate: end,
                note: note,
                kind: .meeting,
                friends: friends
            )
        }

        func makeEvent(
            dayOffset: Int,
            hour: Int,
            minute: Int,
            title: String,
            note: String,
            friends: [Friend]
        ) -> Meeting {
            let start = day(dayOffset, hour, minute)
            return Meeting(
                eventTitle: title,
                startDate: start,
                endDate: start,
                note: note,
                kind: .event,
                friends: friends
            )
        }

        func addDetailedEntries(
            _ values: [(title: String, note: String)],
            category: String,
            to friend: Friend
        ) {
            let existing = Set(
                friend.entryList(for: category).map {
                    $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                }
            )
            var order = friend.entryList(for: category).count
            for value in values where !existing.contains(value.title.lowercased()) {
                let entry = FriendEntry(
                    title: value.title,
                    note: value.note,
                    category: category,
                    order: order
                )
                context.insert(entry)
                friend.entries.append(entry)
                order += 1
            }
        }

        @discardableResult
        func addGift(_ title: String, _ note: String, _ isGifted: Bool = false, to friend: Friend) -> GiftIdea {
            let idea = GiftIdea(title: title, note: note, isGifted: isGifted)
            idea.friend = friend
            friend.giftIdeas.append(idea)
            context.insert(idea)
            return idea
        }

        // Exactly 7 friends with rich profile data.
        let mia = makeFriend(
            firstName: "Mia",
            lastName: "Schneider",
            nickname: "Mimi",
            tags: ["Best Friend", "Work", "Foodie"],
            birthday: calendar.date(from: DateComponents(year: 1993, month: 8, day: 17)) ?? now,
            favorite: true
        )
        let leon = makeFriend(
            firstName: "Leon",
            lastName: "Keller",
            tags: ["Gym", "Travel", "Sports"],
            birthday: calendar.date(from: DateComponents(year: 1990, month: 12, day: 3)) ?? now
        )
        let emma = makeFriend(
            firstName: "Emma",
            lastName: "Wagner",
            nickname: "Em",
            tags: ["Family", "Study", "Creative"],
            birthday: calendar.date(from: DateComponents(year: 2000, month: 4, day: 9)) ?? now,
            favorite: true
        )
        let noah = makeFriend(
            firstName: "Noah",
            lastName: "Bergmann",
            nickname: "No",
            tags: ["Work", "Tech", "Neighbors"],
            birthday: calendar.date(from: DateComponents(year: 1988, month: 9, day: 28)) ?? now
        )
        let sofia = makeFriend(
            firstName: "Sofia",
            lastName: "Hartmann",
            nickname: "Sofi",
            tags: ["Travel", "Foodie", "Best Friend"],
            birthday: calendar.date(from: DateComponents(year: 1994, month: 11, day: 21)) ?? now
        )
        let paul = makeFriend(
            firstName: "Paul",
            lastName: "Neumann",
            tags: ["Sports", "Neighbors", "Family"],
            birthday: calendar.date(from: DateComponents(year: 1992, month: 2, day: 14)) ?? now
        )
        let lina = makeFriend(
            firstName: "Lina",
            lastName: "Krüger",
            nickname: "Li",
            tags: ["Creative", "Study", "Music"],
            birthday: calendar.date(from: DateComponents(year: 1998, month: 7, day: 1)) ?? now
        )

        let friendData: [(friend: Friend, hobbies: [(String, String)], foods: [(String, String)], musics: [(String, String)], movies: [(String, String)], notes: [(String, String)])] = [
            (
                mia,
                [("Bouldering", "Member at Boulderklub Nord, mostly Tue/Thu evenings."), ("Street Photography", "Shoots with Fuji X100V; wants to try film in summer."), ("Pilates", "Prefers classes on Saturday mornings."), ("Weekend City Trips", "One museum + one café rule.")],
                [("Sushi", "Loves salmon nigiri, dislikes too much mayo."), ("Homemade Pasta", "Favorite: cacio e pepe, medium spicy."), ("Falafel Bowl", "No olives; extra lemon dressing."), ("Tiramisu", "Prefers less sweet, espresso-heavy versions.")],
                [("Indie Pop", "Current loop: Japanese House + Phoebe Bridgers."), ("Lo-Fi", "Uses chill playlists while editing photos."), ("Acoustic Sessions", "Collects Tiny Desk performances."), ("Electro Swing", "Dance playlists for house parties.")],
                [("The Bear", "Loves the kitchen pacing."), ("Dune: Part Two", "Wants to rewatch in IMAX."), ("Past Lives", "Favorite from last year."), ("The White Lotus", "Travel aesthetics inspiration.")],
                [("Prefers voice notes over long chats", "Reply window usually same day."), ("Camera lens purchase in Q2", "Comparing 23mm and 35mm options."), ("Planning Porto trip in June", "Needs hotel shortlist."), ("Can do spontaneous weekday dinners", "Best after 18:30.")]
            ),
            (
                leon,
                [("Half-Marathon Training", "Long run Sundays; intervals Wednesdays."), ("Home Cooking", "Batch-cooks for work week."), ("Strength Training", "Lower-body split currently."), ("Hiking", "Planning alpine weekend in May.")],
                [("Ramen", "Prefers tonkotsu, no bamboo shoots."), ("Tacos", "Fish tacos with lime crema."), ("Steak", "Medium rare only."), ("Burrata Salad", "Tomato + peach combo in summer.")],
                [("House", "Friday workout playlist."), ("Hip-Hop", "Old-school + UK rap mix."), ("Techno", "Underground sets for long drives."), ("Drum & Bass", "Pre-run motivation.")],
                [("Severance", "Discusses theories after each episode."), ("Shogun", "Favorite visuals this season."), ("The Gentlemen", "Easy weekend binge."), ("Top Boy", "Rewatch started.")],
                [("Morning person", "Best calls before 9:00."), ("Lisbon trip planning", "Wants running route suggestions."), ("Prefers short messages", "Responsive in afternoons."), ("Buying new running shoes", "Compare support vs. lightweight.")]
            ),
            (
                emma,
                [("Yoga", "Loves vinyasa, avoids hot yoga."), ("Sketching", "Carries A5 sketchbook daily."), ("Reading", "Alternates fiction and essays."), ("Journaling", "Nightly 10-minute reflections.")],
                [("Thai Curry", "Yellow curry with tofu."), ("Dumplings", "Favorite: mushroom + chive."), ("Granola Bowls", "No banana, extra berries."), ("Miso Soup", "Comfort food on busy days.")],
                [("Neo Soul", "Plays while studying."), ("Jazz Piano", "Favorite for calm evenings."), ("Indie Folk", "Sunday cleanup soundtrack."), ("Classical", "Focus playlists during exam prep.")],
                [("Normal People", "Rewatch with friend group."), ("Little Women", "All-time comfort movie."), ("The Bear", "Loves character writing."), ("One Day", "Recent recommendation.")],
                [("Final exams this month", "Avoid late-night meetups."), ("Needs presentation rehearsal", "Help with timing + slides."), ("Birthday dinner idea", "Small group, cozy place."), ("Prefers Sunday check-ins", "Usually free after 17:00.")]
            ),
            (
                noah,
                [("Cycling", "Commutes by bike year-round."), ("Board Games", "Hosts monthly game night."), ("Home Coffee Roasting", "Tracks roast profiles in a sheet."), ("DIY Keyboard Builds", "Trying silent tactile switches.")],
                [("Pho", "Extra herbs, less sugar in broth."), ("Smash Burger", "Double patty, no pickles."), ("Ceviche", "Loves citrus-heavy versions."), ("Shakshuka", "Weekend brunch staple.")],
                [("Ambient", "For deep work blocks."), ("Progressive House", "Night drive playlists."), ("Synthwave", "Coding sessions."), ("Instrumental Hip-Hop", "Morning focus.")],
                [("Black Mirror", "Keeps a ranking list."), ("Arrival", "Rewatch every few months."), ("Mr. Robot", "Tech reference favorite."), ("Silo", "Currently watching.")],
                [("Planning cloud migration", "Decision meeting next week."), ("Prefers async updates", "Slack over phone calls."), ("Available for office lunch", "Tue or Thu works best."), ("Needs monitor stand recommendation", "32-inch ultrawide setup.")]
            ),
            (
                sofia,
                [("Pottery", "Works on cups and small plates."), ("Weekend Trips", "Prefers train-friendly destinations."), ("Pilates", "Mat classes twice a week."), ("Language Learning", "Spanish practice every morning.")],
                [("Tapas", "Loves pimientos + croquetas."), ("Paella", "Seafood only."), ("Soba", "Cold soba in summer."), ("Cheesecake", "Basque style favorite.")],
                [("Latin Pop", "Weekend dance playlist."), ("R&B", "Evening wind-down songs."), ("Afrobeats", "Party starter set."), ("Soul", "Travel playlist staple.")],
                [("The Queen's Gambit", "Rewatching with cousin."), ("Past Lives", "Top recommendation."), ("The Diplomat", "Current series."), ("Emily in Paris", "Guilty pleasure watch.")],
                [("Collects restaurant tips per city", "Keeps Notion list updated."), ("Flying to Lisbon soon", "Send café suggestions."), ("Birthday gift should be handmade", "No generic gift cards."), ("Prefers evening meetup times", "After 19:00 ideal.")]
            ),
            (
                paul,
                [("Tennis", "Doubles every Wednesday."), ("Swimming", "Morning lanes Saturdays."), ("DIY Projects", "Currently building shelf wall."), ("Cycling", "Short evening rides in good weather.")],
                [("Napolitan Pizza", "Thin crust, little cheese."), ("Kebab", "No onions, spicy sauce."), ("Protein Bowl", "Chicken + edamame combo."), ("Sourdough Sandwiches", "Pesto + turkey favorite.")],
                [("Rock", "Workout playlist classic."), ("Pop Punk", "Nostalgic favorites."), ("Alternative", "Weekend cycling mix."), ("Funk", "For house chores.")],
                [("Ted Lasso", "Comfort series."), ("Top Gun: Maverick", "Favorite rewatch."), ("Drive to Survive", "Keeps up each season."), ("The Last Dance", "Sports doc favorite.")],
                [("Morning person", "Best plans before noon."), ("Open for spontaneous bike rides", "Usually available Sundays."), ("Home project help needed", "Lamp installation pending."), ("Birthday dinner likes grills", "Not too loud places.")]
            ),
            (
                lina,
                [("Illustration", "Digital + watercolor mix."), ("Museum Visits", "Modern art focus."), ("Calligraphy", "Copperplate practice weekly."), ("Piano", "Learning jazz standards.")],
                [("Poke Bowl", "Salmon + mango combo."), ("Miso Soup", "Comfort food for study days."), ("Blueberry Pancakes", "Sunday brunch favorite."), ("Kimchi Fried Rice", "Medium spicy.")],
                [("Film Scores", "Hans Zimmer heavy rotation."), ("Classical", "Focus while writing thesis."), ("Dream Pop", "Evening drawing sessions."), ("Singer-Songwriter", "Acoustic study breaks.")],
                [("Amelie", "Visual style inspiration."), ("Howl's Moving Castle", "Comfort rewatch."), ("Portrait of a Lady on Fire", "Top 3 favorite."), ("Everything Everywhere All at Once", "Loved narrative pace.")],
                [("Thesis deadline in two weeks", "Needs low-distraction meetups."), ("Prefers coworking over cafés", "Power outlet required."), ("Loves stationery", "Pen set idea for birthday."), ("Saturday brunch works", "After 11:30 ideal.")]
            )
        ]

        for data in friendData {
            addDetailedEntries(data.hobbies, category: "hobbies", to: data.friend)
            addDetailedEntries(data.foods, category: "foods", to: data.friend)
            addDetailedEntries(data.musics, category: "musics", to: data.friend)
            addDetailedEntries(data.movies, category: "moviesSeries", to: data.friend)
            addDetailedEntries(data.notes, category: "notes", to: data.friend)
        }

        let giftsByFriend: [(Friend, [(String, String, Bool)])] = [
            (mia, [("Vintage Film Camera Strap", "Dark brown leather, minimal logo.", false), ("Ceramic Dripper Set", "V60 size 02 + server.", true), ("Climbing Chalk Bag", "Forest green preferred.", false), ("Photo Book Voucher", "For annual print project.", false)]),
            (leon, [("Running Belt", "Slim model with key clip.", true), ("Gym Towel Set", "Quick-dry microfiber.", false), ("Massage Gun Mini", "Travel-friendly size preferred.", false), ("Meal Prep Glass Containers", "Leak-proof lids are a must.", false)]),
            (emma, [("Premium Sketchbook", "A4, thick paper for markers.", false), ("Bookstore Gift Card", "For post-exam reward.", false), ("Desk Lamp", "Warm light, dimmable.", true), ("Matcha Starter Set", "Bamboo whisk included.", false)]),
            (noah, [("Mechanical Keyboard Keycaps", "Muted grayscale set.", false), ("Smart Bike Light", "USB-C rechargeable.", false), ("Board Game Expansion", "Co-op mode preferred.", true), ("Cable Organizer Kit", "Magnetic desk clips.", false)]),
            (sofia, [("Travel Journal", "Hardcover, blank dotted pages.", false), ("Noise-Cancelling Earbuds", "For flights + coworking.", false), ("Handmade Ceramic Mug", "Terracotta glaze style.", true), ("Packing Cube Set", "Lightweight and washable.", false)]),
            (paul, [("Tennis Grip Bundle", "White + blue mix.", false), ("Swim Goggles Pro", "Anti-fog mirrored lenses.", false), ("DIY Tool Roll", "Compact size preferred.", true), ("Insulated Bottle", "1L, dishwasher safe.", false)]),
            (lina, [("Watercolor Brush Set", "Synthetic sable, travel case.", false), ("Museum Membership Pass", "Annual, flexible dates.", false), ("Premium Pen Set", "Fine nib, black + sepia ink.", true), ("Portable Sketch Light", "USB rechargeable.", false)])
        ]

        for (friend, gifts) in giftsByFriend {
            for gift in gifts {
                addGift(gift.0, gift.1, gift.2, to: friend)
            }
        }

        let timeline: [Meeting] = [
            makeMeeting(dayOffset: -18, startHour: 19, startMinute: 0, durationMinutes: 110, note: "Italian dinner catch-up. Mia wants feedback on her photo-book layout.", friends: [mia, emma]),
            makeEvent(dayOffset: -15, hour: 9, minute: 0, title: "Noah Production Rollout", note: "Send a good-luck message before deploy window.", friends: [noah]),
            makeMeeting(dayOffset: -13, startHour: 18, startMinute: 30, durationMinutes: 90, note: "Running session with Leon + Paul, then smoothie stop.", friends: [leon, paul]),
            makeMeeting(dayOffset: -10, startHour: 20, startMinute: 0, durationMinutes: 130, note: "Board-game evening at Noah's, bring card sleeves.", friends: [mia, noah, lina]),
            makeEvent(dayOffset: -8, hour: 14, minute: 15, title: "Emma Oral Exam", note: "Call Emma after exam and plan celebration dinner.", friends: [emma]),
            makeMeeting(dayOffset: -6, startHour: 12, startMinute: 45, durationMinutes: 75, note: "Lunch with Sofia to shortlist Lisbon cafés and coworking spots.", friends: [sofia]),
            makeMeeting(dayOffset: -3, startHour: 19, startMinute: 15, durationMinutes: 105, note: "Pottery + dinner evening with Sofia and Lina.", friends: [sofia, lina]),
            makeMeeting(dayOffset: -1, startHour: 8, startMinute: 10, durationMinutes: 60, note: "Morning tennis + coffee recap with Paul.", friends: [paul]),
            makeMeeting(dayOffset: 1, startHour: 18, startMinute: 30, durationMinutes: 120, note: "Ramen night with Mia and Noah; discuss next mini-trip.", friends: [mia, noah]),
            makeEvent(dayOffset: 2, hour: 10, minute: 0, title: "Lina Thesis Submission", note: "Flowers + short celebration planned for the evening.", friends: [lina]),
            makeMeeting(dayOffset: 3, startHour: 19, startMinute: 40, durationMinutes: 100, note: "Workout + stretch block with Leon and Paul.", friends: [leon, paul]),
            makeEvent(dayOffset: 5, hour: 16, minute: 30, title: "Sofia Flight to Lisbon", note: "Send airport transfer tips and ask for hotel update.", friends: [sofia]),
            makeMeeting(dayOffset: 7, startHour: 11, startMinute: 30, durationMinutes: 95, note: "Brunch and museum plan with Emma + Lina.", friends: [emma, lina]),
            makeMeeting(dayOffset: 9, startHour: 18, startMinute: 0, durationMinutes: 80, note: "Sprint-planning style check-in with Noah and Mia.", friends: [noah, mia]),
            makeEvent(dayOffset: 12, hour: 8, minute: 45, title: "Leon Half Marathon", note: "Meet at km marker 15 with water and snacks.", friends: [leon]),
            makeMeeting(dayOffset: 14, startHour: 20, startMinute: 10, durationMinutes: 125, note: "Movie + dessert night: Emma picks the film.", friends: [emma, mia, sofia]),
            makeMeeting(dayOffset: 17, startHour: 13, startMinute: 0, durationMinutes: 70, note: "Quick lunch catch-up with Paul and Noah near office.", friends: [paul, noah]),
            makeEvent(dayOffset: 21, hour: 19, minute: 0, title: "Mia Photo Walk Meetup", note: "Golden hour route through old town.", friends: [mia, lina]),
            makeMeeting(dayOffset: 24, startHour: 18, startMinute: 20, durationMinutes: 120, note: "Group dinner: discuss summer trip dates.", friends: [mia, leon, emma, sofia, paul, lina]),
            makeMeeting(dayOffset: 29, startHour: 11, startMinute: 0, durationMinutes: 90, note: "Sunday brunch with Sofia and Emma, keep it low-key.", friends: [sofia, emma])
        ]
        timeline.forEach { context.insert($0) }
    }
}
