package com.example.friendnotes.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

// Hintergrundfarben (Gradient + Orbs)
val BackgroundTopLight = Color(0xFFF2F6FE)
val BackgroundBottomLight = Color(0xFFD2E2FB)
val BackgroundOrbPrimaryLight = Color(0xFF497BFC)
val BackgroundOrbSecondaryLight = Color(0xFF3CA7FE)

val BackgroundTopDark = Color(0xFF0A0F1E)
val BackgroundBottomDark = Color(0xFF131E39)
val BackgroundOrbPrimaryDark = Color(0xFF536ED6)
val BackgroundOrbSecondaryDark = Color(0xFF2F8AC0)

// Semantic colors – nicht aus dem M3-Schema ableitbar
val SemanticBirthdayLight = Color(0xFFE75C93)
val SemanticEventLight = Color(0xFFF3A43A)
val SemanticDangerLight = Color(0xFFBA1A1A)

val SemanticBirthdayDark = Color(0xFFFF7CAF)
val SemanticEventDark = Color(0xFFFFC069)
val SemanticDangerDark = Color(0xFFFFB4AB)

// Fallback-Primärfarbe (für Geräte < Android 12)
val FallbackPrimaryLight = Color(0xFF3D6CF4)
val FallbackPrimaryDark = Color(0xFFBAC3FF)

@Immutable
data class FriendNotesExtraColors(
    val backgroundTop: Color,
    val backgroundBottom: Color,
    val backgroundOrbPrimary: Color,
    val backgroundOrbSecondary: Color,
    val semanticBirthday: Color,
    val semanticEvent: Color,
    val semanticDanger: Color,
    // Abgeleitet vom M3-Farbschema (werden in Theme.kt gesetzt)
    val surfaceCard: Color,
    val surfaceChip: Color,
    val surfaceElevated: Color,
    val cardBorder: Color,
    val brandAccentSoft: Color,
    val subtleFill: Color,
    val subtleFillSelected: Color,
)

val LocalFriendNotesExtraColors = staticCompositionLocalOf {
    FriendNotesExtraColors(
        backgroundTop = BackgroundTopLight,
        backgroundBottom = BackgroundBottomLight,
        backgroundOrbPrimary = BackgroundOrbPrimaryLight,
        backgroundOrbSecondary = BackgroundOrbSecondaryLight,
        semanticBirthday = SemanticBirthdayLight,
        semanticEvent = SemanticEventLight,
        semanticDanger = SemanticDangerLight,
        surfaceCard = Color(0xFFEFF3FD),
        surfaceChip = Color(0xFFE1EAFB),
        surfaceElevated = Color(0xFFFAFCFF),
        cardBorder = Color(0xFFBBCEF5),
        brandAccentSoft = Color(0xFFE7EEFF),
        subtleFill = FallbackPrimaryLight.copy(alpha = 0.08f),
        subtleFillSelected = FallbackPrimaryLight.copy(alpha = 0.12f),
    )
}
