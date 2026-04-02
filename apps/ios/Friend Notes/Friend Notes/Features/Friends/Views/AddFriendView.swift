import SwiftUI
import SwiftData

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
                    Button(L10n.text("common.cancel", "Cancel")) {
                        cancelCreation()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "Save")) { save() }
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
            }
            .sheet(isPresented: $showingBirthdayPicker) {
                BirthdayPickerSheet(
                    title: L10n.text("friend.section.birthday", "Birthday"),
                    initialDate: draftFriend?.birthday ?? Date(),
                    onSave: { selectedDate in
                        draftFriend?.birthday = selectedDate
                    }
                )
            }
            .onAppear {
                initializeDraftFriendIfNeeded()
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
                        .font(.body.weight(.semibold))
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
                        .font(.body.weight(.semibold))
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
                        .font(.body.weight(.semibold))
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
            .padding(.horizontal, 12)
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
