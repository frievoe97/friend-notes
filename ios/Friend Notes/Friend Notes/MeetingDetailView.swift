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

/// Compact, searchable multi-select view for assigning friends.
private struct FriendMultiSelectView: View {
    let allFriends: [Friend]
    @Binding var selectedFriends: [Friend]
    let allowsCollapsing: Bool

    @State private var searchText = ""
    @State private var isShowingAll = false

    private let previewCount = 8

    init(
        allFriends: [Friend],
        selectedFriends: Binding<[Friend]>,
        allowsCollapsing: Bool = true
    ) {
        self.allFriends = allFriends
        self._selectedFriends = selectedFriends
        self.allowsCollapsing = allowsCollapsing
    }

    private var selectedFriendIDs: Set<PersistentIdentifier> {
        Set(selectedFriends.map(\.persistentModelID))
    }

    private var filteredFriends: [Friend] {
        let base: [Friend]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = allFriends
        } else {
            base = allFriends.filter { friend in
                friend.displayName.localizedCaseInsensitiveContains(searchText) ||
                friend.firstName.localizedCaseInsensitiveContains(searchText) ||
                friend.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return base.sorted {
            $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending
        }
    }

    private var visibleFriends: [Friend] {
        guard allowsCollapsing else { return filteredFriends }
        return isShowingAll ? filteredFriends : Array(filteredFriends.prefix(previewCount))
    }

    private var selectedFriendsSorted: [Friend] {
        selectedFriends.sorted {
            $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending
        }
    }

    var body: some View {
        if allFriends.isEmpty {
            Text(L10n.text("meeting.friends.empty", "Add friends first to include them in an event."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                selectedCountRow

                Text(L10n.text("meeting.friends.search", "Search friends"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .appGlassCard(cornerRadius: 12)
                .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    ForEach(visibleFriends) { friend in
                        let isSelected = selectedFriendIDs.contains(friend.persistentModelID)
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                toggle(friend)
                            }
                        } label: {
                            friendSelectionRow(friend: friend, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                if allowsCollapsing && filteredFriends.count > previewCount {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingAll.toggle()
                        }
                    } label: {
                        Label(
                            isShowingAll
                                ? L10n.text("meeting.friends.show_less", "Show fewer friends")
                                : L10n.text("meeting.friends.show_all", "Show all friends (%d)", filteredFriends.count),
                            systemImage: isShowingAll ? "chevron.up" : "chevron.down"
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Compact selected-count indicator shown above the selectable list.
    private var selectedCountRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(
                L10n.text(
                    "meeting.friends.selected_count",
                    "%d selected",
                    selectedFriendsSorted.count
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    /// Renders one selectable friend row in a calm, list-first style.
    ///
    /// - Parameters:
    ///   - friend: Friend displayed in the row.
    ///   - isSelected: Whether the friend is currently selected.
    /// - Returns: A stylized row with add/remove affordance.
    private func friendSelectionRow(friend: Friend, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: friend.displayName, size: 34)
            Text(friend.displayName)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                .foregroundStyle(
                    isSelected
                        ? AnyShapeStyle(AppTheme.accent)
                        : AnyShapeStyle(.secondary)
                )
                .font(.title3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? AppTheme.subtleFillSelected.opacity(0.42) : AppTheme.subtleFill.opacity(0.45))
        )
    }

    private func toggle(_ friend: Friend) {
        if selectedFriends.contains(where: { $0.persistentModelID == friend.persistentModelID }) {
            selectedFriends.removeAll { $0.persistentModelID == friend.persistentModelID }
        } else {
            selectedFriends.append(friend)
        }
    }
}

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

/// Reusable editor card used for meeting/event notes in create and edit flows.
private struct NoteEditorCard<Editor: View>: View {
    @Binding var text: String
    let minHeight: CGFloat
    @ViewBuilder let editor: () -> Editor

    var body: some View {
        editor()
            .frame(minHeight: minHeight, alignment: .topLeading)
            // TextEditor has an intrinsic inner inset; compensate so edit/view spacing matches.
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .scrollContentBackground(.hidden)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Reusable read-only card used for meeting/event notes in view mode.
private struct NoteReadCard: View {
    let text: String
    let emptyText: String
    let minHeight: CGFloat

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Text(trimmedText.isEmpty ? emptyText : text)
            .font(.body)
            .foregroundStyle(trimmedText.isEmpty ? .secondary : .primary)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Sheet containing a wheel date-time picker with 5-minute granularity.
private struct DateTimeWheelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    let title: String
    let range: ClosedRange<Date>?
    let onSave: (Date) -> Void

    init(
        title: String,
        initialDate: Date,
        range: ClosedRange<Date>? = nil,
        onSave: @escaping (Date) -> Void
    ) {
        self.title = title
        self.range = range
        self.onSave = onSave
        _selectedDate = State(
            initialValue: FiveMinuteDateTimePicker.roundedToFiveMinutes(initialDate)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: dateSelectionBinding,
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    DatePicker(
                        L10n.text("meeting.time", "Time"),
                        selection: timeSelectionBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "Save")) {
                        onSave(FiveMinuteDateTimePicker.roundedToFiveMinutes(selectedDate))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .appScreenBackground()
        .onChange(of: selectedDate) { _, newValue in
            let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(newValue)
            if abs(newValue.timeIntervalSince(rounded)) > 0.5 {
                selectedDate = rounded
            }
        }
    }

    private var dateRange: ClosedRange<Date> {
        range ?? (Date.distantPast...Date.distantFuture)
    }

    /// Binds only the date component while preserving the currently selected time component.
    private var dateSelectionBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                let cal = Calendar.current
                let time = cal.dateComponents([.hour, .minute], from: selectedDate)
                let day = cal.dateComponents([.year, .month, .day], from: newValue)
                let merged = DateComponents(
                    year: day.year,
                    month: day.month,
                    day: day.day,
                    hour: time.hour,
                    minute: time.minute
                )
                selectedDate = cal.date(from: merged) ?? newValue
            }
        )
    }

    /// Binds only the time component while preserving the currently selected date component.
    private var timeSelectionBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                let cal = Calendar.current
                let day = cal.dateComponents([.year, .month, .day], from: selectedDate)
                let time = cal.dateComponents([.hour, .minute], from: newValue)
                let merged = DateComponents(
                    year: day.year,
                    month: day.month,
                    day: day.day,
                    hour: time.hour,
                    minute: time.minute
                )
                selectedDate = cal.date(from: merged) ?? newValue
            }
        )
    }
}
