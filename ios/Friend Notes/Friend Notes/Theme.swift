import SwiftUI

/// Centralized color tokens for a consistent modern light/dark palette.
enum AppTheme {
    /// Primary interactive color used for tint and key actions.
    static let accent = Color("BrandAccent")
    /// Subtle accent background for selected chips and highlights.
    static let accentSoft = Color("BrandAccentSoft")
    /// Very light neutral fill for chips and lightweight list rows.
    static let subtleFill = Color.primary.opacity(0.08)
    /// Slightly stronger subtle fill for selected chips.
    static let subtleFillSelected = Color.primary.opacity(0.12)

    /// Card-like neutral background used for grouped content blocks.
    static let surfaceCard = Color.clear
    /// Smaller chip/input surface color.
    static let surfaceChip = Color.clear
    /// Slightly elevated surface used for editable containers.
    static let surfaceElevated = Color.clear

    /// Semantic timeline colors.
    static let birthday = Color("SemanticBirthday")
    static let event = Color("SemanticEvent")

    /// Destructive semantic colors.
    static let danger = Color("SemanticDanger")
    static let dangerSoft = Color.clear

    /// Global background gradient colors.
    static let backgroundTop = Color("BackgroundTop")
    static let backgroundBottom = Color("BackgroundBottom")
    /// Decorative gradient orb colors for richer depth.
    static let backgroundOrbPrimary = Color("BackgroundOrbPrimary")
    static let backgroundOrbSecondary = Color("BackgroundOrbSecondary")
    /// Subtle stroke color for elevated cards.
    static let cardBorder = Color.clear
}

/// Full-screen decorative gradient background used across major screens.
struct AppGradientBackground: View {
    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.backgroundTop,
                        AppTheme.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(AppTheme.backgroundOrbPrimary.opacity(0.4))
                    .frame(width: 500, height: 500)
                    .blur(radius: 120)
                    .offset(x: -180, y: -180)

                Circle()
                    .fill(AppTheme.backgroundOrbSecondary.opacity(0.35))
                    .frame(width: 600, height: 600)
                    .blur(radius: 140)
                    .offset(x: 200, y: 200)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Gradient background variant intended for sheets so intrinsic sizing remains intact.
struct SheetGradientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.backgroundOrbPrimary.opacity(0.36))
                .frame(width: 260, height: 260)
                .blur(radius: 72)
                .offset(x: -120, y: -90)

            Circle()
                .fill(AppTheme.backgroundOrbSecondary.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 86)
                .offset(x: 130, y: 130)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

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
