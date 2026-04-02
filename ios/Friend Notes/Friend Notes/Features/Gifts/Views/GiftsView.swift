import SwiftUI
import SwiftData

/// Global gift hub listing all gift ideas across the app.
struct GiftsView: View {
    /// SwiftData context used for delete operations triggered from list rows.
    @Environment(\.modelContext) private var modelContext
    /// Live query of all gift ideas, used as source data for search and sections.
    @Query(sort: [SortDescriptor(\GiftIdea.createdAt, order: .reverse)]) private var giftIdeas: [GiftIdea]

    /// Presents the global add-gift sheet.
    @State private var showingAddGiftIdea = false
    /// Holds the selected gift idea for detail-sheet presentation.
    @State private var selectedGiftIdea: GiftIdea?
    /// Controls expansion of the completed section in non-search mode.
    @State private var isGiftedExpanded = false
    /// Controls expansion of the open section preview in non-search mode.
    @State private var showAllOpen = false
    /// Search query bound to the native `.searchable` field.
    @State private var searchText = ""

    /// Maximum number of open ideas shown before "show all" expands the section.
    private let openPreviewLimit = 5

    /// Bridges optional selected idea state to boolean sheet presentation.
    private var detailSheetBinding: Binding<Bool> {
        Binding(
            get: { selectedGiftIdea != nil },
            set: { if !$0 { selectedGiftIdea = nil } }
        )
    }

    /// Deterministic ordering used as base for sectioning and search output.
    private var sortedIdeas: [GiftIdea] {
        giftIdeas.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    /// Search text normalized for empty checks and matching.
    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Indicates whether the user currently filters the list via search.
    private var isSearching: Bool {
        !trimmedSearchText.isEmpty
    }

    /// Search-filtered ideas using title, note, URL, and assignee name.
    private var filteredIdeas: [GiftIdea] {
        guard isSearching else { return sortedIdeas }
        return sortedIdeas.filter { idea in
            let query = trimmedSearchText.localizedLowercase
            let titleMatch = idea.title.localizedLowercase.contains(query)
            let noteMatch = idea.note.localizedLowercase.contains(query)
            let friendMatch = (idea.friend?.displayName.localizedLowercase.contains(query) ?? false)
            let urlMatch = idea.url.localizedLowercase.contains(query)
            return titleMatch || noteMatch || friendMatch || urlMatch
        }
    }

    /// Non-gifted subset used by the open section.
    private var openIdeas: [GiftIdea] { filteredIdeas.filter { !$0.isGifted } }
    /// Gifted subset used by the completed section.
    private var giftedIdeas: [GiftIdea] { filteredIdeas.filter(\.isGifted) }

    /// Open ideas currently visible after preview/expand logic.
    private var visibleOpenIdeas: [GiftIdea] {
        (showAllOpen || isSearching) ? openIdeas : Array(openIdeas.prefix(openPreviewLimit))
    }

    /// Effective expansion state for completed ideas.
    ///
    /// - Note: Search mode always shows all matching completed items.
    private var giftedExpandedForDisplay: Bool {
        isSearching || isGiftedExpanded
    }

    var body: some View {
        NavigationStack {
            giftList
            .navigationTitle(L10n.text("gifts.title", "Gifts"))
            .navigationBarTitleDisplayMode(.large)
            .background {
                AppGradientBackground()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddGiftIdea = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGlobalGiftIdeaSheet()
        }
        .sheet(isPresented: detailSheetBinding) {
            if let idea = selectedGiftIdea {
                GiftIdeaDetailSheet(idea: idea, allowsAssigneeEditing: true)
            }
        }
    }

    /// Renders the searchable gift list and relevant empty states.
    private var giftList: some View {
        List {
            openSection
            giftedSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: L10n.text("gifts.search.placeholder", "Search gifts, notes, or people"))
        .overlay {
            if giftIdeas.isEmpty {
                ContentUnavailableView {
                    Label(
                        L10n.text("gifts.title", "Gifts"),
                        systemImage: "gift.fill"
                    )
                } description: {
                    Text(L10n.text("friend.gifts.empty", "No gift ideas yet."))
                }
            } else if isSearching && filteredIdeas.isEmpty {
                ContentUnavailableView.search(text: trimmedSearchText)
            }
        }
    }

    @ViewBuilder
    /// Renders open ideas with optional preview expansion controls.
    private var openSection: some View {
        if !openIdeas.isEmpty {
            Section(L10n.text("statistics.gifts.open", "Open")) {
                ForEach(visibleOpenIdeas) { idea in
                    giftRow(idea)
                        .listRowBackground(AppTheme.subtleFill)
                }
                .onDelete { offsets in
                    offsets.map { visibleOpenIdeas[$0] }.forEach { modelContext.delete($0) }
                }

                if openIdeas.count > openPreviewLimit && !isSearching {
                    if !showAllOpen {
                        Button {
                            withAnimation { showAllOpen = true }
                        } label: {
                            Text(L10n.text("friend.gifts.open.show_all", "Show all gift ideas (%d)", openIdeas.count))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.subtleFill)
                    } else {
                        Button {
                            withAnimation { showAllOpen = false }
                        } label: {
                            Text(L10n.text("friend.gifts.open.show_less", "Show fewer gift ideas"))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.subtleFill)
                    }
                }
            }
        }
    }

    @ViewBuilder
    /// Renders completed ideas with collapsible behavior outside search mode.
    private var giftedSection: some View {
        if !giftedIdeas.isEmpty {
            Section {
                if giftedExpandedForDisplay {
                    ForEach(giftedIdeas) { idea in
                        giftRow(idea)
                            .listRowBackground(AppTheme.subtleFill)
                    }
                    .onDelete { offsets in
                        offsets.map { giftedIdeas[$0] }.forEach { modelContext.delete($0) }
                    }
                }
            } header: {
                Button {
                    guard !isSearching else { return }
                    withAnimation { isGiftedExpanded.toggle() }
                } label: {
                    HStack {
                        Text(L10n.text("friend.gifts.gifted.section", "Completed"))
                        Spacer()
                        Image(systemName: giftedExpandedForDisplay ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    /// Renders one gift row with completion toggle and detail navigation.
    ///
    /// - Parameter idea: Gift idea displayed in the list.
    private func giftRow(_ idea: GiftIdea) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    idea.isGifted.toggle()
                }
            } label: {
                Image(systemName: idea.isGifted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        idea.isGifted
                            ? AnyShapeStyle(AppTheme.accent)
                            : AnyShapeStyle(.tertiary)
                    )
                    .font(.title3)
                    .frame(width: 22)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.body)
                    .strikethrough(idea.isGifted)
                    .foregroundStyle(idea.isGifted ? .secondary : .primary)
                    .multilineTextAlignment(.leading)

                if !idea.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(idea.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                let trimmedURL = idea.url.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedURL.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(trimmedURL)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Text(idea.friend?.displayName ?? L10n.text("gifts.assignee.none", "No person assigned"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { selectedGiftIdea = idea }
    }
}

/// Sheet used to create a new global gift idea with optional friend assignment.
private struct AddGlobalGiftIdeaSheet: View {
    /// Uses environment dismissal after save or cancel.
    @Environment(\.dismiss) private var dismiss
    /// SwiftData context used for insert and explicit save.
    @Environment(\.modelContext) private var modelContext
    /// Friend list used for optional assignee selection.
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]

    /// Local required title draft.
    @State private var title = ""
    /// Local optional note draft.
    @State private var note = ""
    /// Local optional URL draft.
    @State private var url = ""
    /// Selected optional assignee represented by persistent identifier.
    @State private var selectedFriendID: PersistentIdentifier?
    /// Controls assignee picker sheet presentation.
    @State private var showingAssigneePicker = false
    /// Tracks keyboard focus to support next/done field flow.
    @FocusState private var focusedField: Field?

    /// Focus targets for keyboard navigation.
    private enum Field {
        case title
        case url
        case note
    }

    /// Resolves the selected friend from persisted identifier state.
    private var selectedFriend: Friend? {
        guard let selectedFriendID else { return nil }
        return allFriends.first(where: { $0.persistentModelID == selectedFriendID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.name", "Name"))
                        TextField("", text: $title)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .url }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.url", "URL"))
                        TextField("", text: $url)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .url)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .note }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.note", "Note"))
                        TextField("", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(4...)
                            .focused($focusedField, equals: .note)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gifts.assignee.label", "Person"))
                        assignmentMenu
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(L10n.text("gift.new.title", "New Gift Idea"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "Save")) {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L10n.text("common.done", "Done")) {
                        focusedField = nil
                        Keyboard.dismiss()
                    }
                }
            }
        }
        .appScreenBackground()
        .sheet(isPresented: $showingAssigneePicker) {
            GiftAssigneePickerSheet(
                allFriends: allFriends,
                selectedFriendID: $selectedFriendID
            )
        }
    }

    /// Applies shared field-label styling for the form.
    ///
    /// - Parameter text: Label text rendered above an input.
    /// - Returns: Styled label view.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    /// Opens a picker that assigns one friend or leaves the gift unassigned.
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

    /// Persists a new global gift idea and optionally links it to a friend.
    ///
    /// - Important: This method inserts into `modelContext` and performs an explicit `save()`.
    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let idea = GiftIdea(
            title: trimmedTitle,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        idea.friend = selectedFriend
        modelContext.insert(idea)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save gift idea: \(error)")
        }

        dismiss()
    }
}
