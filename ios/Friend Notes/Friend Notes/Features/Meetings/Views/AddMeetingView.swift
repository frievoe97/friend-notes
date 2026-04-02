import SwiftUI
import SwiftData

// MARK: - Add Meeting Sheet

/// Creates a new meeting with start/end date-time, participants, and notes.
struct AddMeetingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]

    let initialDate: Date

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var note = ""
    @State private var selectedFriends: [Friend] = []
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var showingFriendsPicker = false
    @FocusState private var focusedNote: Bool

    /// Initializes meeting creation state.
    init(initialDate: Date = Date(), preselectedFriends: [Friend] = []) {
        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(initialDate)
        self.initialDate = rounded
        _startDate = State(initialValue: rounded)
        _endDate = State(initialValue: rounded.addingTimeInterval(60 * 60))
        _selectedFriends = State(initialValue: Self.uniqueFriends(preselectedFriends))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
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
                    Color.clear.frame(height: focusedNote ? 124 : 0)
                }
                .onChange(of: focusedNote) { _, isFocused in
                    guard isFocused else { return }
                    scrollToNoteSection(proxy: proxy)
                }
                .navigationTitle(L10n.text("meeting.new.title", "New Meeting"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("common.save", "Save")) { save() }
                            .fontWeight(.semibold)
                            .disabled(selectedFriends.isEmpty)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(L10n.text("common.done", "Done")) {
                            focusedNote = false
                            Keyboard.dismiss()
                        }
                    }
                }
                .onChange(of: startDate) { _, newStart in
                    if endDate < newStart {
                        endDate = newStart
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
                .sheet(isPresented: $showingEndPicker) {
                    DateTimeWheelPickerSheet(
                        title: L10n.text("meeting.end", "End"),
                        initialDate: endDate,
                        range: startDate...Date.distantFuture
                    ) { selectedDate in
                        endDate = max(selectedDate, startDate)
                    }
                }
                .sheet(isPresented: $showingFriendsPicker) {
                    addFriendsSheet
                }
            }
        }
        .appScreenBackground()
    }

    /// Start/end picker section constrained to 5-minute steps.
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("meeting.section.start_end", "Start / End"), icon: "calendar")
            dateValueRow(label: L10n.text("meeting.start", "Start"), value: startDate)
                .contentShape(Rectangle())
                .onTapGesture { showingStartPicker = true }
            dateValueRow(label: L10n.text("meeting.end", "End"), value: endDate)
                .contentShape(Rectangle())
                .onTapGesture { showingEndPicker = true }
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
                    .focused($focusedNote)
                    .textInputAutocapitalization(.sentences)
            }
            .padding(.horizontal, 24)
        }
        .id(noteSectionScrollID)
    }

    /// Persists the newly created meeting.
    private func save() {
        guard !selectedFriends.isEmpty else { return }
        modelContext.insert(
            Meeting(
                eventTitle: "",
                startDate: startDate,
                endDate: max(endDate, startDate),
                note: note,
                kind: .meeting,
                friends: selectedFriends
            )
        )
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save meeting: \(error)")
        }
        dismiss()
    }

    /// Stable scroll anchor ID used to keep the focused note visible above the keyboard.
    private var noteSectionScrollID: String {
        "add-meeting-note-section"
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
