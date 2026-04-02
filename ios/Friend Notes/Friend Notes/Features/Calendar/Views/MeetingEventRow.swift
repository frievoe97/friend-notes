import SwiftUI

// MARK: - Event Row: Meeting/Event

/// Row used to display a meeting or event in daily lists.
struct MeetingEventRow: View {
    /// Timeline entry rendered by this row.
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
