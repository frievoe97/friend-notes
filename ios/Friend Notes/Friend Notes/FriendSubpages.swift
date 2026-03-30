import SwiftUI
import SwiftData

// MARK: - Entry List Sub-Page (Hobbies, Food, Music, Movies, Notes)

/// Sub-page listing entries for a single category (e.g. hobbies, food).
struct FriendEntryListView: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext

    let title: String
    let icon: String
    let category: String
    let addPlaceholder: String

    @State private var showingAdd = false
    @State private var editingEntry: FriendEntry?

    private var editingBinding: Binding<Bool> {
        Binding(get: { editingEntry != nil }, set: { if !$0 { editingEntry = nil } })
    }

    private var entries: [FriendEntry] {
        friend.entryList(for: category)
    }

    var body: some View {
        entryList
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("common.add", "Add")) {
                    showingAdd = true
                }
                .fontWeight(.semibold)
            }
        }
        .appScreenBackground()
        .sheet(isPresented: $showingAdd) {
            AddFriendEntrySheet(placeholder: addPlaceholder) { entryTitle, note in
                addEntry(title: entryTitle, note: note)
            }
        }
        .sheet(isPresented: editingBinding) {
            if let entry = editingEntry {
                EditFriendEntrySheet(entry: entry)
            }
        }
    }

    private var entryList: some View {
        List {
            if !entries.isEmpty {
                Section {
                    ForEach(entries) { entry in
                        entryRow(entry)
                            .listRowBackground(AppTheme.subtleFill)
                    }
                    .onDelete { offsets in
                        offsets.map { entries[$0] }.forEach { modelContext.delete($0) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    title,
                    systemImage: icon,
                    description: Text(L10n.text("list.detail.empty", "Tap + to add an entry."))
                )
            }
        }
    }

    private func entryRow(_ entry: FriendEntry) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { editingEntry = entry }
    }

    private func addEntry(title: String, note: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = FriendEntry(
            title: trimmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            order: entries.count
        )
        modelContext.insert(entry)
        friend.entries.append(entry)
    }
}

// MARK: - Add Entry Sheet

struct AddFriendEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @FocusState private var focusedField: Field?

    let placeholder: String
    let onSave: (String, String) -> Void

    private enum Field { case title, note }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField(L10n.text("entry.name", "Title"), text: $title)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .note }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    TextField(L10n.text("entry.note", "Note (optional)"), text: $note, axis: .vertical)
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
            .navigationTitle(L10n.text("entry.new.title", "New Entry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "Save")) {
                        onSave(title, note)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button(L10n.text("common.done", "Done")) {
                            focusedField = nil
                            Keyboard.dismiss()
                        }
                    }
                }
            }
        }
        .appScreenBackground()
    }
}

// MARK: - Edit Entry Sheet

struct EditFriendEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: FriendEntry

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField(L10n.text("entry.name", "Title"), text: $entry.title)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    TextField(L10n.text("entry.note", "Note (optional)"), text: $entry.note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(4...)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle(L10n.text("entry.edit.title", "Edit Entry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "Save")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .appScreenBackground()
    }
}

// MARK: - Meetings Sub-Page

/// Sub-page listing all meetings and events linked to a friend.
struct FriendMeetingsView: View {
    @Bindable var friend: Friend
    @State private var isPastExpanded = false
    @State private var showAllUpcoming = false

    private let upcomingLimit = 5

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var upcoming: [Meeting] {
        friend.meetings
            .filter { $0.startDate >= startOfToday }
            .sorted { $0.startDate < $1.startDate }
    }

    private var past: [Meeting] {
        friend.meetings
            .filter { $0.startDate < startOfToday }
            .sorted { $0.startDate > $1.startDate }
    }

    private var visibleUpcoming: [Meeting] {
        showAllUpcoming ? upcoming : Array(upcoming.prefix(upcomingLimit))
    }

    var body: some View {
        List {
            if !upcoming.isEmpty {
                Section(L10n.text("meeting.section.upcoming", "Upcoming")) {
                    ForEach(visibleUpcoming) { meeting in
                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                            meetingRow(meeting)
                        }
                        .listRowBackground(AppTheme.subtleFill)
                    }
                    if upcoming.count > upcomingLimit && !showAllUpcoming {
                        Button {
                            withAnimation { showAllUpcoming = true }
                        } label: {
                            Text(L10n.text("meeting.show_more", "+%d more", upcoming.count - upcomingLimit))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.subtleFill)
                    }
                }
            }
            if !past.isEmpty {
                Section {
                    if isPastExpanded {
                        ForEach(past) { meeting in
                            NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                                meetingRow(meeting)
                            }
                            .listRowBackground(AppTheme.subtleFill)
                        }
                    }
                } header: {
                    Button {
                        withAnimation { isPastExpanded.toggle() }
                    } label: {
                        HStack {
                            Text(L10n.text("meeting.section.past", "Past"))
                            Spacer()
                            Image(systemName: isPastExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(L10n.text("friend.section.history", "Meeting / Event History"))
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if upcoming.isEmpty && past.isEmpty {
                ContentUnavailableView {
                    Label(
                        L10n.text("friend.section.history", "Meeting / Event History"),
                        systemImage: "clock.arrow.circlepath"
                    )
                } description: {
                    Text(L10n.text(
                        "friend.history.empty",
                        "No meetings or events yet. Add one in the Calendar tab."
                    ))
                }
            }
        }
        .appScreenBackground()
    }

    private func meetingRow(_ meeting: Meeting) -> some View {
        HStack(spacing: 12) {
            Image(systemName: meeting.kind == .meeting ? "person.2.fill" : "flag.fill")
                .font(.title3)
                .foregroundStyle(meeting.kind == .meeting ? AppTheme.accent : AppTheme.event)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(meeting.displayTitle)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(
                    meeting.kind == .meeting
                        ? "\(meeting.startDate.formatted(date: .abbreviated, time: .shortened)) – \(meeting.endDate.formatted(date: .omitted, time: .shortened))"
                        : meeting.startDate.formatted(date: .abbreviated, time: .shortened)
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if !meeting.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(meeting.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Gift Ideas Sub-Page

/// Sub-page for managing gift ideas associated with a friend.
struct FriendGiftsView: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddGiftIdea = false
    @State private var editingGiftIdea: GiftIdea?

    private var editingSheetBinding: Binding<Bool> {
        Binding(
            get: { editingGiftIdea != nil },
            set: { if !$0 { editingGiftIdea = nil } }
        )
    }

    private var sorted: [GiftIdea] {
        friend.giftIdeas.sorted { $0.createdAt > $1.createdAt }
    }

    private var openIdeas: [GiftIdea] { sorted.filter { !$0.isGifted } }
    private var giftedIdeas: [GiftIdea] { sorted.filter(\.isGifted) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            giftList
            addFAB
        }
        .navigationTitle(L10n.text("friend.section.gift_ideas", "Gift Ideas"))
        .navigationBarTitleDisplayMode(.large)
        .appScreenBackground()
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGiftIdeaSheet { title, note in
                addGiftIdea(title: title, note: note)
            }
        }
        .sheet(isPresented: editingSheetBinding) {
            if let idea = editingGiftIdea {
                EditGiftIdeaSheet(idea: idea)
            }
        }
    }

    private var giftList: some View {
        List {
            openSection
            completedSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay {
            if openIdeas.isEmpty && giftedIdeas.isEmpty {
                ContentUnavailableView {
                    Label(
                        L10n.text("friend.section.gift_ideas", "Gift Ideas"),
                        systemImage: "gift.fill"
                    )
                } description: {
                    Text(L10n.text("friend.gifts.empty", "No gift ideas yet."))
                }
            }
        }
    }

    @ViewBuilder
    private var openSection: some View {
        if !openIdeas.isEmpty {
            Section {
                ForEach(openIdeas) { idea in
                    giftRow(idea).listRowBackground(AppTheme.subtleFill)
                }
                .onDelete { offsets in
                    offsets.map { openIdeas[$0] }.forEach { modelContext.delete($0) }
                }
            }
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        if !giftedIdeas.isEmpty {
            Section(L10n.text("friend.gifts.gifted.section", "Completed")) {
                ForEach(giftedIdeas) { idea in
                    giftRow(idea).listRowBackground(AppTheme.subtleFill)
                }
                .onDelete { offsets in
                    offsets.map { giftedIdeas[$0] }.forEach { modelContext.delete($0) }
                }
            }
        }
    }

    private var addFAB: some View {
        Button { showingAddGiftIdea = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
        }
        .glassEffect(in: Circle())
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    @ViewBuilder
    private func giftRow(_ idea: GiftIdea) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3)) { idea.isGifted.toggle() }
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

            VStack(alignment: .leading, spacing: 3) {
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
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { editingGiftIdea = idea }
    }

    private func addGiftIdea(title: String, note: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let idea = GiftIdea(
            title: trimmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(idea)
        friend.giftIdeas.append(idea)
    }
}
