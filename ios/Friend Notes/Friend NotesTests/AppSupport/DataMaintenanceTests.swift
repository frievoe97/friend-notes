import SwiftData
import XCTest
@testable import Friend_Notes

@MainActor
final class DataMaintenanceTests: XCTestCase {
    func testPruneDeletesMeetingWhenRemovedFriendWasOnlyParticipant() throws {
        let store = try InMemoryModelContainer.makeStore()
        let context = store.context
        defer { withExtendedLifetime(store) {} }

        let removedFriend = Friend(firstName: "Alex")
        let orphanedMeeting = Meeting(kind: .meeting)

        context.insert(removedFriend)
        context.insert(orphanedMeeting)
        orphanedMeeting.friends = [removedFriend]
        try context.save()

        let orphanedMeetingID = orphanedMeeting.persistentModelID

        DataMaintenance.pruneMeetingsAfterRemoving(friend: removedFriend, in: context)
        try context.save()

        let meetings = try context.fetch(FetchDescriptor<Meeting>())
        XCTAssertFalse(meetings.contains(where: { $0.persistentModelID == orphanedMeetingID }))
    }

    func testPruneRemovesFriendFromSharedMeetingAndKeepsMeeting() throws {
        let store = try InMemoryModelContainer.makeStore()
        let context = store.context
        defer { withExtendedLifetime(store) {} }

        let removedFriend = Friend(firstName: "Alex")
        let retainedFriend = Friend(firstName: "Jamie")
        let sharedMeeting = Meeting(kind: .meeting)

        context.insert(removedFriend)
        context.insert(retainedFriend)
        context.insert(sharedMeeting)
        sharedMeeting.friends = [removedFriend, retainedFriend]
        try context.save()

        let sharedMeetingID = sharedMeeting.persistentModelID
        let retainedFriendID = retainedFriend.persistentModelID

        DataMaintenance.pruneMeetingsAfterRemoving(friend: removedFriend, in: context)
        try context.save()

        let meetings = try context.fetch(FetchDescriptor<Meeting>())
        let reloadedSharedMeeting = try XCTUnwrap(meetings.first(where: { $0.persistentModelID == sharedMeetingID }))

        XCTAssertEqual(reloadedSharedMeeting.friends.count, 1)
        XCTAssertEqual(reloadedSharedMeeting.friends.first?.persistentModelID, retainedFriendID)
    }

    func testPruneLeavesUnrelatedMeetingsUntouched() throws {
        let store = try InMemoryModelContainer.makeStore()
        let context = store.context
        defer { withExtendedLifetime(store) {} }

        let removedFriend = Friend(firstName: "Alex")
        let unrelatedFriend = Friend(firstName: "Casey")
        let unrelatedMeeting = Meeting(kind: .event)

        context.insert(removedFriend)
        context.insert(unrelatedFriend)
        context.insert(unrelatedMeeting)
        unrelatedMeeting.friends = [unrelatedFriend]
        try context.save()

        let unrelatedMeetingID = unrelatedMeeting.persistentModelID

        DataMaintenance.pruneMeetingsAfterRemoving(friend: removedFriend, in: context)
        try context.save()

        let meetings = try context.fetch(FetchDescriptor<Meeting>())
        XCTAssertTrue(meetings.contains(where: { $0.persistentModelID == unrelatedMeetingID }))
    }
}
