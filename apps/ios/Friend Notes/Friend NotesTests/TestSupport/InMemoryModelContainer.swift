import SwiftData
@testable import Friend_Notes

/// Bundles an in-memory SwiftData container with its main context.
///
/// Holding this value in tests keeps the underlying container alive for the
/// full test scope, which prevents crashes when saving through the context.
struct InMemoryTestStore {
    let container: ModelContainer
    let context: ModelContext
}

enum InMemoryModelContainer {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Friend.self,
            Meeting.self,
            GiftIdea.self,
            FriendEntry.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func makeStore() throws -> InMemoryTestStore {
        let container = try makeContainer()
        return InMemoryTestStore(container: container, context: container.mainContext)
    }
}
