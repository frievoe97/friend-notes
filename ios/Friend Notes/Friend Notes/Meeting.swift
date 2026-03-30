import Foundation
import SwiftData

/// Distinguishes friend-specific interactions from generic timeline events.
enum MeetingKind: String, CaseIterable, Identifiable {
    case meeting
    case event

    /// Stable identifier for use in SwiftUI pickers.
    var id: String { rawValue }

    /// Localized human-readable label.
    var title: String {
        switch self {
        case .meeting: return L10n.text("meeting.kind.meeting", "Meeting")
        case .event: return L10n.text("meeting.kind.event", "Event")
        }
    }

    /// SF Symbol name used in UI rows and badges.
    var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .event: return "flag.fill"
        }
    }
}

/// Persisted timeline entry representing either a meeting or an event.
@Model
final class Meeting {
    /// Optional title used only when `kind == .event`.
    var eventTitle: String
    /// Start date and time.
    var startDate: Date
    /// End date and time (always normalized to be >= `startDate`).
    var endDate: Date
    /// Optional user note attached to the entry.
    var note: String
    /// Raw persisted kind value.
    var kindRaw: String
    /// Linked friends participating in this entry.
    var friends: [Friend] = []

    /// Creates a meeting/event model and normalizes the end date.
    ///
    /// - Parameters:
    ///   - eventTitle: Optional event title.
    ///   - startDate: Entry start date.
    ///   - endDate: Entry end date. If `nil` or before `startDate`, a valid end date is generated.
    ///   - note: Optional note text.
    ///   - kind: Entry type (`meeting` or `event`).
    ///   - friends: Associated friends.
    init(
        eventTitle: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        note: String = "",
        kind: MeetingKind = .meeting,
        friends: [Friend] = []
    ) {
        let resolvedEnd = max(endDate ?? startDate.addingTimeInterval(60 * 60), startDate)
        self.eventTitle = eventTitle
        self.startDate = startDate
        self.endDate = resolvedEnd
        self.note = note
        self.kindRaw = kind.rawValue
        self.friends = friends
    }

    /// Typed access for the persisted kind value.
    ///
    /// - Returns: The decoded kind, defaulting to `.meeting` for unknown persisted values.
    var kind: MeetingKind {
        get { MeetingKind(rawValue: kindRaw) ?? .meeting }
        set { kindRaw = newValue.rawValue }
    }

    /// Preferred title shown in UI and notifications.
    ///
    /// - Returns: For events, a trimmed `eventTitle` when non-empty.
    ///   For meetings, a comma-separated participant list when available; otherwise the localized kind title.
    var displayTitle: String {
        if kind == .event {
            let trimmed = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? kind.title : trimmed
        }

        let names = friends
            .sorted { $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending }
            .map(\.displayName)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if names.isEmpty {
            return kind.title
        }
        return names.joined(separator: ", ")
    }
}
