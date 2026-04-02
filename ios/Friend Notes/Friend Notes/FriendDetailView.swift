import SwiftUI
import SwiftData

// MARK: - Detail / Edit

/// Displays and edits a single friend profile, including history, notes, tags, and gift ideas.
struct FriendDetailView: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTagStore.key) private var definedTagsRaw = "[]"

    @State private var showingDeleteAlert = false
    @State private var showingBirthdayPicker = false
    @State private var quickAddEntryCategory: QuickAddEntryCategory?
    @State private var showingQuickAddMeeting = false
    @State private var showingQuickAddEvent = false
    @State private var showingQuickAddGiftIdea = false
    @State private var isContactEditing = false
    @State private var firstNameDraft = ""
    @State private var lastNameDraft = ""
    @State private var nicknameDraft = ""
    @FocusState private var focusedField: Field?

    /// Focus targets for keyboard navigation in editable name fields.
    private enum Field {
        case firstName, lastName, nickname
    }

    /// Supported quick-add entry categories from the detail toolbar menu.
    private enum QuickAddEntryCategory: String, Identifiable {
        case hobbies
        case foods
        case musics
        case moviesSeries
        case notes

        var id: String { rawValue }

        var title: String {
            switch self {
            case .hobbies:
                return L10n.text("friend.section.hobbies", "Hobbies")
            case .foods:
                return L10n.text("friend.section.food", "Food")
            case .musics:
                return L10n.text("friend.section.music", "Music")
            case .moviesSeries:
                return L10n.text("friend.section.movies_series", "Movies / Series")
            case .notes:
                return L10n.text("friend.section.notes", "Notes")
            }
        }

        var placeholder: String {
            switch self {
            case .hobbies:
                return L10n.text("friend.placeholder.add_hobby", "Add hobby…")
            case .foods:
                return L10n.text("friend.placeholder.add_food", "Add food…")
            case .musics:
                return L10n.text("friend.placeholder.add_music", "Add music…")
            case .moviesSeries:
                return L10n.text("friend.placeholder.add_movie_series", "Add movie or series…")
            case .notes:
                return L10n.text("friend.placeholder.add_note", "Add note…")
            }
        }
    }

    /// Decoded globally defined tag options available for selection.
    private var definedTags: [String] {
        AppTagStore.decode(definedTagsRaw)
    }

    /// Count of upcoming meetings/events linked to this friend.
    private var upcomingMeetingsCount: Int {
        let now = Date()
        return friend.meetings.filter { $0.startDate > now }.count
    }

    /// Count of not-yet-gifted ideas linked to this friend.
    private var openGiftIdeasCount: Int {
        friend.giftIdeas.filter { !$0.isGifted }.count
    }

    /// `true` when the current name draft can be committed.
    private var canCommitNameDraft: Bool {
        let first = firstNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let nickname = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !first.isEmpty || !last.isEmpty || !nickname.isEmpty
    }

    var body: some View {
        profileScrollContainer
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { detailToolbar }
            .sheet(isPresented: $showingBirthdayPicker, content: birthdayPickerSheet)
            .sheet(item: $quickAddEntryCategory) { category in
                AddFriendEntrySheet(placeholder: category.placeholder) { entryTitle, note in
                    addQuickEntry(title: entryTitle, note: note, category: category.rawValue)
                }
            }
            .sheet(isPresented: $showingQuickAddMeeting) {
                AddMeetingView(initialDate: Date(), preselectedFriends: [friend])
            }
            .sheet(isPresented: $showingQuickAddEvent) {
                AddEventView(initialDate: Date(), preselectedFriends: [friend])
            }
            .sheet(isPresented: $showingQuickAddGiftIdea) {
                AddGiftIdeaSheet { title, note, url in
                    addQuickGiftIdea(title: title, note: note, url: url)
                }
            }
            .alert(L10n.text("friend.delete.title", "Delete %@?", friend.displayName), isPresented: $showingDeleteAlert) {
                Button(L10n.text("common.delete", "Delete"), role: .destructive) {
                    DataMaintenance.pruneMeetingsAfterRemoving(friend: friend, in: modelContext)
                    modelContext.delete(friend)
                    dismiss()
                }
                Button(L10n.text("common.cancel", "Cancel"), role: .cancel) {}
            } message: {
                Text(L10n.text("common.delete_irreversible", "This action cannot be undone."))
            }
            .appScreenBackground()
    }

    /// Main scroll container for the profile detail content.
    private var profileScrollContainer: some View {
        ScrollView {
            profileContentStack
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollDismissesKeyboard(.interactively)
    }

    /// Ordered stack of all detail sections.
    private var profileContentStack: some View {
        VStack(spacing: 28) {
            header
            Divider().padding(.horizontal, 24)
            birthdaySection
            tagsSection
            categoriesSection
            if isContactEditing {
                deleteButton
            }
        }
        .padding(.bottom, 40)
    }

    /// Navigation rows linking to dedicated sub-pages for each interest category.
    private var categoriesSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                FriendEntryListView(
                    friend: friend,
                    title: L10n.text("friend.section.hobbies", "Hobbies"),
                    icon: "figure.walk",
                    category: "hobbies",
                    addPlaceholder: L10n.text("friend.placeholder.add_hobby", "Add hobby…")
                )
            } label: {
                categoryRow(title: L10n.text("friend.section.hobbies", "Hobbies"),
                            icon: "figure.walk", count: friend.entryList(for: "hobbies").count)
            }
            .buttonStyle(.plain)

            NavigationLink {
                FriendEntryListView(
                    friend: friend,
                    title: L10n.text("friend.section.food", "Food"),
                    icon: "fork.knife",
                    category: "foods",
                    addPlaceholder: L10n.text("friend.placeholder.add_food", "Add food…")
                )
            } label: {
                categoryRow(title: L10n.text("friend.section.food", "Food"),
                            icon: "fork.knife", count: friend.entryList(for: "foods").count)
            }
            .buttonStyle(.plain)

            NavigationLink {
                FriendEntryListView(
                    friend: friend,
                    title: L10n.text("friend.section.music", "Music"),
                    icon: "music.note",
                    category: "musics",
                    addPlaceholder: L10n.text("friend.placeholder.add_music", "Add music…")
                )
            } label: {
                categoryRow(title: L10n.text("friend.section.music", "Music"),
                            icon: "music.note", count: friend.entryList(for: "musics").count)
            }
            .buttonStyle(.plain)

            NavigationLink {
                FriendEntryListView(
                    friend: friend,
                    title: L10n.text("friend.section.movies_series", "Movies / Series"),
                    icon: "film.fill",
                    category: "moviesSeries",
                    addPlaceholder: L10n.text("friend.placeholder.add_movie_series", "Add movie or series…")
                )
            } label: {
                categoryRow(title: L10n.text("friend.section.movies_series", "Movies / Series"),
                            icon: "film.fill", count: friend.entryList(for: "moviesSeries").count)
            }
            .buttonStyle(.plain)

            NavigationLink {
                FriendEntryListView(
                    friend: friend,
                    title: L10n.text("friend.section.notes", "Notes"),
                    icon: "note.text",
                    category: "notes",
                    addPlaceholder: L10n.text("friend.placeholder.add_note", "Add note…")
                )
            } label: {
                categoryRow(title: L10n.text("friend.section.notes", "Notes"),
                            icon: "note.text", count: friend.entryList(for: "notes").count)
            }
            .buttonStyle(.plain)
                NavigationLink {
                    FriendMeetingsView(friend: friend)
                } label: {
                    categoryRow(
                        title: L10n.text("friend.section.history", "Meetings / Events"),
                        icon: "clock.arrow.circlepath",
                        count: upcomingMeetingsCount
                    )
                }
            .buttonStyle(.plain)

            NavigationLink {
                FriendGiftsView(friend: friend)
            } label: {
                categoryRow(
                    title: L10n.text("friend.section.gift_ideas", "Gift Ideas"),
                    icon: "gift.fill",
                    count: openGiftIdeasCount
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
    }

    private func categoryRow(title: String, icon: String, count: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// Top bar controls for pinning and editing profile content.
    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {

        // MARK: - Leading (Left)
        ToolbarItem(placement: .topBarLeading) {
            if isContactEditing {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        friend.isFavorite.toggle()
                    }
                } label: {
                    Image(systemName: friend.isFavorite ? "star.fill" : "star")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(friend.isFavorite ? AppTheme.accent : .secondary)
                }
                .accessibilityLabel("Favorite")
            }
        }

        // MARK: - Trailing (Grouped)
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section {
                    Button {
                        quickAddEntryCategory = .hobbies
                    } label: {
                        Label(L10n.text("friend.section.hobbies", "Hobbies"), systemImage: "figure.walk")
                    }

                    Button {
                        quickAddEntryCategory = .foods
                    } label: {
                        Label(L10n.text("friend.section.food", "Food"), systemImage: "fork.knife")
                    }

                    Button {
                        quickAddEntryCategory = .musics
                    } label: {
                        Label(L10n.text("friend.section.music", "Music"), systemImage: "music.note")
                    }

                    Button {
                        quickAddEntryCategory = .moviesSeries
                    } label: {
                        Label(L10n.text("friend.section.movies_series", "Movies / Series"), systemImage: "film.fill")
                    }

                    Button {
                        quickAddEntryCategory = .notes
                    } label: {
                        Label(L10n.text("friend.section.notes", "Notes"), systemImage: "note.text")
                    }
                }

                Section {
                    Button {
                        showingQuickAddMeeting = true
                    } label: {
                        Label(L10n.text("meeting.new.title", "New Meeting"), systemImage: "person.2.fill")
                    }

                    Button {
                        showingQuickAddEvent = true
                    } label: {
                        Label(L10n.text("event.new.title", "New Event"), systemImage: "flag.fill")
                    }

                    Button {
                        showingQuickAddGiftIdea = true
                    } label: {
                        Label(L10n.text("gift.new.title", "New Gift Idea"), systemImage: "gift.fill")
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
            }
            .accessibilityLabel(L10n.text("common.add", "Add"))
        }

        // MARK: - Primary Action (separate right button)
        ToolbarItem(placement: .primaryAction) {
            Button {
                if isContactEditing {
                    commitContactDraft()
                } else {
                    startContactEditing()
                }
            } label: {
                Image(systemName: isContactEditing ? "checkmark" : "pencil")
                    .font(.body.weight(.semibold))
                    .frame(width: 18, height: 18, alignment: .center)
            }
            .disabled(isContactEditing && !canCommitNameDraft)
            .accessibilityLabel(
                isContactEditing
                    ? L10n.text("common.done", "Done")
                    : L10n.text("common.edit", "Edit")
            )
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(L10n.text("common.done", "Done")) {
                focusedField = nil
                Keyboard.dismiss()
            }
        }
    }   

    /// Sheet content for editing the birthday value.
    private func birthdayPickerSheet() -> some View {
        return BirthdayPickerSheet(
            title: L10n.text("friend.section.birthday", "Birthday"),
            initialDate: friend.birthday ?? Date(),
            onSave: { selectedDate in
                friend.birthday = selectedDate
            }
        )
    }

    /// Header area containing avatar, editable name fields, and nickname.
    private var header: some View {
        let primaryName: String = {
            if isContactEditing {
                return [firstNameDraft, lastNameDraft]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
            return friend.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        }()
        let avatarName: String = {
            if isContactEditing {
                let nickname = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !nickname.isEmpty { return nickname }
                if !primaryName.isEmpty { return primaryName }
            }
            return primaryName.isEmpty ? friend.displayName : primaryName
        }()

        return VStack(spacing: 12) {
            AvatarView(name: avatarName, size: 88)
                .padding(.top, 16)

            if isContactEditing {
                let canClearFirstName = !firstNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearLastName = !lastNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearNickname = !nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        inputFieldLabel(L10n.text("friend.first_name", "First Name"))
                        HStack(spacing: 8) {
                            TextField("", text: $firstNameDraft)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)
                                .font(.title3.weight(.semibold))
                                .focused($focusedField, equals: .firstName)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .lastName }

                            Button {
                                firstNameDraft = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearFirstName ? 1 : 0)
                            .disabled(!canClearFirstName)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        inputFieldLabel(L10n.text("friend.last_name", "Last Name"))
                        HStack(spacing: 8) {
                            TextField("", text: $lastNameDraft)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)
                                .font(.title3.weight(.semibold))
                                .focused($focusedField, equals: .lastName)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .nickname }

                            Button {
                                lastNameDraft = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearLastName ? 1 : 0)
                            .disabled(!canClearLastName)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        inputFieldLabel(L10n.text("friend.nickname", "Nickname"))
                        HStack(spacing: 8) {
                            TextField("", text: $nicknameDraft)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled(true)
                                .font(.title3.weight(.semibold))
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .nickname)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }

                            Button {
                                nicknameDraft = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearNickname ? 1 : 0)
                            .disabled(!canClearNickname)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if !canCommitNameDraft {
                        Text(L10n.text("friend.name_required", "Name or nickname required."))
                            .font(.caption)
                            .foregroundStyle(AppTheme.danger)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)
            } else {
                let trimmedNickname = friend.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedFullName = friend.fullName.trimmingCharacters(in: .whitespacesAndNewlines)

                VStack(spacing: 4) {
                    if trimmedNickname.isEmpty {
                        Text(trimmedFullName.isEmpty ? friend.displayName : trimmedFullName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    } else {
                        Text(trimmedNickname)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if !trimmedFullName.isEmpty {
                            Text(trimmedFullName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
        }
    }

    /// Birthday display/edit section with wheel picker sheet integration.
    private var birthdaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("friend.section.birthday", "Birthday"), icon: "birthday.cake.fill")
            HStack {
                if friend.birthday != nil {
                    if isContactEditing {
                        Button {
                            showingBirthdayPicker = true
                        } label: {
                            Text((friend.birthday ?? Date()).formatted(date: .long, time: .omitted))
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Button { friend.birthday = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                    } else {
                        Text((friend.birthday ?? Date()).formatted(date: .long, time: .omitted))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    if isContactEditing {
                        Button {
                            showingBirthdayPicker = true
                        } label: {
                            Label(L10n.text("friend.add_birthday", "Add Birthday"), systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                    } else {
                        Text(L10n.text("friend.no_birthday", "No birthday set"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Tag selection section bound to globally configured tags.
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("friend.section.tags", "Tags"), icon: "tag.fill")

            if isContactEditing {
                if definedTags.isEmpty {
                    Text(L10n.text("friend.tags.empty_hint", "Define tags first in Settings."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(definedTags, id: \.self) { tag in
                            let isSelected = friend.tags.contains(tag)
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    toggleTag(tag)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                    Text(tag)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected ? AppTheme.subtleFillSelected : AppTheme.subtleFill,
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                if friend.tags.isEmpty {
                    Text(L10n.text("friend.tags.none", "No tags selected."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(friend.tags.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }, id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.subtleFill, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    /// Destructive action button used to delete the current friend.
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label(L10n.text("friend.delete.button", "Delete Friend"), systemImage: "trash")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .padding(.horizontal, 24)
    }

    /// Builds a standardized small section label with icon.
    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
    }

    /// Label style used above editable text inputs.
    private func inputFieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    /// Adds or removes a tag from the friend and keeps selected tags sorted.
    ///
    /// - Parameter tag: Tag to toggle.
    private func toggleTag(_ tag: String) {
        if friend.tags.contains(tag) {
            friend.tags.removeAll { $0 == tag }
        } else {
            friend.tags.append(tag)
            friend.tags.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
    }

    /// Adds a new category entry directly from the toolbar quick-add menu.
    private func addQuickEntry(title: String, note: String, category: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let order = friend.entryList(for: category).count
        let entry = FriendEntry(
            title: trimmedTitle,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            order: order
        )
        modelContext.insert(entry)
        friend.entries.append(entry)
    }

    /// Adds a new gift idea preassigned to the current friend.
    private func addQuickGiftIdea(title: String, note: String, url: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let idea = GiftIdea(
            title: trimmedTitle,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(idea)
        friend.giftIdeas.append(idea)
    }

    /// Starts editing by copying persisted values into local name drafts.
    private func startContactEditing() {
        firstNameDraft = friend.firstName
        lastNameDraft = friend.lastName
        nicknameDraft = friend.nickname
        withAnimation(.easeInOut(duration: 0.2)) {
            isContactEditing = true
        }
    }

    /// Commits local name drafts to the persisted friend record when valid.
    private func commitContactDraft() {
        guard canCommitNameDraft else { return }

        friend.firstName = firstNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        friend.lastName = lastNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        friend.nickname = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        focusedField = nil
        Keyboard.dismiss()

        withAnimation(.easeInOut(duration: 0.2)) {
            isContactEditing = false
        }
    }

}


// MARK: - Add Friend Sheet

/// Modal flow for creating a new friend with optional profile details.
struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTagStore.key) private var definedTagsRaw = "[]"

    @State private var draftFriend: Friend?
    @State private var showingBirthdayPicker = false
    @FocusState private var focusedField: Field?

    /// Focus targets for keyboard navigation while creating a friend.
    private enum Field {
        case firstName, lastName, nickname
    }

    /// Decoded globally defined tags that can be assigned during creation.
    private var definedTags: [String] {
        AppTagStore.decode(definedTagsRaw)
    }

    private var firstNameBinding: Binding<String> {
        Binding(
            get: { draftFriend?.firstName ?? "" },
            set: { draftFriend?.firstName = $0 }
        )
    }

    private var lastNameBinding: Binding<String> {
        Binding(
            get: { draftFriend?.lastName ?? "" },
            set: { draftFriend?.lastName = $0 }
        )
    }

    private var nicknameBinding: Binding<String> {
        Binding(
            get: { draftFriend?.nickname ?? "" },
            set: { draftFriend?.nickname = $0 }
        )
    }

    /// Name preview used by the avatar while typing.
    ///
    /// - Returns: Nickname when available, otherwise first+last name.
    private var displayNameForAvatar: String {
        let nick = (draftFriend?.nickname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !nick.isEmpty { return nick }
        return [(draftFriend?.firstName ?? ""), (draftFriend?.lastName ?? "")]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Inline navigation title that mirrors typed nickname/name.
    private var navigationTitleText: String {
        let trimmed = displayNameForAvatar.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("friend.new.title", "New Friend") : trimmed
    }

    /// Enables save once a non-empty first or last name exists.
    private var canSave: Bool {
        let first = (draftFriend?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last = (draftFriend?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !first.isEmpty || !last.isEmpty
    }

    /// Count of upcoming meetings/events linked to the current draft friend.
    private var upcomingMeetingsCount: Int {
        guard let draftFriend else { return 0 }
        let now = Date()
        return draftFriend.meetings.filter { $0.startDate > now }.count
    }

    /// Count of not-yet-gifted ideas linked to the current draft friend.
    private var openGiftIdeasCount: Int {
        guard let draftFriend else { return 0 }
        return draftFriend.giftIdeas.filter { !$0.isGifted }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    Divider().padding(.horizontal, 24)
                    birthdaySection
                    tagsSection
                    categoriesSection
                }
                .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancelCreation() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                        Keyboard.dismiss()
                    }
                }
            }
        }
        .appScreenBackground()
    }

    /// Header area for entering name and nickname with live avatar preview.
    private var header: some View {
        VStack(spacing: 14) {
            AvatarView(name: displayNameForAvatar, size: 88)
                .animation(.spring(response: 0.4), value: displayNameForAvatar)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    inputFieldLabel(L10n.text("friend.first_name", "First Name"))
                    TextField("", text: firstNameBinding)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .lastName }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    inputFieldLabel(L10n.text("friend.last_name", "Last Name"))
                    TextField("", text: lastNameBinding)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .nickname }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    inputFieldLabel(L10n.text("friend.nickname", "Nickname"))
                    TextField("", text: nicknameBinding)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .nickname)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    /// Birthday input section for optional date assignment.
    private var birthdaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("friend.section.birthday", "Birthday"), icon: "birthday.cake.fill")
            HStack {
                if draftFriend?.birthday != nil {
                    Button {
                        showingBirthdayPicker = true
                    } label: {
                        Text((draftFriend?.birthday ?? Date()).formatted(date: .long, time: .omitted))
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Button { draftFriend?.birthday = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                } else {
                    Button {
                        showingBirthdayPicker = true
                    } label: {
                        Label(L10n.text("friend.add_birthday", "Add Birthday"), systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Tag selection section using globally defined tag options.
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("friend.section.tags", "Tags"), icon: "tag.fill")
            if definedTags.isEmpty {
                Text(L10n.text("friend.tags.empty_hint", "Define tags first in Settings."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(definedTags, id: \.self) { tag in
                        let isSelected = draftFriend?.tags.contains(tag) ?? false
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                toggleTag(tag)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                Text(tag)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? AppTheme.subtleFillSelected : AppTheme.subtleFill,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    /// Navigation rows matching the same category structure used in friend detail.
    private var categoriesSection: some View {
        guard let draftFriend else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(spacing: 0) {
                NavigationLink {
                    FriendEntryListView(
                        friend: draftFriend,
                        title: L10n.text("friend.section.hobbies", "Hobbies"),
                        icon: "figure.walk",
                        category: "hobbies",
                        addPlaceholder: L10n.text("friend.placeholder.add_hobby", "Add hobby…")
                    )
                } label: {
                    categoryRow(title: L10n.text("friend.section.hobbies", "Hobbies"),
                                icon: "figure.walk", count: draftFriend.entryList(for: "hobbies").count)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FriendEntryListView(
                        friend: draftFriend,
                        title: L10n.text("friend.section.food", "Food"),
                        icon: "fork.knife",
                        category: "foods",
                        addPlaceholder: L10n.text("friend.placeholder.add_food", "Add food…")
                    )
                } label: {
                    categoryRow(title: L10n.text("friend.section.food", "Food"),
                                icon: "fork.knife", count: draftFriend.entryList(for: "foods").count)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FriendEntryListView(
                        friend: draftFriend,
                        title: L10n.text("friend.section.music", "Music"),
                        icon: "music.note",
                        category: "musics",
                        addPlaceholder: L10n.text("friend.placeholder.add_music", "Add music…")
                    )
                } label: {
                    categoryRow(title: L10n.text("friend.section.music", "Music"),
                                icon: "music.note", count: draftFriend.entryList(for: "musics").count)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FriendEntryListView(
                        friend: draftFriend,
                        title: L10n.text("friend.section.movies_series", "Movies / Series"),
                        icon: "film.fill",
                        category: "moviesSeries",
                        addPlaceholder: L10n.text("friend.placeholder.add_movie_series", "Add movie or series…")
                    )
                } label: {
                    categoryRow(title: L10n.text("friend.section.movies_series", "Movies / Series"),
                                icon: "film.fill", count: draftFriend.entryList(for: "moviesSeries").count)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FriendEntryListView(
                        friend: draftFriend,
                        title: L10n.text("friend.section.notes", "Notes"),
                        icon: "note.text",
                        category: "notes",
                        addPlaceholder: L10n.text("friend.placeholder.add_note", "Add note…")
                    )
                } label: {
                    categoryRow(title: L10n.text("friend.section.notes", "Notes"),
                                icon: "note.text", count: draftFriend.entryList(for: "notes").count)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FriendMeetingsView(friend: draftFriend)
                } label: {
                    categoryRow(
                        title: L10n.text("friend.section.history", "Meetings / Events"),
                        icon: "clock.arrow.circlepath",
                        count: upcomingMeetingsCount
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FriendGiftsView(friend: draftFriend)
                } label: {
                    categoryRow(
                        title: L10n.text("friend.section.gift_ideas", "Gift Ideas"),
                        icon: "gift.fill",
                        count: openGiftIdeasCount
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        )
    }

    private func categoryRow(title: String, icon: String, count: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// Builds a standardized small section label with icon.
    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
    }

    /// Label style used above editable text inputs.
    private func inputFieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    /// Adds or removes a tag in the local creation draft.
    ///
    /// - Parameter tag: Tag to toggle.
    private func toggleTag(_ tag: String) {
        guard let draftFriend else { return }
        if draftFriend.tags.contains(tag) {
            draftFriend.tags.removeAll { $0 == tag }
        } else {
            draftFriend.tags.append(tag)
            draftFriend.tags.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
    }

    /// Creates an empty draft friend once so linked sub-pages can behave exactly like existing profiles.
    private func initializeDraftFriendIfNeeded() {
        guard draftFriend == nil else { return }
        let friend = Friend()
        modelContext.insert(friend)
        draftFriend = friend
    }

    /// Cancels creation and removes any draft data including linked records.
    private func cancelCreation() {
        deleteDraftFriendIfNeeded()
        dismiss()
    }

    /// Persists the current draft friend and keeps all linked entries/meetings/gifts.
    private func save() {
        guard let draftFriend else { return }
        let trimmedFirstName = draftFriend.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = draftFriend.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty || !trimmedLastName.isEmpty else { return }

        draftFriend.firstName = trimmedFirstName
        draftFriend.lastName = trimmedLastName
        draftFriend.nickname = draftFriend.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        draftFriend.tags.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        focusedField = nil
        Keyboard.dismiss()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Could not save friend draft: \(error)")
        }
    }

    /// Deletes the draft friend and prunes orphaned meetings created during draft editing.
    private func deleteDraftFriendIfNeeded() {
        guard let draftFriend else { return }
        DataMaintenance.pruneMeetingsAfterRemoving(friend: draftFriend, in: modelContext)
        modelContext.delete(draftFriend)
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not delete friend draft: \(error)")
        }
        self.draftFriend = nil
    }
}

/// Sheet containing a wheel-style birthday picker with cancel/save actions.
private struct BirthdayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    let title: String
    let initialDate: Date
    let onSave: (Date) -> Void

    init(
        title: String,
        initialDate: Date,
        onSave: @escaping (Date) -> Void
    ) {
        self.title = title
        self.initialDate = initialDate
        self.onSave = onSave
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.text("friend.section.birthday", "Birthday"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
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
                        onSave(selectedDate)
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
        .onAppear {
            selectedDate = initialDate
        }
    }
}

/// Sheet for editing an existing gift idea in place.
struct EditGiftIdeaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var idea: GiftIdea

    var body: some View {
        NavigationStack {
            ScrollView {
                let canClearTitle = !idea.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearNote = !idea.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearURL = !idea.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.name", "Name"))
                        HStack(spacing: 8) {
                            TextField("", text: $idea.title)
                                .textFieldStyle(.plain)

                            Button {
                                idea.title = ""
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
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.note", "Note"))
                        HStack(alignment: .top, spacing: 8) {
                            TextField("", text: $idea.note, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(4...)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                idea.note = ""
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
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.url", "URL"))
                        HStack(spacing: 8) {
                            TextField("", text: $idea.url)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)

                            Button {
                                idea.url = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearURL ? 1 : 0)
                            .disabled(!canClearURL)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Toggle(L10n.text("gift.already_gifted", "Already gifted"), isOn: $idea.isGifted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle(L10n.text("gift.edit.title", "Edit Gift Idea"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.close", "Close")) { dismiss() }
                }
            }
        }
        .appScreenBackground()
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Gift Idea Sheet

/// Sheet for creating a new gift idea.
struct AddGiftIdeaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var url = ""
    @FocusState private var focusedField: Field?

    let onSave: (String, String, String) -> Void

    private enum Field {
        case title
        case url
        case note
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
                        onSave(title, note, url)
                        dismiss()
                    }
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
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
