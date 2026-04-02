import SwiftUI
import SwiftData

// MARK: - Entry List Sub-Page (Hobbies, Food, Music, Movies, Notes)

/// Sub-page listing entries for a single category (e.g. hobbies, food).
struct FriendEntryListView: View {
    /// Bound friend model that owns the displayed category entries.
    @Bindable var friend: Friend
    /// SwiftData context used for inserts and deletes triggered by this screen.
    @Environment(\.modelContext) private var modelContext

    /// Localized navigation title for this category.
    let title: String
    /// SF Symbol used by the empty state.
    let icon: String
    /// Persisted category key used for filtering and creation.
    let category: String
    /// Category-specific placeholder passed to the add sheet.
    let addPlaceholder: String

    /// Controls presentation of the add-entry sheet.
    @State private var showingAdd = false
    /// Holds the currently selected entry for edit sheet presentation.
    @State private var editingEntry: FriendEntry?

    /// Bridges optional `editingEntry` state to boolean sheet presentation.
    private var editingBinding: Binding<Bool> {
        Binding(get: { editingEntry != nil }, set: { if !$0 { editingEntry = nil } })
    }

    /// Entries for the active category, sorted via model helper.
    private var entries: [FriendEntry] {
        friend.entryList(for: category)
    }

    var body: some View {
        entryList
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel(L10n.text("common.add", "Add"))
            }
        }
        .appScreenBackground()
        .sheet(isPresented: $showingAdd) {
            AddFriendEntrySheet(placeholder: addPlaceholder) { entryTitle, note in
                addEntry(title: entryTitle, note: note)
            }
        }
        .sheet(isPresented: editingBinding) {
            if let entry = editingEntry {
                EditFriendEntrySheet(entry: entry)
            }
        }
    }

    /// Renders the grouped list with empty-state fallback.
    ///
    /// - Note: Delete actions remove persisted entries from the current model context.
    private var entryList: some View {
        List {
            if !entries.isEmpty {
                Section {
                    ForEach(entries) { entry in
                        entryRow(entry)
                            .listRowBackground(AppTheme.subtleFill)
                    }
                    .onDelete { offsets in
                        offsets.map { entries[$0] }.forEach { modelContext.delete($0) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    title,
                    systemImage: icon,
                    description: Text(L10n.text("list.detail.empty", "Tap + to add an entry."))
                )
            }
        }
    }

    /// Renders one tappable entry row.
    ///
    /// - Parameter entry: Entry displayed in the row.
    /// - Returns: Row view that opens edit mode when tapped.
    private func entryRow(_ entry: FriendEntry) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { editingEntry = entry }
    }

    /// Creates and links a new entry to the bound friend.
    ///
    /// - Parameters:
    ///   - title: Raw title input from the add sheet.
    ///   - note: Raw optional note input.
    /// - Important: Mutates `friend.entries` and inserts into `modelContext`.
    private func addEntry(title: String, note: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = FriendEntry(
            title: trimmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            order: entries.count
        )
        modelContext.insert(entry)
        friend.entries.append(entry)
    }
}
