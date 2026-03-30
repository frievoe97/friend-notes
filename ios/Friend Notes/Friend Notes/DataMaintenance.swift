import SwiftData

/// Provides data cleanup helpers used during destructive operations.
enum DataMaintenance {
    /// Removes a friend from all related meetings and deletes meetings that become orphaned.
    ///
    /// - Parameters:
    ///   - friend: The friend being removed.
    ///   - modelContext: The SwiftData context used to delete orphaned meeting records.
    ///
    /// - Important: This method mutates `Meeting.friends` and may delete meetings with no remaining participants.
    static func pruneMeetingsAfterRemoving(friend: Friend, in modelContext: ModelContext) {
        let friendID = friend.persistentModelID
        let relatedMeetings = friend.meetings

        for meeting in relatedMeetings {
            meeting.friends.removeAll { $0.persistentModelID == friendID }
            if meeting.friends.isEmpty {
                modelContext.delete(meeting)
            }
        }
    }
}
