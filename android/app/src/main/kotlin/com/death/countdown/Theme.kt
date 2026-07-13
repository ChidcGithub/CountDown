package com.death.countdown

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.unit.sp
import com.death.countdown.R

val DarkRed = Color(0xFFCC0000)
val NumberWhite = Color.White
val LabelGray = Color(0xFFBDBDBD)

// Google Sans Flex (OFL 1.1) bundled in res/font/google_sans_flex.ttf
val AppFontFamily = FontFamily(
    Font(R.font.google_sans_flex, FontWeight.Normal),
    Font(R.font.google_sans_flex, FontWeight.Medium),
    Font(R.font.google_sans_flex, FontWeight.SemiBold),
    Font(R.font.google_sans_flex, FontWeight.Bold),
    Font(R.font.google_sans_flex, FontWeight.ExtraBold),
    Font(R.font.google_sans_flex, FontWeight.Black),
)

private val Colors = darkColorScheme(
    primary = DarkRed,
    background = Color.Black,
    surface = Color.Black,
    onBackground = Color.White,
    onSurface = Color.White,
)

private val Type = Typography(
    bodyLarge = TextStyle(fontFamily = AppFontFamily, color = Color.White, fontSize = 16.sp),
    titleLarge = TextStyle(fontFamily = AppFontFamily, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold),
    labelLarge = TextStyle(fontFamily = AppFontFamily, color = DarkRed, fontSize = 14.sp, fontWeight = FontWeight.Bold),
)

@Composable
fun CountdownTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = Colors, typography = Type, content = content)
