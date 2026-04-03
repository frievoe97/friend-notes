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
    static let followUp = Color("SemanticFollowUp")

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
