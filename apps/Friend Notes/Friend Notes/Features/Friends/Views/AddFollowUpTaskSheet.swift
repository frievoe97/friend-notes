import SwiftUI
import SwiftData

/// Sheet for creating a new follow-up task with due date and optional note.
struct AddFollowUpTaskSheet: View {
    /// Uses environment dismissal to close after save/cancel.
    @Environment(\.dismiss) private var dismiss
    /// Local title draft. Required before save is enabled.
    @State private var title = ""
    /// Local optional note draft.
    @State private var note = ""
    /// Local due date-time draft.
    @State private var dueDate = FiveMinuteDateTimePicker.roundedToFiveMinutes(Date().addingTimeInterval(60 * 60))
    /// Selected optional friend assignment.
    @State private var selectedFriendID: PersistentIdentifier?
    /// Controls due date-time picker presentation.
    @State private var showingDueDatePicker = false
    /// Controls friend picker presentation.
    @State private var showingFriendPicker = false
    /// Tracks keyboard focus for title/note field transitions.
    @FocusState private var focusedField: Field?

    /// Candidate friends that can be assigned to this task.
    let allFriends: [Friend]

    /// Callback that receives raw form values when save is tapped.
    ///
    /// - Important: The caller owns validation beyond required title and model persistence.
    let onSave: (String, String, Date, PersistentIdentifier?) -> Void

    /// Focus targets used by sequential keyboard navigation.
    private enum Field {
        case title
        case note
    }

    /// Creates the sheet with optional friend assignment support.
    ///
    /// - Parameters:
    ///   - allFriends: Assignable friend choices. Empty keeps the sheet unassigned-only.
    ///   - initiallySelectedFriendID: Optional preselected friend.
    ///   - onSave: Save callback containing title, note, due date, and selected friend identifier.
    init(
        allFriends: [Friend] = [],
        initiallySelectedFriendID: PersistentIdentifier? = nil,
        onSave: @escaping (String, String, Date, PersistentIdentifier?) -> Void
    ) {
        self.allFriends = allFriends
        self.onSave = onSave
        _selectedFriendID = State(initialValue: initiallySelectedFriendID)
    }

    /// Resolves the selected friend model from local selection state.
    private var selectedFriend: Friend? {
        allFriends.first(where: { $0.persistentModelID == selectedFriendID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        fieldLabel(L10n.text("followup.field.title", "Title"))
                        TextField("", text: $title)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .note }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        fieldLabel(L10n.text("followup.field.due", "Due"))
                        Button {
                            showingDueDatePicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.body)
                                    .foregroundStyle(.primary)
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

                    if !allFriends.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            fieldLabel(L10n.text("common.friend", "Friend"))
                            assigneeMenu
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        fieldLabel(L10n.text("followup.field.note", "Note"))
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
            .navigationTitle(L10n.text("followup.new.title", "New To-Do"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(L10n.text("common.cancel", "Cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(title, note, dueDate, selectedFriendID)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(L10n.text("common.save", "Save"))
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
        .sheet(isPresented: $showingDueDatePicker) {
            DateTimeWheelPickerSheet(
                title: L10n.text("followup.field.due", "Due"),
                initialDate: dueDate
            ) { selectedDate in
                dueDate = selectedDate
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            GiftAssigneePickerSheet(
                allFriends: allFriends,
                selectedFriendID: $selectedFriendID
            )
        }
        .appScreenBackground()
    }

    /// Applies the shared label style used above form inputs.
    ///
    /// - Parameter text: Label text rendered above an input.
    /// - Returns: Styled label view.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    /// Opens a picker that assigns one friend or leaves the task unassigned.
    private var assigneeMenu: some View {
        Button {
            showingFriendPicker = true
        } label: {
            HStack(spacing: 10) {
                if let selectedFriend {
                    AvatarView(friend: selectedFriend, size: 28)
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
}
