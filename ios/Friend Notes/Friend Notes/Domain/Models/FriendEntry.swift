import Foundation
import SwiftData

/// Persisted entry (hobby, food, music, movie, note) linked to a friend.
@Model
final class FriendEntry {
    /// Short headline shown in list rows.
    var title: String
    /// Optional detail text shown under the title.
    var note: String
    /// Category key used to group entries (for example `hobbies` or `notes`).
    var category: String
    /// Stable order value inside one category.
    var order: Int
    /// Timestamp used for deterministic sorting when order values collide.
    var createdAt: Date
    /// Optional owning friend relationship.
    var friend: Friend?

    /// Creates a new friend entry.
    ///
    /// - Parameters:
    ///   - title: Entry title shown in lists.
    ///   - note: Optional supporting detail text.
    ///   - category: Category key used for grouping.
    ///   - order: Sort order within the category.
    /// - Note: `createdAt` is captured at initialization for tie-breaking sort behavior.
    init(title: String, note: String = "", category: String, order: Int = 0) {
        self.title = title
        self.note = note
        self.category = category
        self.order = order
        self.createdAt = Date()
    }
}
