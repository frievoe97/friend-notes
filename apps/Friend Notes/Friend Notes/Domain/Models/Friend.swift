import Foundation
import SwiftData

/// Persisted contact model storing identity, profile details, and related records.
@Model
final class Friend {
    /// The friend's first name.
    var firstName: String
    /// The friend's last name.
    var lastName: String
    /// Optional nickname shown as primary display name when not empty.
    var nickname: String
    /// User-selected tags from the global tag registry.
    var tags: [String]

    /// Optional birthday date, including year when set by the user.
    var birthday: Date?
    /// Creation timestamp.
    var createdAt: Date

    /// Whether the contact should be pinned near the top in list sorting.
    var isFavorite: Bool

    /// Meetings/events associated with this friend.
    @Relationship(deleteRule: .nullify, inverse: \Meeting.friends)
    var meetings: [Meeting] = []

    /// Gift idea entities owned by this friend.
    @Relationship(deleteRule: .cascade, inverse: \GiftIdea.friend)
    var giftIdeas: [GiftIdea] = []

    /// Follow-up task entities owned by this friend.
    @Relationship(deleteRule: .cascade, inverse: \FollowUpTask.friend)
    var followUpTasks: [FollowUpTask] = []

    /// Category entry entities owned by this friend.
    @Relationship(deleteRule: .cascade, inverse: \FriendEntry.friend)
    var entries: [FriendEntry] = []

    /// Creates a new friend model.
    ///
    /// - Parameters:
    ///   - firstName: The first name value.
    ///   - lastName: The last name value.
    ///   - nickname: Optional nickname.
    ///   - tags: Initial tag collection.
    ///   - birthday: Optional birthday.
    ///   - isFavorite: Pin state in list sorting.
    init(
        firstName: String = "",
        lastName: String = "",
        nickname: String = "",
        tags: [String] = [],
        birthday: Date? = nil,
        isFavorite: Bool = false
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.nickname = nickname
        self.tags = tags
        self.birthday = birthday
        self.createdAt = Date()
        self.isFavorite = isFavorite
    }

    /// Returns the trimmed full name built from first and last name.
    ///
    /// - Returns: A space-separated full name or an empty string when both parts are empty.
    var fullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Returns the preferred display name for UI presentation.
    ///
    /// - Returns: `nickname` when available, else `fullName`, else a localized unnamed fallback.
    var displayName: String {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNickname.isEmpty {
            return trimmedNickname
        }
        let combinedName = fullName
        return combinedName.isEmpty
            ? L10n.text("friend.unnamed", "Unnamed")
            : combinedName
    }

    /// Returns the canonical name source used for avatar initials.
    ///
    /// - Returns: Full name when available, otherwise nickname/display fallback.
    var avatarInitialsSource: String {
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFullName.isEmpty {
            return trimmedFullName
        }

        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNickname.isEmpty {
            return trimmedNickname
        }

        return displayName
    }

    /// Returns the stable color seed used for deterministic avatar coloring.
    ///
    /// - Returns: String form of the persistent model identifier.
    var avatarColorSeed: String {
        "\(persistentModelID)"
    }

    /// Returns the sort key used by friend list ordering.
    ///
    /// - Returns: `"lastName firstName"` when possible, otherwise `displayName`.
    var sortName: String {
        let ln = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if ln.isEmpty && fn.isEmpty {
            return displayName
        }
        return "\(ln) \(fn)"
    }

    /// Returns entries for one category, sorted by explicit order and stable creation tie-break.
    ///
    /// - Parameter category: Persisted category key to filter by.
    /// - Returns: Entries that belong to `category`, sorted for deterministic rendering.
    func entryList(for category: String) -> [FriendEntry] {
        entries.filter { $0.category == category }.sorted { $0.order < $1.order || ($0.order == $1.order && $0.createdAt < $1.createdAt) }
    }

    /// Returns the most recently created note entry title.
    ///
    /// - Returns: Latest note title for quick previews, or `nil` when no notes exist.
    var latestNote: String? {
        entries.filter { $0.category == "notes" }
            .sorted { $0.createdAt > $1.createdAt }
            .first?.title
    }
}
