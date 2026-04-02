import SwiftUI
import SwiftData

/// Compact, searchable multi-select view for assigning friends.
struct FriendMultiSelectView: View {
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
