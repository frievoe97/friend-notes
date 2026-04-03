import SwiftUI
import SwiftData

/// Creates a new friend entry for a category-specific subpage.
///
/// - Note: The sheet keeps edits in local `@State` and forwards normalized input through `onSave`.
struct AddFriendEntrySheet: View {
    /// Uses environment dismissal so the presenting view controls sheet lifetime.
    @Environment(\.dismiss) private var dismiss
    /// Local draft for the required title field. Persisted only after explicit save.
    @State private var title = ""
    /// Local draft for the optional note field.
    @State private var note = ""
    /// Tracks keyboard focus to drive next/done navigation between fields.
    @FocusState private var focusedField: Field?

    /// Placeholder shown for category-specific guidance in the title input.
    let placeholder: String
    /// Callback that commits user input in the parent context.
    ///
    /// - Important: The caller is responsible for model mutation and persistence.
    let onSave: (String, String) -> Void

    /// Focus targets used by the sheet input flow.
    private enum Field { case title, note }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        fieldLabel(L10n.text("entry.name", "Title"))
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
                        fieldLabel(L10n.text("entry.note", "Note (optional)"))
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
                        onSave(title, note)
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
        .appScreenBackground()
    }

    /// Dynamic title that mirrors the entered entry title.
    private var navigationTitleText: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.text("entry.new.title", "New Entry") : trimmed
    }

    /// Applies a shared label style for entry form fields.
    ///
    /// - Parameter text: Field title rendered above an input.
    /// - Returns: Styled field label view.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
