import Foundation
import SwiftData

/// Persisted entry (hobby, food, music, movie, note) linked to a friend.
@Model
final class FriendEntry {
    var title: String
    var note: String
    /// One of: "hobbies", "foods", "musics", "moviesSeries", "notes"
    var category: String
    var order: Int
    var createdAt: Date
    var friend: Friend?

    init(title: String, note: String = "", category: String, order: Int = 0) {
        self.title = title
        self.note = note
        self.category = category
        self.order = order
        self.createdAt = Date()
    }
}
