import SwiftUI
import SwiftData

// MARK: - Add Event Sheet

/// Creates a new event with title and single start date-time.
struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]

    let initialDate: Date

    @State private var startDate: Date
    @State private var eventTitle = ""
    @State private var note = ""
    @State private var selectedFriends: [Friend] = []
    @State private var showingStartPicker = false
    @State private var showingFriendsPicker = false
    @FocusState private var focusedField: Field?

    /// Focus targets for event creation inputs.
    private enum Field {
        case eventTitle
        case note
    }

    /// Initializes event creation state.
    init(initialDate: Date = Date(), preselectedFriends: [Friend] = []) {
        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(initialDate)
        self.initialDate = rounded
        _startDate = State(initialValue: rounded)
        _selectedFriends = State(initialValue: Self.uniqueFriends(preselectedFriends))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        eventTitleSection
                        Divider().padding(.horizontal, 24)
                        dateSection
                        Divider().padding(.horizontal, 24)
                        friendsSection
                        Divider().padding(.horizontal, 24)
                        noteSection
                    }
                    .padding(.bottom, 40)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: focusedField == .note ? 124 : 0)
                }
                .onChange(of: focusedField) { _, newValue in
                    guard newValue == .note else { return }
                    scrollToNoteSection(proxy: proxy)
                }
                .navigationTitle(sheetTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("common.save", "Save")) { save() }
                            .fontWeight(.semibold)
                            .disabled(eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedFriends.isEmpty)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(L10n.text("common.done", "Done")) {
                            focusedField = nil
                            Keyboard.dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingStartPicker) {
                    DateTimeWheelPickerSheet(
                        title: L10n.text("meeting.start", "Start"),
                        initialDate: startDate
                    ) { selectedDate in
                        startDate = selectedDate
                    }
                }
                .sheet(isPresented: $showingFriendsPicker) {
                    addFriendsSheet
                }
            }
        }
        .appScreenBackground()
    }

    /// Dynamic sheet title that mirrors the typed event title.
    private var sheetTitle: String {
        let trimmed = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("event.new.title", "New Event") : trimmed
    }

    /// Event title input section.
    private var eventTitleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("event.title.short", "Title"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            TextField("", text: $eventTitle)
                .textFieldStyle(.plain)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)
                .textInputAutocapitalization(.sentences)
                .focused($focusedField, equals: .eventTitle)
                .submitLabel(.next)
                .onSubmit { focusedField = .note }
        }
    }

    /// Start picker section constrained to 5-minute steps.
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("meeting.start", "Start"), icon: "calendar")
            dateValueRow(label: L10n.text("meeting.start", "Start"), value: startDate)
                .contentShape(Rectangle())
                .onTapGesture { showingStartPicker = true }
        }
    }

    /// Participant selection section.
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("meeting.section.friends", "Friends"), icon: "person.2.fill")

            if selectedFriendsSorted.isEmpty {
                Text(L10n.text("meeting.friends.none", "No friends assigned."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                addFriendAvatarButton
                    .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(selectedFriendsSorted) { friend in
                            VStack(spacing: 6) {
                                AvatarView(name: friend.displayName, size: 48)
                                Text(friend.displayName)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 64)
                            }
                            .padding(.top, 6)
                        }
                        addFriendAvatarButton
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 86)
            }

        }
    }

    /// Optional note section.
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("meeting.section.note", "Note"), icon: "note.text")
            NoteEditorCard(
                text: $note,
                minHeight: 132
            ) {
                TextEditor(text: $note)
                    .font(.body)
                    .focused($focusedField, equals: .note)
                    .textInputAutocapitalization(.sentences)
            }
            .padding(.horizontal, 24)
        }
        .id(noteSectionScrollID)
    }

    /// Persists the newly created event.
    private func save() {
        let trimmedTitle = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard !selectedFriends.isEmpty else { return }

        modelContext.insert(
            Meeting(
                eventTitle: trimmedTitle,
                startDate: startDate,
                endDate: startDate,
                note: note,
                kind: .event,
                friends: selectedFriends
            )
        )
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save event: \(error)")
        }
        dismiss()
    }

    /// Stable scroll anchor ID used to keep the focused note visible above the keyboard.
    private var noteSectionScrollID: String {
        "add-event-note-section"
    }

    /// Scrolls to the notes section after focus changes.
    private func scrollToNoteSection(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(noteSectionScrollID, anchor: .bottom)
            }
        }
    }

    /// Stable alphabetical selection for avatar-strip rendering.
    private var selectedFriendsSorted: [Friend] {
        selectedFriends.sorted {
            $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending
        }
    }

    /// Removes duplicate friend references while preserving first-seen order.
    private static func uniqueFriends(_ friends: [Friend]) -> [Friend] {
        var seen = Set<PersistentIdentifier>()
        return friends.filter { seen.insert($0.persistentModelID).inserted }
    }

    /// Sheet for selecting meeting/event participants.
    private var addFriendsSheet: some View {
        NavigationStack {
            ScrollView {
                FriendMultiSelectView(
                    allFriends: allFriends,
                    selectedFriends: $selectedFriends,
                    allowsCollapsing: false
                )
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle(L10n.text("meeting.friends.edit_title", "Edit Friends"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.done", "Done")) {
                        showingFriendsPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .appScreenBackground()
    }

    /// Section title helper.
    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
    }

    /// Plus-avatar affordance that opens friend selection.
    private var addFriendAvatarButton: some View {
        Button {
            showingFriendsPicker = true
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.subtleFill)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .frame(width: 64)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Renders one read-only date row used as a tappable picker trigger.
    private func dateValueRow(label: String, value: Date) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Text(value.formatted(date: .abbreviated, time: .shortened))
                .font(.body)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}
