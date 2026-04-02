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
