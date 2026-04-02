import SwiftUI

// MARK: - String List Editor

/// Inline editor for small string collections with add, edit, and delete actions.
struct StringListEditor: View {
    /// Placeholder shown in the add input field.
    let placeholder: String
    /// Binding to the edited string list.
    @Binding var items: [String]
    @State private var newItem = ""
    @State private var editIndex: Int?
    @State private var editValue = ""
    @FocusState private var isAddFieldFocused: Bool
    @FocusState private var focusedEditField: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            existingItemsSection
            addItemRow
        }
        .onChange(of: focusedEditField) { _, newValue in
            if newValue == nil, editIndex != nil {
                commitEdit()
            }
        }
    }

    @ViewBuilder
    private var existingItemsSection: some View {
        if !items.isEmpty {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    itemRow(index: index, item: item)
                }
            }
        }
    }

    private var addItemRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(placeholder)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                TextField("", text: $newItem, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...4)
                    .focused($isAddFieldFocused)
                    .onSubmit(addItem)
                Button(action: addItem) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.semibold))
                }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .opacity(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
                    .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(L10n.text("common.add", "Add"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .appGlassCard(cornerRadius: 14)
        .padding(.bottom, 14)
    }

    private func itemRow(index: Int, item: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            itemTextView(index: index, item: item)
            itemActionButtons(index: index)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .appGlassCard(cornerRadius: 14)
    }

    @ViewBuilder
    private func itemTextView(index: Int, item: String) -> some View {
        if editIndex == index {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("list.edit_entry", "Edit entry"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("", text: $editValue, axis: .vertical)
                    .font(.body)
                    .lineLimit(2...6)
                    .focused($focusedEditField, equals: index)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text(softWrapped(item))
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func itemActionButtons(index: Int) -> some View {
        HStack(spacing: 10) {
            if editIndex == index {
                Button(action: commitEdit) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                }
            } else {
                Button {
                    startEditing(index: index)
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                withAnimation(.spring(response: 0.3)) {
                    if editIndex == index {
                        cancelEdit()
                    }
                    items.removeSubrange(index...index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    /// Appends a unique trimmed item from the add input.
    ///
    /// - Note: Empty values and case-insensitive duplicates are ignored.
    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !items.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            newItem = ""
            return
        }
        withAnimation(.spring(response: 0.3)) {
            items.append(trimmed)
        }
        newItem = ""
    }

    /// Inserts soft wrap opportunities for long strings to prevent overflow.
    ///
    /// - Parameter value: Source text.
    /// - Returns: Text containing zero-width break opportunities.
    private func softWrapped(_ value: String) -> String {
        guard value.count > 24 else { return value }
        var result = ""
        for (index, char) in value.enumerated() {
            result.append(char)
            if index % 24 == 23 {
                result.append("\u{200B}")
            }
        }
        return result
    }

    /// Enters edit mode for a specific list row.
    ///
    /// - Parameter index: Row index to edit.
    private func startEditing(index: Int) {
        editIndex = index
        editValue = items[index]
        focusedEditField = index
    }

    /// Cancels current edit mode and clears temporary state.
    private func cancelEdit() {
        editIndex = nil
        editValue = ""
        focusedEditField = nil
    }

    /// Commits the active edit operation.
    ///
    /// - Note: Empty edited values remove the row.
    private func commitEdit() {
        guard let index = editIndex else { return }
        let trimmed = editValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            items.removeSubrange(index...index)
        } else {
            items[index] = trimmed
        }
        cancelEdit()
    }
}
