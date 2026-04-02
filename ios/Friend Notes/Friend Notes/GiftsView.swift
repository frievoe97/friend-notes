import SwiftUI
import SwiftData

/// Global gift hub listing all gift ideas across the app.
struct GiftsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\GiftIdea.createdAt, order: .reverse)]) private var giftIdeas: [GiftIdea]

    @State private var showingAddGiftIdea = false
    @State private var selectedGiftIdea: GiftIdea?
    @State private var isGiftedExpanded = false
    @State private var showAllOpen = false
    @State private var searchText = ""

    private let openPreviewLimit = 5

    private var detailSheetBinding: Binding<Bool> {
        Binding(
            get: { selectedGiftIdea != nil },
            set: { if !$0 { selectedGiftIdea = nil } }
        )
    }

    private var sortedIdeas: [GiftIdea] {
        giftIdeas.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !trimmedSearchText.isEmpty
    }

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

    private var openIdeas: [GiftIdea] { filteredIdeas.filter { !$0.isGifted } }
    private var giftedIdeas: [GiftIdea] { filteredIdeas.filter(\.isGifted) }

    private var visibleOpenIdeas: [GiftIdea] {
        (showAllOpen || isSearching) ? openIdeas : Array(openIdeas.prefix(openPreviewLimit))
    }

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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]

    @State private var title = ""
    @State private var note = ""
    @State private var url = ""
    @State private var selectedFriendID: PersistentIdentifier?
    @State private var showingAssigneePicker = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case url
        case note
    }

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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

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

/// Gift detail sheet that starts in read mode and switches to edit mode on demand.
struct GiftIdeaDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.lastName), SortDescriptor(\Friend.firstName)]) private var allFriends: [Friend]
    @Bindable var idea: GiftIdea

    let allowsAssigneeEditing: Bool

    @State private var mode: Mode = .view
    @State private var draftTitle: String
    @State private var draftNote: String
    @State private var draftURL: String
    @State private var draftIsGifted: Bool
    @State private var selectedFriendID: PersistentIdentifier?
    @State private var showingAssigneePicker = false
    @State private var showingDeleteAlert = false
    @State private var browserURL: URL?
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

    private let noteCardMinHeight: CGFloat = 120

    init(idea: GiftIdea, allowsAssigneeEditing: Bool = true) {
        self.idea = idea
        self.allowsAssigneeEditing = allowsAssigneeEditing
        _draftTitle = State(initialValue: idea.title)
        _draftNote = State(initialValue: idea.note)
        _draftURL = State(initialValue: idea.url)
        _draftIsGifted = State(initialValue: idea.isGifted)
        _selectedFriendID = State(initialValue: idea.friend?.persistentModelID)
    }

    private var isEditing: Bool {
        mode == .edit
    }

    private var selectedFriend: Friend? {
        guard let selectedFriendID else { return nil }
        return allFriends.first(where: { $0.persistentModelID == selectedFriendID })
    }

    private var titleForNavigation: String {
        let source = isEditing ? draftTitle : idea.title
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("gift.new.title", "New Gift Idea") : trimmed
    }

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

    private func beginEditing() {
        draftTitle = idea.title
        draftNote = idea.note
        draftURL = idea.url
        draftIsGifted = idea.isGifted
        selectedFriendID = idea.friend?.persistentModelID
        mode = .edit
    }

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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func readOnlyRow(value: String) -> some View {
        Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "–" : value)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

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

    private func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }

        return URL(string: "https://\(trimmed)")
    }
}

/// Single-select sheet for assigning one friend (or no friend) to a gift.
private struct GiftAssigneePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let allFriends: [Friend]
    @Binding var selectedFriendID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedFriendID = nil
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.subtleFillSelected)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            Text(L10n.text("gifts.assignee.none", "No person assigned"))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedFriendID == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.subtleFill)
                }

                if !allFriends.isEmpty {
                    Section {
                        ForEach(allFriends) { friend in
                            Button {
                                selectedFriendID = friend.persistentModelID
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(name: friend.displayName, size: 30)
                                    Text(friend.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedFriendID == friend.persistentModelID {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(AppTheme.subtleFill)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle(L10n.text("gifts.assignee.label", "Person"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.done", "Done")) { dismiss() }
                }
            }
        }
        .appScreenBackground()
    }
}
