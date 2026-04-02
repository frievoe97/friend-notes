import XCTest
@testable import Friend_Notes

final class FriendModelTests: XCTestCase {
    func testDisplayNamePrefersNicknameWhenAvailable() {
        let friend = Friend(firstName: "Alex", lastName: "Taylor", nickname: "Lex")

        XCTAssertEqual(friend.displayName, "Lex")
    }

    func testDisplayNameFallsBackToFullNameWhenNicknameIsEmpty() {
        let friend = Friend(firstName: "Alex", lastName: "Taylor", nickname: "  ")

        XCTAssertEqual(friend.displayName, "Alex Taylor")
    }

    func testDisplayNameFallsBackToLocalizedUnnamedWhenNoNameDataExists() {
        let friend = Friend(firstName: "  ", lastName: "\n", nickname: "")

        XCTAssertEqual(friend.displayName, L10n.text("friend.unnamed", "Unnamed"))
    }

    func testSortNameUsesLastNameThenFirstName() {
        let friend = Friend(firstName: "Alex", lastName: "Taylor")

        XCTAssertEqual(friend.sortName, "Taylor Alex")
    }

    func testSortNameFallsBackToDisplayNameWhenFirstAndLastNameAreEmpty() {
        let friend = Friend(firstName: "", lastName: "", nickname: "Lex")

        XCTAssertEqual(friend.sortName, "Lex")
    }

    func testEntryListSortsByOrderThenCreationDate() {
        let friend = Friend(firstName: "Alex")

        let sameOrderNewer = FriendEntry(title: "Newer", note: "", category: "notes", order: 1)
        sameOrderNewer.createdAt = Date(timeIntervalSince1970: 2_000)

        let lowerOrder = FriendEntry(title: "First", note: "", category: "notes", order: 0)
        lowerOrder.createdAt = Date(timeIntervalSince1970: 3_000)

        let sameOrderOlder = FriendEntry(title: "Older", note: "", category: "notes", order: 1)
        sameOrderOlder.createdAt = Date(timeIntervalSince1970: 1_000)

        friend.entries = [sameOrderNewer, lowerOrder, sameOrderOlder]

        let sorted = friend.entryList(for: "notes")

        XCTAssertEqual(sorted.map(\.title), ["First", "Older", "Newer"])
    }

    func testEntryListFiltersByCategory() {
        let friend = Friend(firstName: "Alex")

        let hobby = FriendEntry(title: "Running", note: "", category: "hobbies", order: 0)
        let note = FriendEntry(title: "Remember gift idea", note: "", category: "notes", order: 0)

        friend.entries = [hobby, note]

        let hobbies = friend.entryList(for: "hobbies")

        XCTAssertEqual(hobbies.count, 1)
        XCTAssertEqual(hobbies.first?.title, "Running")
    }

    func testLatestNoteReturnsMostRecentNoteTitle() {
        let friend = Friend(firstName: "Alex")

        let oldNote = FriendEntry(title: "Old", note: "", category: "notes", order: 0)
        oldNote.createdAt = Date(timeIntervalSince1970: 100)

        let newNote = FriendEntry(title: "New", note: "", category: "notes", order: 1)
        newNote.createdAt = Date(timeIntervalSince1970: 200)

        friend.entries = [oldNote, newNote]

        XCTAssertEqual(friend.latestNote, "New")
    }

    func testLatestNoteIgnoresEntriesFromOtherCategories() {
        let friend = Friend(firstName: "Alex")

        let hobby = FriendEntry(title: "Bouldering", note: "", category: "hobbies", order: 0)
        hobby.createdAt = Date(timeIntervalSince1970: 1_000)

        friend.entries = [hobby]

        XCTAssertNil(friend.latestNote)
    }
}
