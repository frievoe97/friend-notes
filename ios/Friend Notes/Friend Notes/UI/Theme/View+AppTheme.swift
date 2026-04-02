import SwiftUI

/// Applies a consistent gradient background for full-screen views.
private struct AppScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                AppGradientBackground()
            }
            .background(Color.clear)
    }
}

/// Applies a modern, frosted card treatment with border and subtle shadow.
private struct AppGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
    }
}

/// Convenience theming helpers applied across SwiftUI screens.
extension View {
    /// Places the app-wide decorative gradient behind the current screen.
    ///
    /// - Returns: The view with theme background applied.
    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }

    /// Wraps content in a modern glass-like card container.
    ///
    /// - Parameter cornerRadius: Corner radius used for card shape.
    /// - Returns: The view wrapped in a themed card.
    func appGlassCard(cornerRadius: CGFloat = 14) -> some View {
        modifier(AppGlassCardModifier(cornerRadius: cornerRadius))
    }
}
