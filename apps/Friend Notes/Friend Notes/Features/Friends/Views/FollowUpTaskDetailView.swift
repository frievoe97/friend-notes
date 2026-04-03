import SwiftUI
import SwiftData

/// Detail view for one follow-up task with dedicated read and edit modes.
struct FollowUpTaskDetailView: View {
    /// Uses environment dismissal for delete flow.
    @Environment(\.dismiss) private var dismiss
    /// SwiftData context used for destructive delete persistence.
    @Environment(\.modelContext) private var modelContext
    /// Bound persisted follow-up task displayed and edited by this screen.
    @Bindable var task: FollowUpTask

    /// Local mode state to switch between read and edit presentation.
    @State private var mode: Mode = .view
    /// Local title draft to isolate edits until save.
    @State private var draftTitle: String
    /// Local note draft to isolate edits until save.
    @State private var draftNote: String
    /// Local due date draft to isolate edits until save.
    @State private var draftDueDate: Date
    /// Local completion draft to isolate edits until save.
    @State private var draftIsCompleted: Bool
    /// Controls due date-time picker presentation.
    @State private var showingDueDatePicker = false
    /// Controls destructive delete confirmation.
    @State private var showingDeleteAlert = false
    /// Tracks keyboard focus for title/note input flow.
    @FocusState private var focusedField: Field?

    private enum Mode {
        case view
        case edit
    }

    private enum Field {
        case title
        case note
    }

    /// Shared minimum height used by multiline note cards across read/edit modes.
    private let noteCardMinHeight: CGFloat = 120

    /// Creates a detail screen backed by one persisted task.
    ///
    /// - Parameter task: Persisted task displayed by this screen.
    /// - Note: Draft state is seeded from `task` so cancel can fully revert edit mode.
    init(task: FollowUpTask) {
        self.task = task
        _draftTitle = State(initialValue: task.title)
        _draftNote = State(initialValue: task.note)
        _draftDueDate = State(initialValue: task.dueDate)
        _draftIsCompleted = State(initialValue: task.isCompleted)
    }

    /// Indicates whether editable form controls should be shown.
    private var isEditing: Bool {
        mode == .edit
    }

    /// Navigation title derived from current mode-specific title source.
    private var titleForNavigation: String {
        let source = isEditing ? draftTitle : task.title
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("followup.untitled", "Untitled To-Do") : trimmed
    }

    /// Enables save only when the required title is non-empty.
    private var canSave: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Human-readable due date used in cards.
    private var dueDateText: String {
        task.dueDate.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
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
        .navigationBarBackButtonHidden(isEditing)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingDueDatePicker) {
            DateTimeWheelPickerSheet(
                title: L10n.text("followup.field.due", "Due"),
                initialDate: draftDueDate
            ) { selectedDate in
                draftDueDate = selectedDate
            }
        }
        .alert(L10n.text("followup.delete.title", "Delete To-Do?"), isPresented: $showingDeleteAlert) {
            Button(L10n.text("common.delete", "Delete"), role: .destructive) {
                deleteTask()
            }
            Button(L10n.text("common.cancel", "Cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("common.delete_irreversible", "This action cannot be undone."))
        }
        .appScreenBackground()
    }

    @ViewBuilder
    /// Renders read-only card content for view mode.
    private var readOnlyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel(L10n.text("followup.field.title", "Title"))
            readOnlyRow(value: task.title)
        }

        VStack(alignment: .leading, spacing: 14) {
            fieldLabel(L10n.text("followup.field.due", "Due"))
            readOnlyRow(value: dueDateText)
        }

        VStack(alignment: .leading, spacing: 14) {
            fieldLabel(L10n.text("followup.field.note", "Note"))
            readOnlyMultilineRow(value: task.note.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if let friend = task.friend {
            VStack(alignment: .leading, spacing: 14) {
                fieldLabel(L10n.text("common.friend", "Friend"))
                NavigationLink(destination: FriendDetailView(friend: friend)) {
                    HStack {
                        VStack(spacing: 6) {
                            AvatarView(friend: friend, size: 48)
                            Text(friend.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(width: 64)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    /// Renders editable form controls for edit mode.
    private var editableContent: some View {
        let canClearTitle = !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel(L10n.text("followup.field.title", "Title"))
            HStack(spacing: 8) {
                TextField("", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .note }

                Button {
                    draftTitle = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
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

        VStack(alignment: .leading, spacing: 14) {
            fieldLabel(L10n.text("followup.field.due", "Due"))
            Button {
                showingDueDatePicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(draftDueDate.formatted(date: .abbreviated, time: .shortened))
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

        let canClearNote = !draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel(L10n.text("followup.field.note", "Note"))
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
                        .foregroundStyle(.tertiary)
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

        Toggle(L10n.text("followup.mark_done", "Mark as done"), isOn: $draftIsCompleted)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label(L10n.text("followup.delete.button", "Delete To-Do"), systemImage: "trash")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    /// Builds toolbar actions for view and edit modes.
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    cancelEditing()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel(L10n.text("common.cancel", "Cancel"))
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    saveChanges()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(!canSave)
                .accessibilityLabel(L10n.text("common.save", "Save"))
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.text("common.done", "Done")) {
                    focusedField = nil
                    Keyboard.dismiss()
                }
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    beginEditing()
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel(L10n.text("common.edit", "Edit"))
            }
        }
    }

    /// Enters edit mode and refreshes drafts from persisted model values.
    private func beginEditing() {
        draftTitle = task.title
        draftNote = task.note
        draftDueDate = task.dueDate
        draftIsCompleted = task.isCompleted
        mode = .edit
    }

    /// Leaves edit mode without persisting draft changes.
    private func cancelEditing() {
        draftTitle = task.title
        draftNote = task.note
        draftDueDate = task.dueDate
        draftIsCompleted = task.isCompleted
        focusedField = nil
        Keyboard.dismiss()
        mode = .view
    }

    /// Persists current drafts into the bound model and returns to view mode.
    private func saveChanges() {
        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        task.title = trimmedTitle
        task.note = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        task.dueDate = draftDueDate
        task.isCompleted = draftIsCompleted
        task.completedAt = draftIsCompleted ? (task.completedAt ?? Date()) : nil

        focusedField = nil
        Keyboard.dismiss()
        mode = .view
    }

    /// Deletes the bound follow-up task from SwiftData and dismisses the screen.
    private func deleteTask() {
        focusedField = nil
        Keyboard.dismiss()
        modelContext.delete(task)
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not delete follow-up task: \(error)")
        }
        dismiss()
    }

    /// Applies shared field-label styling.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    /// Renders a single-line read-only value card.
    private func readOnlyRow(value: String) -> some View {
        Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "–" : value)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Renders a multiline read-only card for note content.
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
}
