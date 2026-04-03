import SwiftUI

// MARK: - Event Row: Follow-up

/// Row used to display a follow-up task in calendar day lists.
struct FollowUpEventRow: View {
    /// Follow-up task rendered by this row.
    let task: FollowUpTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "checklist")
                .foregroundStyle(task.isCompleted ? AppTheme.followUp.opacity(0.65) : AppTheme.followUp)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)

                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let trimmedNote = task.note.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    Text(trimmedNote)
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
