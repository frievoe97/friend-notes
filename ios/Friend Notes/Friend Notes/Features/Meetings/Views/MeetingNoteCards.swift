import SwiftUI

/// Reusable editor card used for meeting/event notes in create and edit flows.
struct NoteEditorCard<Editor: View>: View {
    @Binding var text: String
    let minHeight: CGFloat
    @ViewBuilder let editor: () -> Editor

    var body: some View {
        editor()
            .frame(minHeight: minHeight, alignment: .topLeading)
            // TextEditor has an intrinsic inner inset; compensate so edit/view spacing matches.
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .scrollContentBackground(.hidden)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Reusable read-only card used for meeting/event notes in view mode.
struct NoteReadCard: View {
    let text: String
    let emptyText: String
    let minHeight: CGFloat

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Text(trimmedText.isEmpty ? emptyText : text)
            .font(.body)
            .foregroundStyle(trimmedText.isEmpty ? .secondary : .primary)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
