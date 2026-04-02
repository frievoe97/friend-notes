import SwiftUI

// MARK: - TagChip

/// Reusable capsule chip view for displaying and removing a tag token.
struct TagChip: View {
    /// Tag text to display.
    let tag: String
    /// Callback fired when the remove button is tapped.
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 3) {
            Text(tag)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.borderless)
        }
        .padding(.leading, 10)
        .padding(.trailing, 7)
        .padding(.vertical, 6)
        .background(AppTheme.subtleFill, in: Capsule())
        .foregroundStyle(.primary)
    }
}
