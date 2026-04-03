import SwiftUI
import SwiftData

/// Single-select sheet for assigning one friend (or no friend) to a gift.
struct GiftAssigneePickerSheet: View {
    /// Uses environment dismissal to close immediately after selection.
    @Environment(\.dismiss) private var dismiss
    /// Candidate friends available for assignment.
    let allFriends: [Friend]
    /// Binding to the selected assignee identifier in the parent form.
    ///
    /// - Note: `nil` represents "no person assigned".
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
                                    AvatarView(friend: friend, size: 30)
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(L10n.text("common.done", "Done"))
                }
            }
        }
        .appScreenBackground()
    }
}
