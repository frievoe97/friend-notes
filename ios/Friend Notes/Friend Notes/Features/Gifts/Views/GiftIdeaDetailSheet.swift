import SwiftUI
import SwiftData

/// Gift detail sheet that starts in read mode and switches to edit mode on demand.
struct GiftIdeaDetailSheet: View {
    /// Uses environment dismissal for close/delete flows.
    @Environment(\.dismiss) private var dismiss
    /// SwiftData context used for destructive delete persistence.
    @Environment(\.modelContext) private var modelContext
    /// Friend list used to resolve assignee edits.
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]
    /// Bound persisted gift idea displayed and edited by this sheet.
    @Bindable var idea: GiftIdea

    /// Enables assignee editing when the sheet is used from global gift contexts.
    let allowsAssigneeEditing: Bool

    /// Local mode state to switch between read and edit presentation.
    @State private var mode: Mode = .view
    /// Local title draft to isolate edits until save.
    @State private var draftTitle: String
    /// Local note draft to isolate edits until save.
    @State private var draftNote: String
    /// Local URL draft to isolate edits until save.
    @State private var draftURL: String
    /// Local gifted flag draft to isolate edits until save.
    @State private var draftIsGifted: Bool
    /// Local assignee selection draft represented by persistent identifier.
    @State private var selectedFriendID: PersistentIdentifier?
    /// Controls assignee picker presentation in edit mode.
    @State private var showingAssigneePicker = false
    /// Controls destructive delete confirmation.
    @State private var showingDeleteAlert = false
    /// Holds the URL opened in the in-app browser sheet.
    @State private var browserURL: URL?
    /// Tracks keyboard focus for title/url/note input flow.
    @FocusState private var focusedField: Field?

    private enum Mode {
        case view
        case edit
    }

    private enum Field {
        case title
        case url
        case note
    }

    /// Shared minimum height used by multiline note cards across read/edit modes.
    private let noteCardMinHeight: CGFloat = 120

    /// Creates a detail sheet backed by one persisted idea.
    ///
    /// - Parameters:
    ///   - idea: Persisted gift idea displayed by this sheet.
    ///   - allowsAssigneeEditing: Controls whether assignee editing UI is shown.
    /// - Note: Draft state is seeded from `idea` so cancel can fully revert edit mode.
    init(idea: GiftIdea, allowsAssigneeEditing: Bool = true) {
        self.idea = idea
        self.allowsAssigneeEditing = allowsAssigneeEditing
        _draftTitle = State(initialValue: idea.title)
        _draftNote = State(initialValue: idea.note)
        _draftURL = State(initialValue: idea.url)
        _draftIsGifted = State(initialValue: idea.isGifted)
        _selectedFriendID = State(initialValue: idea.friend?.persistentModelID)
    }

    /// Indicates whether editable form controls should be shown.
    private var isEditing: Bool {
        mode == .edit
    }

    /// Resolves the currently selected assignee draft to a full friend model.
    private var selectedFriend: Friend? {
        guard let selectedFriendID else { return nil }
        return allFriends.first(where: { $0.persistentModelID == selectedFriendID })
    }

    /// Navigation title derived from current mode-specific title source.
    private var titleForNavigation: String {
        let source = isEditing ? draftTitle : idea.title
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("gift.new.title", "New Gift Idea") : trimmed
    }

    /// Enables save only when the required title is non-empty.
    private var canSave: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isEditing {
                        editableContent
                    } else {
                        readOnlyContent
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(titleForNavigation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .appScreenBackground()
        .sheet(isPresented: $showingAssigneePicker) {
            GiftAssigneePickerSheet(
                allFriends: allFriends,
                selectedFriendID: $selectedFriendID
            )
        }
        .sheet(
            isPresented: Binding(
                get: { browserURL != nil },
                set: { if !$0 { browserURL = nil } }
            )
        ) {
            if let browserURL {
                InAppBrowserView(url: browserURL)
                    .ignoresSafeArea()
            }
        }
        .alert(L10n.text("gift.delete.title", "Delete Gift Idea?"), isPresented: $showingDeleteAlert) {
            Button(L10n.text("common.delete", "Delete"), role: .destructive) {
                deleteIdea()
            }
            Button(L10n.text("common.cancel", "Cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("common.delete_irreversible", "This action cannot be undone."))
        }
    }

    @ViewBuilder
    /// Renders read-only card content for view mode.
    private var readOnlyContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(L10n.text("gift.name", "Name"))
            readOnlyRow(value: idea.title)
        }

        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(L10n.text("gift.url", "URL"))
            readOnlyURLRow(rawURL: idea.url)
        }

        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(L10n.text("gift.note", "Note"))
            readOnlyMultilineRow(value: idea.note.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if allowsAssigneeEditing {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel(L10n.text("gifts.assignee.label", "Person"))
                readOnlyAssigneeRow
            }
        }
    }

    @ViewBuilder
    /// Renders editable form controls for edit mode.
    private var editableContent: some View {
        let canClearTitle = !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(L10n.text("gift.name", "Name"))
            HStack(spacing: 8) {
                TextField("", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .url }

                Button {
                    draftTitle = ""
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
                .frame(minHeight: 48)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        let canClearURL = !draftURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(L10n.text("gift.url", "URL"))
            HStack(spacing: 8) {
                TextField("", text: $draftURL)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .note }

                Button {
                    draftURL = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("gift.url.clear", "Clear URL"))
                .opacity(canClearURL ? 1 : 0)
                .disabled(!canClearURL)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        let canClearNote = !draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(L10n.text("gift.note", "Note"))
            HStack(alignment: .top, spacing: 8) {
                TextField("", text: $draftNote, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(4...)
                    .focused($focusedField, equals: .note)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    draftNote = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("common.clear", "Clear"))
                .opacity(canClearNote ? 1 : 0)
                .disabled(!canClearNote)
            }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: noteCardMinHeight, alignment: .topLeading)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        if allowsAssigneeEditing {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel(L10n.text("gifts.assignee.label", "Person"))
                assignmentMenu
            }
        }

        Toggle(L10n.text("gift.already_gifted", "Already gifted"), isOn: $draftIsGifted)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label(L10n.text("gift.delete.button", "Delete Gift Idea"), systemImage: "trash")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    /// Builds toolbar actions for view and edit modes.
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("common.cancel", "Cancel")) {
                    cancelEditing()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.text("common.save", "Save")) {
                    saveChanges()
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.text("common.done", "Done")) {
                    focusedField = nil
                    Keyboard.dismiss()
                }
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("common.close", "Close")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    beginEditing()
                } label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel(L10n.text("common.edit", "Edit"))
            }
        }
    }

    /// Enters edit mode and refreshes drafts from persisted model values.
    ///
    /// - Side Effects: Mutates local draft state and presentation mode.
    private func beginEditing() {
        draftTitle = idea.title
        draftNote = idea.note
        draftURL = idea.url
        draftIsGifted = idea.isGifted
        selectedFriendID = idea.friend?.persistentModelID
        mode = .edit
    }

    /// Leaves edit mode without persisting draft changes.
    ///
    /// - Side Effects: Resets drafts, clears keyboard focus, and dismisses keyboard.
    private func cancelEditing() {
        draftTitle = idea.title
        draftNote = idea.note
        draftURL = idea.url
        draftIsGifted = idea.isGifted
        selectedFriendID = idea.friend?.persistentModelID
        focusedField = nil
        Keyboard.dismiss()
        mode = .view
    }

    /// Persists current drafts into the bound model and returns to view mode.
    ///
    /// - Important: Mutates persisted `idea` fields directly via `@Bindable`.
    private func saveChanges() {
        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        idea.title = trimmedTitle
        idea.note = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        idea.url = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        idea.isGifted = draftIsGifted

        if allowsAssigneeEditing {
            idea.friend = allFriends.first(where: { $0.persistentModelID == selectedFriendID })
        }

        focusedField = nil
        Keyboard.dismiss()
        mode = .view
    }

    /// Deletes the bound gift idea from SwiftData and dismisses the sheet.
    ///
    /// - Side Effects: Removes persisted data and triggers context save.
    private func deleteIdea() {
        focusedField = nil
        Keyboard.dismiss()
        modelContext.delete(idea)
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not delete gift idea: \(error)")
        }
        dismiss()
    }

    /// Applies shared field-label styling.
    ///
    /// - Parameter text: Label text rendered above a card.
    /// - Returns: Styled label view.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    /// Renders a single-line read-only value card.
    ///
    /// - Parameter value: Value to display.
    /// - Returns: Read-only card with placeholder dash when empty.
    private func readOnlyRow(value: String) -> some View {
        Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "–" : value)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Renders a multiline read-only card for note content.
    ///
    /// - Parameter value: Trimmed note value.
    /// - Returns: Multiline card with placeholder dash when empty.
    private func readOnlyMultilineRow(value: String) -> some View {
        Text(value.isEmpty ? "–" : value)
            .font(.body)
            .foregroundStyle(value.isEmpty ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: noteCardMinHeight, alignment: .topLeading)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    /// Renders URL content as a tappable in-app browser action when valid.
    ///
    /// - Parameter rawURL: Raw URL text stored on the idea.
    private func readOnlyURLRow(rawURL: String) -> some View {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedURL = normalizedURL(from: trimmed)

        VStack(alignment: .leading, spacing: 0) {
            if let resolvedURL, !trimmed.isEmpty {
                Button {
                    browserURL = resolvedURL
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.caption.weight(.semibold))
                        Text(trimmed)
                            .font(.body)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 8)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            } else {
                Text(trimmed.isEmpty ? "–" : trimmed)
                    .font(.body)
                    .foregroundStyle(trimmed.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Read-only assignee card used in view mode.
    private var readOnlyAssigneeRow: some View {
        HStack(spacing: 10) {
            if let friend = idea.friend {
                AvatarView(name: friend.displayName, size: 28)
                Text(friend.displayName)
                    .foregroundStyle(.primary)
            } else {
                Circle()
                    .fill(AppTheme.subtleFillSelected)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                Text(L10n.text("gifts.assignee.none", "No person assigned"))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Editable assignee selector used in edit mode.
    private var assignmentMenu: some View {
        Button {
            showingAssigneePicker = true
        } label: {
            HStack(spacing: 10) {
                if let selectedFriend {
                    AvatarView(name: selectedFriend.displayName, size: 28)
                } else {
                    Circle()
                        .fill(AppTheme.subtleFillSelected)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                }
                Text(selectedFriend?.displayName ?? L10n.text("gifts.assignee.none", "No person assigned"))
                    .foregroundStyle(selectedFriend == nil ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Normalizes raw URL text into a browser-openable URL.
    ///
    /// - Parameter rawValue: Raw user-provided URL string.
    /// - Returns: URL with existing scheme preserved, or `https://` prepended when missing.
    private func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }

        return URL(string: "https://\(trimmed)")
    }
}
