import SwiftUI
import SwiftData

struct FriendGiftsView: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddGiftIdea = false
    @State private var selectedGiftIdea: GiftIdea?

    private var detailSheetBinding: Binding<Bool> {
        Binding(
            get: { selectedGiftIdea != nil },
            set: { if !$0 { selectedGiftIdea = nil } }
        )
    }

    private var sorted: [GiftIdea] {
        friend.giftIdeas.sorted { $0.createdAt > $1.createdAt }
    }

    private var openIdeas: [GiftIdea] { sorted.filter { !$0.isGifted } }
    private var giftedIdeas: [GiftIdea] { sorted.filter(\.isGifted) }

    var body: some View {
        giftList
        .navigationTitle(L10n.text("friend.section.gift_ideas", "Gift Ideas"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddGiftIdea = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel(L10n.text("common.add", "Add"))
            }
        }
        .appScreenBackground()
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGiftIdeaSheet { title, note, url in
                addGiftIdea(title: title, note: note, url: url)
            }
        }
        .sheet(isPresented: detailSheetBinding) {
            if let idea = selectedGiftIdea {
                GiftIdeaDetailSheet(idea: idea, allowsAssigneeEditing: false)
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
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { selectedGiftIdea = idea }
    }

    private func addGiftIdea(title: String, note: String, url: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let idea = GiftIdea(
            title: trimmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(idea)
        friend.giftIdeas.append(idea)
    }
}
