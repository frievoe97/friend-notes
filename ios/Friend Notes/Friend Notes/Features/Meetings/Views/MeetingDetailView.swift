import SwiftUI
import SwiftData

// MARK: - Meeting/Event Detail

/// Presents an existing meeting or event in read mode and allows switching into edit mode.
struct MeetingDetailView: View {
    @Bindable var meeting: Meeting
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]

    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    @State private var meetingNoteDraft = ""
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var showingFriendsPicker = false
    @FocusState private var focusedField: Field?

    /// Focus targets for keyboard handling.
    private enum Field {
        case eventTitle
        case note
    }

    private var sortedSelectedFriends: [Friend] {
        meeting.friends.sorted {
            $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending
        }
    }

    /// Stable IDs used to react to selection changes and auto-scroll the avatar strip.
    private var sortedSelectedFriendIDs: [String] {
        sortedSelectedFriends.map { "\($0.persistentModelID)" }
    }

    var body: some View {
        screenContent
    }

    /// Fully configured detail screen with navigation and modal presentation behavior.
    private var screenContent: some View {
        scrollBody
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(meeting.displayTitle)
            .onAppear {
                normalizeEventDates()
                meetingNoteDraft = meeting.note
            }
            .onChange(of: meeting.startDate) { _, newStart in
                if meeting.kind == .event {
                    meeting.endDate = newStart
                } else if meeting.endDate < newStart {
                    meeting.endDate = newStart
                }
            }
            .onChange(of: meeting.note) { _, newValue in
                if newValue != meetingNoteDraft {
                    meetingNoteDraft = newValue
                }
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingStartPicker) {
                DateTimeWheelPickerSheet(
                    title: L10n.text("meeting.start", "Start"),
                    initialDate: meeting.startDate,
                    range: meeting.kind == .meeting ? Date.distantPast...meeting.endDate : nil
                ) { selectedDate in
                    meeting.startDate = selectedDate
                }
            }
            .sheet(isPresented: $showingEndPicker) {
                DateTimeWheelPickerSheet(
                    title: L10n.text("meeting.end", "End"),
                    initialDate: meeting.endDate,
                    range: meeting.startDate...Date.distantFuture
                ) { selectedDate in
                    meeting.endDate = max(selectedDate, meeting.startDate)
                }
            }
            .sheet(isPresented: $showingFriendsPicker) {
                editFriendsSheet
            }
            .alert(L10n.text("meeting.delete.title", "Delete %@?", meeting.kind.title), isPresented: $showingDeleteAlert) {
                Button(L10n.text("common.delete", "Delete"), role: .destructive) {
                    modelContext.delete(meeting)
                    dismiss()
                }
                Button(L10n.text("common.cancel", "Cancel"), role: .cancel) {}
            } message: {
                Text(L10n.text("common.delete_irreversible", "This action cannot be undone."))
            }
            .appScreenBackground()
    }

    /// Main scroll container for the detail sections.
    private var scrollBody: some View {
        ScrollViewReader { proxy in
            ScrollView {
                detailSections
                    .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: isEditing && focusedField == .note ? 124 : 0)
            }
            .onChange(of: focusedField) { _, newValue in
                guard newValue == .note else { return }
                scrollToNoteSection(proxy: proxy)
            }
        }
    }

    /// Vertical stack holding title/date/friends/note/delete sections.
    private var detailSections: some View {
        VStack(spacing: 28) {
            if meeting.kind == .event {
                eventTitleSection
                Divider().padding(.horizontal, 24)
            }
            dateSection
            friendsSection
            noteSection
            if isEditing {
                deleteButton
            }
        }
    }

    /// Toolbar content used in both read and edit mode.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(isEditing ? L10n.text("common.done", "Done") : L10n.text("common.edit", "Edit")) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditing.toggle()
                }
                if !isEditing {
                    focusedField = nil
                    Keyboard.dismiss()
                    showingStartPicker = false
                    showingEndPicker = false
                    showingFriendsPicker = false
                }
            }
            .fontWeight(.semibold)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(L10n.text("common.done", "Done")) {
                focusedField = nil
                Keyboard.dismiss()
            }
        }
    }

    /// Sheet for selecting meeting/event participants.
    private var editFriendsSheet: some View {
        NavigationStack {
            ScrollView {
                FriendMultiSelectView(
                    allFriends: allFriends,
                    selectedFriends: $meeting.friends,
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

    /// Shows or edits the event title for event entries.
    private var eventTitleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("event.title.short", "Title"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            if isEditing {
                let canClearTitle = !meeting.eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                HStack(spacing: 8) {
                    TextField("", text: $meeting.eventTitle)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .textInputAutocapitalization(.sentences)
                        .focused($focusedField, equals: .eventTitle)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .note }

                    Button {
                        meeting.eventTitle = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.text("common.clear", "Clear"))
                    .opacity(canClearTitle ? 1 : 0)
                    .disabled(!canClearTitle)
                }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 24)
            } else {
                Text(meeting.displayTitle)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Start/end date-time section using 5-minute increments.
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(
                meeting.kind == .meeting
                    ? L10n.text("meeting.section.start_end", "Start / End")
                    : L10n.text("meeting.start", "Start"),
                icon: "calendar"
            )

            VStack(spacing: 0) {
                dateValueRow(
                    label: L10n.text("meeting.start", "Start"),
                    value: meeting.startDate
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    guard isEditing else { return }
                    showingStartPicker = true
                }

                if meeting.kind == .meeting {
                    dateValueRow(
                        label: L10n.text("meeting.end", "End"),
                        value: meeting.endDate
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isEditing else { return }
                        showingEndPicker = true
                    }
                }
            }
        }
    }

    /// Friends section for viewing assigned participants or editing assignments.
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("meeting.section.friends", "Friends"), icon: "person.2.fill")

            if sortedSelectedFriends.isEmpty {
                Text(L10n.text("meeting.friends.none", "No friends assigned."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isEditing {
                    addFriendAvatarButton
                        .padding(.horizontal, 24)
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(sortedSelectedFriends) { friend in
                                Group {
                                    if isEditing {
                                        friendAvatarItem(friend)
                                    } else {
                                        NavigationLink(destination: FriendDetailView(friend: friend)) {
                                            friendAvatarItem(friend)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .id(friendAvatarID(for: friend))
                            }
                            if isEditing {
                                addFriendAvatarButton
                                    .id(addFriendAvatarScrollID)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 2)
                    }
                    .onAppear { scrollFriendsStripToTrailing(proxy: proxy) }
                    .onChange(of: sortedSelectedFriendIDs) { _, _ in
                        scrollFriendsStripToTrailing(proxy: proxy)
                    }
                    .onChange(of: isEditing) { _, _ in
                        scrollFriendsStripToTrailing(proxy: proxy)
                    }
                }
            }
        }
    }

    /// Note section for read or edit mode.
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("meeting.section.note", "Note"), icon: "note.text")
            if isEditing {
                NoteEditorCard(
                    text: $meetingNoteDraft,
                    minHeight: 132
                ) {
                    TextEditor(text: $meetingNoteDraft)
                        .font(.body)
                        .focused($focusedField, equals: .note)
                        .textInputAutocapitalization(.sentences)
                }
                .padding(.horizontal, 24)
                .onChange(of: meetingNoteDraft) { _, newValue in
                    meeting.note = newValue
                }
            } else {
                NoteReadCard(
                    text: meeting.note,
                    emptyText: L10n.text("meeting.note.empty", "No note yet."),
                    minHeight: 120
                )
                    .padding(.horizontal, 24)
            }
        }
        .id(noteSectionScrollID)
    }

    /// Destructive action shown only in edit mode.
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label(L10n.text("meeting.delete.button", "Delete %@", meeting.kind.title), systemImage: "trash")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .padding(.horizontal, 24)
    }

    /// Builds a standardized section title row.
    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
    }

    /// Renders one selectable participant row.
    private func friendPickerRow(_ friend: Friend, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: friend.displayName, size: 36)
            Text(friend.displayName)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(
                    isSelected
                        ? AnyShapeStyle(AppTheme.accent)
                        : AnyShapeStyle(.tertiary)
                )
                .font(.title3)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    /// Renders a read-only date row.
    private func dateValueRow(label: String, value: Date) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Text(value.formatted(date: .abbreviated, time: .shortened))
                .font(.body)
                .foregroundStyle(isEditing ? AppTheme.accent : .primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    /// Renders one participant avatar + name item in the horizontal list.
    private func friendAvatarItem(_ friend: Friend) -> some View {
        VStack(spacing: 6) {
            AvatarView(name: friend.displayName, size: 48)
            Text(friend.displayName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 64)
        }
        .padding(.top, 6)
    }

    /// Unique scroll anchor ID for the plus-avatar item.
    private var addFriendAvatarScrollID: String {
        "friends-add-avatar"
    }

    /// Returns a stable scroll ID for one friend avatar.
    private func friendAvatarID(for friend: Friend) -> String {
        "friend-avatar-\(friend.persistentModelID)"
    }

    /// Scrolls the horizontal avatar strip to its trailing edge so the latest item is visible.
    private func scrollFriendsStripToTrailing(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            let targetID = isEditing
                ? addFriendAvatarScrollID
                : sortedSelectedFriends.last.map(friendAvatarID(for:))
            guard let targetID else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(targetID, anchor: .trailing)
            }
        }
    }

    /// Plus-avatar affordance used in edit mode to open the friend picker sheet.
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

    /// Keeps event end date aligned with start date.
    private func normalizeEventDates() {
        if meeting.kind == .event {
            meeting.endDate = meeting.startDate
        }
    }

    /// Stable scroll anchor ID used to keep the focused note visible above the keyboard.
    private var noteSectionScrollID: String {
        "meeting-detail-note-section"
    }

    /// Scrolls to the notes section after focus changes.
    private func scrollToNoteSection(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(noteSectionScrollID, anchor: .bottom)
            }
        }
    }
}
