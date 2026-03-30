import Foundation
import SwiftData

/// Persisted gift suggestion linked to a specific friend.
@Model
final class GiftIdea {
    /// Gift idea title.
    var title: String
    /// Optional note or context for the gift.
    var note: String
    /// Whether this idea has already been gifted.
    var isGifted: Bool
    /// Creation timestamp.
    var createdAt: Date
    /// Back-reference to the owning friend.
    var friend: Friend?

    /// Creates a gift idea model.
    ///
    /// - Parameters:
    ///   - title: Idea title.
    ///   - note: Optional note.
    ///   - isGifted: Initial gifted state.
    init(title: String = "", note: String = "", isGifted: Bool = false) {
        self.title = title
        self.note = note
        self.isGifted = isGifted
        self.createdAt = Date()
    }
}
