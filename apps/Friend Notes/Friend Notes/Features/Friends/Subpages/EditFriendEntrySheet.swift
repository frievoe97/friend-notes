import SwiftUI
import SwiftData

/// Edits an existing friend entry using local draft state before commit.
///
/// - Note: The view writes back to the bound `FriendEntry` only when the user confirms save.
struct EditFriendEntrySheet: View {
    /// Uses environment dismissal so the caller remains the source of presentation state.
    @Environment(\.dismiss) private var dismiss
    /// Binds directly to the persisted entry model to apply confirmed mutations.
    @Bindable var entry: FriendEntry
    /// Title draft that isolates intermediate changes from persistence until save.
    @State private var draftTitle: String
    /// Optional note draft that isolates intermediate changes from persistence until save.
    @State private var draftNote: String
    /// Tracks active input focus to support keyboard navigation and dismissal.
    @FocusState private var focusedField: Field?

    /// Focus targets used by the edit form.
    private enum Field {
        case title
        case note
    }

    /// Creates an editor initialized from the current model values.
    ///
    /// - Parameter entry: Persisted entry being edited.
    /// - Note: Draft state is seeded once so cancel can restore original persisted values.
    init(entry: FriendEntry) {
        self.entry = entry
        _draftTitle = State(initialValue: entry.title)
        _draftNote = State(initialValue: entry.note)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let canClearTitle = !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearNote = !draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        fieldLabel(L10n.text("entry.name", "Title"))
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
                        fieldLabel(L10n.text("entry.note", "Note (optional)"))
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
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle(navigationTitleText)
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
                        entry.title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        entry.note = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .appScreenBackground()
    }

    /// Dynamic title that mirrors the edited entry title.
    private var navigationTitleText: String {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("entry.edit.title", "Edit Entry") : trimmed
    }

    /// Applies a shared label style for entry edit fields.
    ///
    /// - Parameter text: Field title rendered above an input.
    /// - Returns: Styled field label view.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
