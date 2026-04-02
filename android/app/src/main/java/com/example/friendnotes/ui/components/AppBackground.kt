package com.example.friendnotes.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import com.example.friendnotes.ui.theme.FriendNotesThemeExtras

@Composable
fun AppBackground(modifier: Modifier = Modifier) {
    val extra = FriendNotesThemeExtras.colors

    Box(
        modifier = modifier
            .fillMaxSize()
            .drawWithCache {
                val w = size.width
                val h = size.height

                val baseGradient = Brush.linearGradient(
                    colors = listOf(
                        extra.backgroundTop,
                        extra.backgroundBottom
                    ),
                    start = Offset(0f, 0f),
                    end = Offset(w, h)
                )

                val topGlow = Brush.radialGradient(
                    colors = listOf(
                        extra.backgroundOrbPrimary.copy(alpha = 0.22f),
                        Color.Transparent
                    ),
                    center = Offset(x = w * 0.18f, y = h * 0.12f),
                    radius = w * 0.55f
                )

                val middleGlow = Brush.radialGradient(
                    colors = listOf(
                        extra.backgroundOrbSecondary.copy(alpha = 0.18f),
                        Color.Transparent
                    ),
                    center = Offset(x = w * 0.82f, y = h * 0.34f),
                    radius = w * 0.50f
                )

                val vignette = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.04f),
                        Color.Transparent,
                        Color.Black.copy(alpha = 0.08f)
                    ),
                    startY = 0f,
                    endY = h
                )

                onDrawBehind {
                    drawRect(baseGradient)
                    drawRect(topGlow)
                    drawRect(middleGlow)
                    drawRect(vignette)
                }
            }
    )
}
