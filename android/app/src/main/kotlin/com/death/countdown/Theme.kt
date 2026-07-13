package com.death.countdown

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val DarkRed = Color(0xFFCC0000)
val NumberWhite = Color.White
val LabelGray = Color(0xFFBDBDBD)

private val Colors = darkColorScheme(
    primary = DarkRed,
    background = Color.Black,
    surface = Color.Black,
    onBackground = Color.White,
    onSurface = Color.White,
)

private val Type = Typography(
    bodyLarge = TextStyle(fontFamily = FontFamily.Monospace, color = Color.White, fontSize = 16.sp),
    titleLarge = TextStyle(fontFamily = FontFamily.Monospace, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold),
    labelLarge = TextStyle(fontFamily = FontFamily.Monospace, color = DarkRed, fontSize = 14.sp, fontWeight = FontWeight.Bold),
)

@Composable
fun CountdownTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = Colors, typography = Type, content = content)
