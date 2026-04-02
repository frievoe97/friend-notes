import SwiftUI
import UIKit
import SafariServices

/// Utility for forcing first-responder resignation when focus state alone is insufficient.
enum Keyboard {
    /// Attempts to dismiss the currently active keyboard responder.
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - In-App Browser

/// Lightweight Safari sheet wrapper for opening links without leaving the app.
struct InAppBrowserView: UIViewControllerRepresentable {
    /// URL to open inside the embedded browser.
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No-op: SFSafariViewController is configured on creation.
    }
}

// MARK: - Date Time Picker

/// UIKit-backed date-time picker constrained to 5-minute increments.
struct FiveMinuteDateTimePicker: UIViewRepresentable {
    /// Bound date value.
    @Binding var selection: Date
    /// Optional lower bound for selectable values.
    var minimumDate: Date?
    /// Optional upper bound for selectable values.
    var maximumDate: Date?
    /// Visual picker style (`.compact` by default, `.wheels` for sheet pickers).
    var preferredStyle: UIDatePickerStyle = .compact

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = preferredStyle
        picker.locale = .current
        picker.minuteInterval = 5
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .vertical)
        picker.setContentHuggingPriority(.required, for: .horizontal)
        picker.setContentHuggingPriority(.required, for: .vertical)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.minimumDate = minimumDate
        uiView.maximumDate = maximumDate
        uiView.minuteInterval = 5
        let roundedSelection = Self.roundedToFiveMinutes(selection)
        if abs(uiView.date.timeIntervalSince(roundedSelection)) > 0.5 {
            uiView.date = roundedSelection
        }
        if abs(selection.timeIntervalSince(roundedSelection)) > 0.5 {
            DispatchQueue.main.async {
                selection = roundedSelection
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    /// Rounds a date to the nearest 5-minute mark.
    ///
    /// - Parameter date: Source date.
    /// - Returns: Rounded date using current calendar context.
    static func roundedToFiveMinutes(_ date: Date) -> Date {
        let interval = date.timeIntervalSinceReferenceDate
        let rounded = (interval / 300.0).rounded() * 300.0
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    final class Coordinator: NSObject {
        @Binding private var selection: Date

        init(selection: Binding<Date>) {
            _selection = selection
        }

        @objc func valueChanged(_ sender: UIDatePicker) {
            let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(sender.date)
            sender.setDate(rounded, animated: false)
            selection = rounded
        }
    }
}

// MARK: - AvatarView

/// Circular avatar that renders deterministic initials and color from a name string.
struct AvatarView: View {
    /// Display name used to derive initials and color.
    let name: String
    /// Avatar diameter in points.
    let size: CGFloat

    private var initials: String {
        let words = name.split(separator: " ").map(String.init)
        let letters = words.prefix(2).compactMap { $0.first }
        return letters.map(String.init).joined().uppercased()
    }

    private var backgroundColor: Color {
        let palette: [Color] = [
            AppTheme.accent,
            AppTheme.event,
            AppTheme.birthday,
            .teal,
            .indigo,
            .mint,
            .cyan,
            .blue
        ]
        guard !name.isEmpty else { return .gray.opacity(0.85) }
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }

    var body: some View {
        Circle()
            .fill(backgroundColor.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
    }
}

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

// MARK: - FlowLayout

/// Custom wrapping layout that flows child views across rows.
struct FlowLayout: Layout {
    /// Horizontal and vertical spacing between items.
    var spacing: CGFloat = 8

    /// Calculates required container size for wrapping children.
    ///
    /// - Parameters:
    ///   - proposal: Proposed container size.
    ///   - subviews: Child subviews to arrange.
    ///   - cache: Layout cache (unused).
    /// - Returns: Computed layout size.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > containerWidth && i > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: containerWidth, height: height + rowHeight)
    }

    /// Places subviews into wrapped rows within the provided bounds.
    ///
    /// - Parameters:
    ///   - bounds: Available bounds for placement.
    ///   - proposal: Proposed container size.
    ///   - subviews: Child subviews to place.
    ///   - cache: Layout cache (unused).
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        var rowItems: [(Subviews.Element, CGSize, CGFloat)] = []

        func commitRow() {
            for (subview, size, originX) in rowItems {
                subview.place(at: CGPoint(x: originX, y: y), proposal: ProposedViewSize(size))
            }
            y += rowHeight + spacing
            rowHeight = 0
            rowItems.removeAll()
            x = bounds.minX
        }

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, !rowItems.isEmpty {
                commitRow()
            }
            rowItems.append((subview, size, x))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        for (subview, size, originX) in rowItems {
            subview.place(at: CGPoint(x: originX, y: y), proposal: ProposedViewSize(size))
        }
    }
}

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
