import SwiftUI

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
