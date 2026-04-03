import SwiftUI
import SwiftData
import Combine

// MARK: - Root

/// Hosts the app's root tabs and keeps local notification scheduling in sync with data changes.
struct ContentView: View {
    /// Root tab selection keys for programmatic navigation.
    private enum RootTab: Hashable {
        case friends
        case calendar
        case gifts
        case settings
    }

    /// Detail sheets opened from notification deep links.
    private enum DeepLinkSheet: Identifiable {
        case friend(String)
        case meeting(String)
        case followUp(String)

        var id: String {
            switch self {
            case .friend(let id):
                return "friend-\(id)"
            case .meeting(let id):
                return "meeting-\(id)"
            case .followUp(let id):
                return "followup-\(id)"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var allFriends: [Friend]
    @Query private var allMeetings: [Meeting]
    @Query(sort: [SortDescriptor(\FollowUpTask.dueDate)]) private var allFollowUps: [FollowUpTask]
    @ObservedObject private var notificationRouteStore = NotificationRouteStore.shared
    @State private var hasSeededDebugData = false
    @State private var selectedTab: RootTab = .friends
    @State private var deepLinkSheet: DeepLinkSheet?

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
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
    @AppStorage("globalNotifyFollowUps") private var globalNotifyFollowUps = true

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

    /// Builds a stable signature string for all follow-up tasks to detect scheduling-relevant changes.
    ///
    /// - Returns: A deterministic string derived from follow-up fields used by notifications.
    private var followUpsSignature: String {
        allFollowUps.map { task in
            [
                "\(task.persistentModelID)",
                task.title,
                task.note,
                "\(task.dueDate.timeIntervalSince1970)",
                "\(task.isCompleted)",
                task.friend.map { "\($0.persistentModelID)" } ?? ""
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
            globalReminderTimeMinutes: globalReminderTimeMinutes,
            globalNotifyPostMeetingNote: globalNotifyPostMeetingNote,
            globalNotifyFollowUps: globalNotifyFollowUps
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
            "\(globalReminderTimeMinutes)",
            "\(globalNotifyPostMeetingNote)",
            "\(globalNotifyFollowUps)",
            friendsSignature,
            meetingsSignature,
            followUpsSignature
        ].joined(separator: "||")
    }

    var body: some View {
        mainTabs
            .task {
                if let pendingRoute = notificationRouteStore.pendingRoute {
                    handleNotificationRoute(pendingRoute)
                    notificationRouteStore.consume()
                }
                await refreshNotificationSchedule()
            }
            .onAppear {
                seedDebugDataIfNeeded()
            }
            .onReceive(notificationRouteStore.$pendingRoute.compactMap { $0 }) { route in
                handleNotificationRoute(route)
                notificationRouteStore.consume()
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
            .sheet(item: $deepLinkSheet) { destination in
                deepLinkDestinationView(for: destination)
            }
    }

    /// Renders the root tab view for friends, calendar, and global settings.
    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            FriendsListView()
                .tabItem { Label(L10n.text("tab.friends", "Friends"), systemImage: "person.2.fill") }
                .tag(RootTab.friends)

            CalendarView()
                .tabItem { Label(L10n.text("tab.calendar", "Calendar"), systemImage: "calendar") }
                .tag(RootTab.calendar)

            GiftsView()
                .tabItem { Label(L10n.text("tab.gifts", "Gifts"), systemImage: "gift.fill") }
                .tag(RootTab.gifts)

            AppSettingsView()
                .tabItem { Label(L10n.text("tab.settings", "Settings"), systemImage: "gearshape.fill") }
                .tag(RootTab.settings)
        }
        .background {
            AppGradientBackground()
                .ignoresSafeArea()
        }
    }

    /// Handles one route from a tapped local notification.
    private func handleNotificationRoute(_ route: AppNotificationRoute) {
        switch route {
        case .friend(let routeID):
            selectedTab = .friends
            deepLinkSheet = .friend(routeID)
        case .meeting(let routeID):
            selectedTab = .calendar
            deepLinkSheet = .meeting(routeID)
        case .followUp(let routeID):
            selectedTab = .friends
            deepLinkSheet = .followUp(routeID)
        }
    }

    /// Builds the presented destination view for deep-link sheets.
    @ViewBuilder
    private func deepLinkDestinationView(for destination: DeepLinkSheet) -> some View {
        switch destination {
        case .friend(let routeID):
            if let friend = allFriends.first(where: { "\($0.persistentModelID)" == routeID }) {
                NavigationStack {
                    FriendDetailView(friend: friend)
                }
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        L10n.text("friend.unnamed", "Friend"),
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(L10n.text("notification.target.missing", "The related item could not be found."))
                    )
                    .navigationTitle(L10n.text("tab.friends", "Friends"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        case .meeting(let routeID):
            if let meeting = allMeetings.first(where: { "\($0.persistentModelID)" == routeID }) {
                NavigationStack {
                    MeetingDetailView(meeting: meeting)
                }
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        L10n.text("meeting.kind.event", "Event"),
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text(L10n.text("notification.target.missing", "The related item could not be found."))
                    )
                    .navigationTitle(L10n.text("tab.calendar", "Calendar"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        case .followUp(let routeID):
            if let followUp = allFollowUps.first(where: { "\($0.persistentModelID)" == routeID }) {
                NavigationStack {
                    FollowUpTaskDetailView(task: followUp)
                }
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        L10n.text("friend.section.follow_ups", "To-Dos"),
                        systemImage: "checklist",
                        description: Text(L10n.text("notification.target.missing", "The related item could not be found."))
                    )
                    .navigationTitle(L10n.text("tab.friends", "Friends"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    /// Rebuilds all managed local notifications based on current data and settings.
    private func refreshNotificationSchedule() async {
        await NotificationService.shared.rescheduleAll(
            friends: allFriends,
            meetings: allMeetings,
            followUpTasks: allFollowUps,
            settings: appNotificationSettings
        )
    }

    /// Inserts debug sample data once in debug runs when the local store is empty.
    private func seedDebugDataIfNeeded() {
        #if DEBUG
        guard !hasSeededDebugData else { return }
        hasSeededDebugData = true
        let persistedFriends = (try? modelContext.fetch(FetchDescriptor<Friend>())) ?? allFriends
        if persistedFriends.isEmpty {
            DummyDataSeeder.insertDummyData(context: modelContext)
        }
        Task {
            await refreshNotificationSchedule()
        }
        #endif
    }

}

// MARK: - Friends List

/// Shows the searchable friend list and supports contact creation.

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, Meeting.self, GiftIdea.self, FollowUpTask.self, FriendEntry.self], inMemory: true)
}
