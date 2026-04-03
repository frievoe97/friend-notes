import SwiftUI

/// Sheet containing a wheel-style birthday picker with cancel/save actions.
struct BirthdayPickerSheet: View {
    /// Uses environment dismissal to close after save/cancel.
    @Environment(\.dismiss) private var dismiss
    /// Local picker value so users can cancel without mutating parent state.
    @State private var selectedDate: Date

    /// Navigation title shown in the sheet header.
    let title: String
    /// Source birthday date used to initialize local selection.
    let initialDate: Date
    /// Callback invoked when the user confirms the selected date.
    ///
    /// - Important: The caller owns persistence of the selected value.
    let onSave: (Date) -> Void

    /// Creates a birthday picker sheet with an initial date and save callback.
    ///
    /// - Parameters:
    ///   - title: Navigation title shown in the sheet.
    ///   - initialDate: Date preselected when the sheet opens.
    ///   - onSave: Callback triggered when the user confirms.
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(L10n.text("common.cancel", "Cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(selectedDate)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(L10n.text("common.save", "Save"))
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
