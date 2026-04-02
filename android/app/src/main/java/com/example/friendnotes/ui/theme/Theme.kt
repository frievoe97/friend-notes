package com.example.friendnotes.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

// Fallback-Farbschema für Geräte ohne Dynamic Color (< Android 12)
private val LightColorScheme = lightColorScheme(
    primary = FallbackPrimaryLight,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDDE3FF),
    onPrimaryContainer = Color(0xFF001258),
    secondary = Color(0xFF5B5D72),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFDFE0F9),
    onSecondaryContainer = Color(0xFF181A2C),
    tertiary = Color(0xFFE75C93),
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFFFD9E3),
    onTertiaryContainer = Color(0xFF3E0021),
    error = SemanticDangerLight,
    background = Color(0xFFFBF8FF),
    onBackground = Color(0xFF1B1B21),
    surface = Color(0xFFFBF8FF),
    onSurface = Color(0xFF1B1B21),
    surfaceVariant = Color(0xFFE3E1EC),
    onSurfaceVariant = Color(0xFF46464F),
    outline = Color(0xFF777680),
    outlineVariant = Color(0xFFC7C5D0),
    surfaceContainer = Color(0xFFEEEBF8),
    surfaceContainerLow = Color(0xFFF4F1FF),
    surfaceContainerHigh = Color(0xFFE8E5F4),
    surfaceContainerLowest = Color(0xFFFFFFFF),
)

private val DarkColorScheme = darkColorScheme(
    primary = FallbackPrimaryDark,
    onPrimary = Color(0xFF001E8C),
    primaryContainer = Color(0xFF2048C4),
    onPrimaryContainer = Color(0xFFDDE3FF),
    secondary = Color(0xFFC3C2DD),
    onSecondary = Color(0xFF2D2F42),
    secondaryContainer = Color(0xFF434559),
    onSecondaryContainer = Color(0xFFDFE0F9),
    tertiary = Color(0xFFFF7CAF),
    onTertiary = Color(0xFF66003C),
    tertiaryContainer = Color(0xFF8F1256),
    onTertiaryContainer = Color(0xFFFFD9E3),
    error = SemanticDangerDark,
    background = Color(0xFF131318),
    onBackground = Color(0xFFE4E1E9),
    surface = Color(0xFF131318),
    onSurface = Color(0xFFE4E1E9),
    surfaceVariant = Color(0xFF46464F),
    onSurfaceVariant = Color(0xFFC7C5D0),
    outline = Color(0xFF918F9A),
    outlineVariant = Color(0xFF46464F),
    surfaceContainer = Color(0xFF1F1F27),
    surfaceContainerLow = Color(0xFF1B1B23),
    surfaceContainerHigh = Color(0xFF262630),
    surfaceContainerLowest = Color(0xFF0E0E16),
)

@Composable
fun FriendNotesTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    // MaterialTheme zuerst anwenden, dann Extra-Farben aus dem Schema ableiten
    MaterialTheme(colorScheme = colorScheme, typography = Typography) {
        val scheme = MaterialTheme.colorScheme
        val extra = FriendNotesExtraColors(
            backgroundTop = if (darkTheme) BackgroundTopDark else BackgroundTopLight,
            backgroundBottom = if (darkTheme) BackgroundBottomDark else BackgroundBottomLight,
            backgroundOrbPrimary = if (darkTheme) BackgroundOrbPrimaryDark else BackgroundOrbPrimaryLight,
            backgroundOrbSecondary = if (darkTheme) BackgroundOrbSecondaryDark else BackgroundOrbSecondaryLight,
            semanticBirthday = if (darkTheme) SemanticBirthdayDark else SemanticBirthdayLight,
            semanticEvent = if (darkTheme) SemanticEventDark else SemanticEventLight,
            semanticDanger = scheme.error,
            surfaceCard = scheme.surfaceContainerLow.copy(alpha = if (darkTheme) 0.52f else 0.58f),
            surfaceChip = scheme.surfaceContainerHigh.copy(alpha = if (darkTheme) 0.46f else 0.5f),
            surfaceElevated = scheme.surfaceContainerLowest.copy(alpha = if (darkTheme) 0.4f else 0.46f),
            cardBorder = scheme.outlineVariant.copy(alpha = if (darkTheme) 0.3f else 0.22f),
            brandAccentSoft = scheme.primaryContainer,
            subtleFill = scheme.primary.copy(alpha = 0.08f),
            subtleFillSelected = scheme.secondaryContainer.copy(alpha = if (darkTheme) 0.52f else 0.58f),
        )
        CompositionLocalProvider(LocalFriendNotesExtraColors provides extra) {
            content()
        }
    }
}

object FriendNotesThemeExtras {
    val colors: FriendNotesExtraColors
        @Composable
        get() = LocalFriendNotesExtraColors.current
}
