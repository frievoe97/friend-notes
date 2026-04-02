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
                    title: L10n.text("friend.section.history", "Meetings/Events"),
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
        .padding(.horizontal, 24)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    isContactEditing.toggle()
                    if !isContactEditing {
                        focusedField = nil
                    }
                }
            } label: {
                Image(systemName: isContactEditing ? "checkmark" : "square.and.pencil")
                    .font(.body.weight(.semibold))
            }
            .accessibilityLabel(
                isContactEditing
                    ? L10n.text("common.done", "Done")
                    : L10n.text("common.edit", "Edit")
            )
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
        let primaryName = friend.fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(spacing: 12) {
            AvatarView(name: primaryName.isEmpty ? friend.displayName : primaryName, size: 88)
                .padding(.top, 16)

            if isContactEditing {
                VStack(spacing: 8) {
                    TextField(
                        L10n.text("friend.first_name", "First Name"),
                        text: $friend.firstName
                    )
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.semibold))
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .lastName }

                    TextField(
                        L10n.text("friend.last_name", "Last Name"),
                        text: $friend.lastName
                    )
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.semibold))
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .nickname }

                    TextField(
                        L10n.text("friend.nickname", "Nickname"),
                        text: $friend.nickname
                    )
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .focused($focusedField, equals: .nickname)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                }
                .padding(.horizontal, 32)

            } else {
                VStack(spacing: 4) {
                    Text(primaryName.isEmpty ? friend.displayName : primaryName)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if !friend.nickname.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(friend.nickname)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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

}


// MARK: - Add Friend Sheet

/// Modal flow for creating a new friend with optional profile details.
struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTagStore.key) private var definedTagsRaw = "[]"

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var nickname = ""
    @State private var tags: [String] = []
    @State private var hobbies: [String] = []
    @State private var foods: [String] = []
    @State private var musics: [String] = []
    @State private var moviesSeries: [String] = []
    @State private var notes: [String] = []
    @State private var isHobbiesExpanded = false
    @State private var isFoodExpanded = false
    @State private var isMusicExpanded = false
    @State private var isMoviesExpanded = false
    @State private var isNotesExpanded = false
    @State private var birthday: Date? = nil
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

    /// Name preview used by the avatar while typing.
    ///
    /// - Returns: Nickname when available, otherwise first+last name.
    private var displayNameForAvatar: String {
        let nick = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nick.isEmpty { return nick }
        return [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    Divider().padding(.horizontal, 24)
                    birthdaySection
                    tagsSection
                    collapsibleListEditorSection(title: L10n.text("friend.section.hobbies", "Hobbies"), icon: "figure.walk", items: $hobbies, placeholder: L10n.text("friend.placeholder.add_hobby", "Add hobby…"), isExpanded: $isHobbiesExpanded)
                    collapsibleListEditorSection(title: L10n.text("friend.section.food", "Food"), icon: "fork.knife", items: $foods, placeholder: L10n.text("friend.placeholder.add_food", "Add food…"), isExpanded: $isFoodExpanded)
                    collapsibleListEditorSection(title: L10n.text("friend.section.music", "Music"), icon: "music.note", items: $musics, placeholder: L10n.text("friend.placeholder.add_music", "Add music…"), isExpanded: $isMusicExpanded)
                    collapsibleListEditorSection(title: L10n.text("friend.section.movies_series", "Movies / Series"), icon: "film.fill", items: $moviesSeries, placeholder: L10n.text("friend.placeholder.add_movie_series", "Add movie or series…"), isExpanded: $isMoviesExpanded)
                    collapsibleListEditorSection(title: L10n.text("friend.section.notes", "Notes"), icon: "note.text", items: $notes, placeholder: L10n.text("friend.placeholder.add_note", "Add note…"), isExpanded: $isNotesExpanded)
                }
                .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(L10n.text("friend.new.title", "New Friend"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                        .accessibilityLabel(L10n.text("common.add", "Add"))
                        .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  && lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingBirthdayPicker) {
                BirthdayPickerSheet(
                    title: L10n.text("friend.section.birthday", "Birthday"),
                    initialDate: birthday ?? Date(),
                    onSave: { selectedDate in
                        birthday = selectedDate
                    }
                )
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    focusedField = .firstName
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

            VStack(spacing: 8) {
                TextField(
                    "",
                    text: $firstName,
                    prompt: focusedField == .firstName ? nil : Text(L10n.text("friend.first_name", "First Name"))
                )
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .lastName }
                TextField(
                    "",
                    text: $lastName,
                    prompt: focusedField == .lastName ? nil : Text(L10n.text("friend.last_name", "Last Name"))
                )
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .nickname }
            }
            .padding(.horizontal, 32)

            TextField(L10n.text("friend.nickname", "Nickname"), text: $nickname)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .nickname)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .padding(.horizontal, 24)
        }
    }

    /// Birthday input section for optional date assignment.
    private var birthdaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(L10n.text("friend.section.birthday", "Birthday"), icon: "birthday.cake.fill")
            HStack {
                if birthday != nil {
                    Button {
                        showingBirthdayPicker = true
                    } label: {
                        Text((birthday ?? Date()).formatted(date: .long, time: .omitted))
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Button { birthday = nil } label: {
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
                    .padding(.horizontal, 24)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(definedTags, id: \.self) { tag in
                        let isSelected = tags.contains(tag)
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

    /// Wraps the reusable list editor in a titled section block.
    ///
    /// - Parameters:
    ///   - title: Section title.
    ///   - icon: SF Symbol name.
    ///   - items: Bound editable list.
    ///   - placeholder: Add-field placeholder text.
    ///   - isExpanded: Expansion binding for the disclosure state.
    /// - Returns: A collapsible section containing `StringListEditor`.
    private func collapsibleListEditorSection(
        title: String,
        icon: String,
        items: Binding<[String]>,
        placeholder: String,
        isExpanded: Binding<Bool>
    ) -> some View {
        let collapseAnimation = Animation.spring(response: 0.34, dampingFraction: 0.9, blendDuration: 0.15)
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(collapseAnimation) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Label(title, systemImage: icon)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(items.wrappedValue.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                        .frame(width: 12)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            if isExpanded.wrappedValue {
                StringListEditor(placeholder: placeholder, items: items)
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -8)),
                        removal: .opacity
                    ))
            }
        }
        .animation(collapseAnimation, value: isExpanded.wrappedValue)
    }

    /// Wraps the reusable list editor in a titled section block.
    ///
    /// - Parameters:
    ///   - title: Section title.
    ///   - icon: SF Symbol name.
    ///   - items: Bound editable list.
    ///   - placeholder: Add-field placeholder text.
    /// - Returns: A section containing `StringListEditor`.
    private func listEditorSection(
        title: String,
        icon: String,
        items: Binding<[String]>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(title, icon: icon)
            StringListEditor(placeholder: placeholder, items: items)
                .padding(.horizontal, 24)
        }
    }

    /// Builds a standardized small section label with icon.
    ///
    /// - Parameters:
    ///   - title: Label text.
    ///   - icon: SF Symbol name.
    /// - Returns: Styled label view.
    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
    }

    /// Adds or removes a tag in the local creation draft.
    ///
    /// - Parameter tag: Tag to toggle.
    private func toggleTag(_ tag: String) {
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
            tags.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
    }

    /// Validates and persists a new friend into the model context.
    ///
    /// - Note: Empty first+last name input is ignored and will not create a record.
    private func save() {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty || !trimmedLastName.isEmpty else { return }

        let friend = Friend(
            firstName: trimmedFirstName,
            lastName: trimmedLastName,
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            birthday: birthday
        )
        modelContext.insert(friend)

        let categoryEntries: [(String, [String])] = [
            ("hobbies", hobbies),
            ("foods", foods),
            ("musics", musics),
            ("moviesSeries", moviesSeries),
            ("notes", notes)
        ]
        for (cat, items) in categoryEntries {
            for (i, item) in items.enumerated() {
                let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                let entry = FriendEntry(title: trimmed, category: cat, order: i)
                modelContext.insert(entry)
                friend.entries.append(entry)
            }
        }
        dismiss()
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
                VStack(alignment: .leading, spacing: 16) {
                    TextField(L10n.text("gift.name", "Name"), text: $idea.title)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    TextField(L10n.text("gift.note", "Note"), text: $idea.note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(4...)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    TextField(L10n.text("gift.url", "URL"), text: $idea.url)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                    TextField(L10n.text("gift.name", "Name"), text: $title)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .url }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    TextField(L10n.text("gift.url", "URL"), text: $url)
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

                    TextField(L10n.text("gift.note", "Note"), text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(4...)
                        .focused($focusedField, equals: .note)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
}
