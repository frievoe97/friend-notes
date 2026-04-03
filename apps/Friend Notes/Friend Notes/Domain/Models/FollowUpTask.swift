import Foundation
import SwiftData

/// Persisted follow-up task linked to a friend profile.
@Model
final class FollowUpTask {
    /// Task title.
    var title: String
    /// Optional task note.
    var note: String
    /// Due date and time for this follow-up.
    var dueDate: Date
    /// Completion state.
    var isCompleted: Bool
    /// Timestamp when the task was completed, if available.
    var completedAt: Date?
    /// Creation timestamp.
    var createdAt: Date
    /// Back-reference to the owning friend.
    var friend: Friend?

    /// Creates a follow-up task model.
    ///
    /// - Parameters:
    ///   - title: Task title.
    ///   - note: Optional note text.
    ///   - dueDate: Due date and time.
    ///   - isCompleted: Initial completion state.
    init(
        title: String = "",
        note: String = "",
        dueDate: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.title = title
        self.note = note
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = isCompleted ? Date() : nil
        self.createdAt = Date()
    }

    /// Preferred display title for UI presentation.
    ///
    /// - Returns: Trimmed title or a localized fallback.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("followup.untitled", "Untitled To-Do") : trimmed
    }
}
