import SwiftUI

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
