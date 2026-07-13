@file:OptIn(ExperimentalMaterial3Api::class, androidx.compose.ui.ExperimentalComposeUiApi::class)

package com.death.countdown

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.semantics.contentType
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import kotlin.random.Random

// ==================== Navigation ====================
sealed class Screen {
    object Loading : Screen()
    object Welcome : Screen()
    object Setup : Screen()
    object FullAgreement : Screen()
    data class Splash(val data: CountdownData) : Screen()
    data class Main(val data: CountdownData) : Screen()
    object Settings : Screen()
    object DevRed : Screen()
    object SearchUsers : Screen()
}

// ==================== App Root ====================
@Composable
fun CountdownApp(initial: Screen) {
    var screen by remember { mutableStateOf<Screen>(initial) }
    AnimatedContent(
        targetState = screen,
        transitionSpec = {
            fadeIn(animationSpec = tween(280)) togetherWith fadeOut(animationSpec = tween(180))
        },
        label = "nav",
    ) { s ->
        when (s) {
            Screen.Loading -> {
                LaunchedEffect(Unit) {
                    val isFirst = StorageService.isFirstLaunch()
                    val enc = StorageService.loadEncryptedUserData()
                    val data = StorageService.loadUserData()
                    screen = when {
                        isFirst && enc != null -> Screen.Splash(enc)
                        data != null -> Screen.Main(data)
                        else -> Screen.Welcome
                    }
                }
                LoadingScreen()
            }
            Screen.Welcome -> WelcomeScreen(
                onAgree = { screen = Screen.Setup },
                onViewFull = { screen = Screen.FullAgreement },
            )
            Screen.FullAgreement -> FullAgreementScreen(onBack = { screen = Screen.Welcome })
            Screen.Setup -> UserSetupScreen(
                onStart = { d -> screen = Screen.Main(d) }
            )
            is Screen.Splash -> SplashScreen(data = s.data, onDone = { screen = Screen.Main(s.data) })
            is Screen.Main -> MainCountdownScreen(
                data = s.data,
                onOpenSettings = { screen = Screen.Settings },
            )
            Screen.Settings -> SettingsScreen(
                onBack = { screen = Screen.Main(StorageService.loadUserData()!!) },
                onDevMode = { screen = Screen.DevRed },
                onSearchUsers = { screen = Screen.SearchUsers },
                onCleared = { screen = Screen.Welcome },
            )
            Screen.DevRed -> DevModeRedScreen(onDone = { screen = Screen.Settings })
            Screen.SearchUsers -> SearchUsersScreen(onBack = { screen = Screen.Settings })
        }
    }
}

// ==================== Loading ====================
@Composable
private fun LoadingScreen() = Box(
    Modifier.fillMaxSize().background(Color.Black),
    contentAlignment = Alignment.Center
) { CircularProgressIndicator(color = DarkRed) }

// ==================== Splash (Recovery) ====================
@Composable
private fun SplashScreen(data: CountdownData, onDone: () -> Unit) {
    val ctx = LocalContext.current
    var flash by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        repeat(5) {
            flash = true; delay(150); flash = false; delay(150)
        }
        delay(2000)
        onDone()
    }
    Box(
        Modifier.fillMaxSize().background(if (flash) DarkRed else Color.Black),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.Restore, null, Modifier.size(80.dp),
                tint = if (flash) Color.Black else DarkRed)
            Spacer(Modifier.height(20.dp))
            Text(
                "COUNTDOWN RESTORED",
                color = if (flash) Color.Black else DarkRed,
                fontFamily = AppFontFamily,
                fontSize = 28.sp, fontWeight = FontWeight.W900,
                letterSpacing = 10.sp,
            )
            Spacer(Modifier.height(20.dp))
            Text("Your countdown has been recovered",
                color = if (flash) Color.Black.copy(alpha = 0.5f) else Color.White.copy(alpha = 0.5f),
                fontSize = 16.sp)
        }
    }
}

// ==================== Welcome ====================
@Composable
private fun WelcomeScreen(onAgree: () -> Unit, onViewFull: () -> Unit) {
    var agreed by remember { mutableStateOf(false) }
    Scaffold(containerColor = Color.Black) { p ->
        Column(Modifier.padding(p).padding(24.dp).fillMaxSize()) {
            Spacer(Modifier.weight(1f))
            Icon(Icons.Default.Warning, null, Modifier.size(80.dp), tint = DarkRed)
            Spacer(Modifier.height(30.dp))
            Text("JUST FOR FUN", color = DarkRed, fontSize = 32.sp,
                fontWeight = FontWeight.Bold, fontFamily = AppFontFamily, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(10.dp))
            Text("Do not take this seriously", color = Color.White.copy(alpha = 0.7f),
                fontSize = 18.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
            Spacer(Modifier.height(40.dp))
            Text("This is purely for entertainment purposes only.",
                color = Color.White.copy(alpha = 0.6f), modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
            Spacer(Modifier.weight(1f))
            Surface(
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, DarkRed.copy(alpha = 0.8f)),
                modifier = Modifier.weight(3f)
            ) {
                Column(Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("User Agreement", color = DarkRed, fontSize = 20.sp,
                            fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                        TextButton(onClick = onViewFull) { Text("View Full", color = DarkRed) }
                    }
                    Spacer(Modifier.height(16.dp))
                    Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
                        AgreementText()
                    }
                    Spacer(Modifier.height(16.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = agreed, onCheckedChange = { agreed = it }, colors = CheckboxDefaults.colors(checkedColor = DarkRed))
                        Text("I have read and agree to the terms and conditions",
                            color = Color.White, fontSize = 12.sp)
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
            Button(
                onClick = onAgree, enabled = agreed,
                colors = ButtonDefaults.buttonColors(containerColor = DarkRed, disabledContainerColor = Color.DarkGray),
                modifier = Modifier.fillMaxWidth().height(50.dp)
            ) { Text("CONTINUE", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold) }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun FullAgreementScreen(onBack: () -> Unit) {
    Scaffold(
        containerColor = Color.Black,
        topBar = {
            TopAppBar(
                title = { Text("User Agreement") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null, tint = DarkRed) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Black)
            )
        }
    ) { p ->
        Text(AgreementFull, color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp,
            modifier = Modifier.padding(p).padding(16.dp).verticalScroll(rememberScrollState()))
    }
}

@Composable
private fun AgreementText() {
    val text = """IMPORTANT NOTICE

Please read this User Agreement carefully before using this application.

1. ENTERTAINMENT PURPOSE ONLY
This application is designed solely for entertainment purposes. The countdown timer displayed is a fictional simulation.

2. NO REAL DATA USED
The countdown calculation is based on a deterministic algorithm that combines username, birth date, and device identification.

3. NO LIABILITY
The developer shall not be held liable for any psychological, emotional, or behavioral changes.

4. FORCE MAJEURE CLAUSE
If you make life decisions based on this application's countdown and experience unexpected consequences, such events shall be considered force majeure.

5. DATA PRIVACY
This application does not collect, store, or transmit any personal information to external servers.

6. NO NETWORK COMMUNICATION
This application does not connect to the internet for any purpose.

7. USER RESPONSIBILITY
You acknowledge that you are of legal age to use this application.

8. MODIFICATION OF TERMS
The developer reserves the right to modify this agreement at any time.

9. INTELLECTUAL PROPERTY
All content within this application is the intellectual property of the developer.

10. GOVERNING LAW
This agreement shall be governed by applicable laws.

11. ADDITIONAL INFORMATION
For more information, please visit our GitHub repository:
https://github.com/ChidcGithub/CountDown

By checking the box below, you acknowledge that you have read, understood, and agree to be bound by all terms and conditions."""
    Text(text, color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp, lineHeight = 18.sp)
}

private const val AgreementFull = """COUNTDOWN APPLICATION - COMPREHENSIVE USER AGREEMENT

Last Updated: 2026

IMPORTANT LEGAL NOTICE

PLEASE READ THIS AGREEMENT CAREFULLY BEFORE USING THIS APPLICATION. THIS IS A LEGALLY BINDING AGREEMENT BETWEEN YOU AND THE DEVELOPER.

SECTION 1: NATURE OF APPLICATION

1.1 This application, named "Countdown," is a digital entertainment product designed solely for recreational and amusement purposes.

1.2 The countdown timer displayed by this application is a FICTIONAL AND FANTASY-BASED simulation. It does not represent, predict, forecast, or in any manner relate to the actual lifespan, mortality, or any aspect of the user's real-life expectancy.

1.3 This application is not intended for making any life decisions, financial planning, health-related choices, or any decisions that may affect the user's physical or mental well-being.

SECTION 2: DISCLAIMER OF WARRANTIES

2.1 THIS APPLICATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.

2.2 THE DEVELOPER EXPRESSLY DISCLAIMS ANY AND ALL LIABILITY FOR THE ACCURACY, COMPLETENESS, LEGALITY, RELIABILITY, OR USEFULNESS OF ANY INFORMATION DISPLAYED.

SECTION 3: LIMITATION OF LIABILITY

3.1 IN NO EVENT SHALL THE DEVELOPER BE LIABLE FOR ANY INDIRECT, INCIDENTAL, CONSEQUENTIAL, SPECIAL, EXEMPLARY, OR PUNITIVE DAMAGES.

3.2 THE DEVELOPER'S LIABILITY TO YOU SHALL BE LIMITED TO THE AMOUNT PAID FOR THE APPLICATION.

SECTION 4: FORCE MAJEURE

4.1 THE DEVELOPER SHALL NOT BE LIABLE FOR ANY FAILURE OR DELAY RESULTING FROM CAUSES BEYOND REASONABLE CONTROL.

4.2 Any life decisions made based on the countdown timer shall be considered FORCE MAJEURE. The developer disclaims any responsibility.

SECTION 5: USER REPRESENTATIONS

5.1 You represent that you are at least 18 years of age or have reached the age of majority.

5.2 You understand that the application is for entertainment only.

SECTION 6: DATA COLLECTION AND PRIVACY

6.1 This application collects and stores data locally on your device only. No personal information is transmitted externally.

6.2 The application does not connect to the internet for any purpose.

SECTION 7: INTELLECTUAL PROPERTY

7.1 All content within this application is the exclusive property of the developer.

7.2 You may not copy, modify, distribute, or exploit any part of this application without express written consent.

SECTION 8: PROHIBITED CONDUCT

8.1 You agree not to use the application for unlawful activity or to infringe upon the rights of others.

SECTION 9: MODIFICATION AND TERMINATION

9.1 The developer reserves the right to modify, suspend, or discontinue the application at any time.

9.2 You may terminate this agreement by ceasing to use the application.

SECTION 10: INDEMNIFICATION

10.1 You agree to indemnify and hold harmless the developer from any claims arising from your use of the application.

SECTION 11: GOVERNING LAW

11.1 This agreement shall be governed by applicable laws.

SECTION 12: MISCELLANEOUS

12.1 This agreement constitutes the entire agreement between you and the developer.

12.2 If any provision is found unenforceable, the remaining provisions shall remain in full force.

SECTION 13: ACKNOWLEDGMENT

13.1 BY USING THIS APPLICATION, YOU ACKNOWLEDGE THAT YOU HAVE READ THIS AGREEMENT AND AGREE TO BE BOUND BY ITS TERMS.

SECTION 14: CONTACT INFORMATION

For questions regarding this agreement, please visit https://github.com/ChidcGithub/CountDown.

BY PROCEEDING, YOU ACKNOWLEDGE THAT YOU HAVE READ AND UNDERSTOOD THIS ENTIRE AGREEMENT AND AGREE TO BE BOUND BY ALL OF ITS TERMS AND CONDITIONS."""

// ==================== User Setup ====================
@Composable
private fun UserSetupScreen(onStart: (CountdownData) -> Unit) {
    var name by remember { mutableStateOf("") }
    var date by remember { mutableStateOf<LocalDate?>(null) }
    var showPicker by remember { mutableStateOf(false) }
    val ctx = LocalContext.current

    if (showPicker) {
        val state = rememberDatePickerState()
        AlertDialog(
            onDismissRequest = { showPicker = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let { ms ->
                        date = Instant.ofEpochMilli(ms).atZone(ZoneId.of("UTC")).toLocalDate()
                    }
                    showPicker = false
                }) { Text("OK", color = DarkRed) }
            },
            dismissButton = { TextButton(onClick = { showPicker = false }) { Text("Cancel", color = DarkRed) } },
            text = { DatePicker(state = state) }
        )
    }

    val valid = name.isNotBlank() && date != null
    Scaffold(containerColor = Color.Black) { p ->
        Column(Modifier.padding(p).padding(24.dp).fillMaxSize()) {
            Text("Setup", color = DarkRed, fontSize = 32.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            Spacer(Modifier.height(40.dp))
            Text("Enter Your Name", color = Color.White.copy(alpha = 0.7f), fontSize = 16.sp)
            Spacer(Modifier.height(8.dp))
            OutlinedTextField(
                value = name, onValueChange = { name = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics { contentType = ContentType.Username },
                placeholder = { Text("Username", color = Color.Gray) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Next,
                ),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    cursorColor = DarkRed,
                    focusedBorderColor = DarkRed,
                    unfocusedBorderColor = DarkRed.copy(alpha = 0.8f),
                )
            )
            Spacer(Modifier.height(30.dp))
            Text("Select Your Birth Date", color = Color.White.copy(alpha = 0.7f), fontSize = 16.sp)
            Spacer(Modifier.height(8.dp))
            Surface(
                shape = RoundedCornerShape(8.dp),
                border = BorderStroke(1.dp, DarkRed.copy(alpha = 0.8f)),
                modifier = Modifier.fillMaxWidth().clickable { showPicker = true }
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        date?.let { "%04d-%02d-%02d".format(it.year, it.monthValue, it.dayOfMonth) } ?: "Select Date",
                        color = if (date != null) Color.White else Color.Gray, fontSize = 18.sp,
                        modifier = Modifier.weight(1f)
                    )
                    Icon(Icons.Default.Today, null, tint = DarkRed)
                }
            }
            Spacer(Modifier.weight(1f))
            Button(
                onClick = {
                    val bd = LocalDateTime.of(date!!, LocalTime.of(0, 0))
                    val deviceId = StorageService.getDeviceId()
                    val death = calculateDeathDate(name, bd, deviceId)
                    val data = CountdownData(name, bd, death)
                    StorageService.saveUserData(name, bd, death)
                    onStart(data)
                },
                enabled = valid,
                colors = ButtonDefaults.buttonColors(containerColor = DarkRed, disabledContainerColor = Color.DarkGray),
                modifier = Modifier.fillMaxWidth().height(50.dp)
            ) { Text("START", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold) }
            Spacer(Modifier.height(24.dp))
        }
    }
}

// ==================== Main Countdown ====================
@Composable
private fun MainCountdownScreen(data: CountdownData, onOpenSettings: () -> Unit) {
    var tick by remember { mutableStateOf(0) }
    var clickCount by remember { mutableStateOf(0) }
    var lastClick by remember { mutableStateOf(0L) }
    var showSettings by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        while (isActive) { delay(1000); tick++ }
    }
    BoxWithConstraints(
        Modifier
            .fillMaxSize()
            .background(Color.Black)
            .clickable {
                val now = System.currentTimeMillis()
                clickCount = if (now - lastClick < 500) clickCount + 1 else 1
                lastClick = now
                if (clickCount >= 5) showSettings = true
            },
        contentAlignment = Alignment.Center
    ) {
        // 5 rows + label below = each row gets ~1/5 of height. Use 0.7 factor for padding.
        val maxFont = with(LocalDensity.current) { (maxHeight.toSp() / 5f) * 0.7f }
        val labelFont = maxFont / 3f

        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
        ) {
            val years = remember(tick) { data.years }
            val days = remember(tick) { data.days }
            val hours = remember(tick) { data.hours }
            val minutes = remember(tick) { data.minutes }
            val seconds = remember(tick) { data.seconds }
            val items = listOf(
                Triple("YRS", years, 0),
                Triple("DAY", days, 1),
                Triple("HRS", hours, 2),
                Triple("MIN", minutes, 3),
                Triple("SEC", seconds, 4),
            )
            var grayFromIndex = 5
            if (years <= 0) grayFromIndex = 0
            if (years <= 0 && days <= 0) grayFromIndex = 1
            if (years <= 0 && days <= 0 && hours <= 0) grayFromIndex = 2
            if (years <= 0 && days <= 0 && hours <= 0 && minutes <= 0) grayFromIndex = 3
            if (years <= 0 && days <= 0 && hours <= 0 && minutes <= 0 && seconds <= 0) grayFromIndex = 4
            items.forEach { (label, value, idx) ->
                CountdownRow(
                    label = label,
                    value = value,
                    isWhite = idx > grayFromIndex,
                    maxFont = maxFont,
                    labelFont = labelFont,
                )
            }
        }
        if (showSettings) {
            IconButton(
                onClick = onOpenSettings,
                modifier = Modifier.align(Alignment.TopStart).padding(16.dp)
            ) { Icon(Icons.Default.Settings, null, tint = DarkRed, modifier = Modifier.size(32.dp)) }
        }
    }
}

@Composable
private fun CountdownRow(
    label: String,
    value: Long,
    isWhite: Boolean,
    maxFont: TextUnit,
    labelFont: TextUnit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth(0.85f)
            .padding(vertical = 4.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box {
            BasicText(
                text = value.toString().padStart(2, '0'),
                style = TextStyle(
                    color = if (isWhite) NumberWhite else DarkRed,
                    fontFamily = AppFontFamily,
                    fontWeight = FontWeight.Black,
                ),
                maxLines = 1,
                autoSize = TextAutoSize.StepBased(
                    minFontSize = 10.sp,
                    maxFontSize = maxFont,
                    stepSize = 0.5.sp,
                ),
            )
            Text(
                label,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .offset(x = 6.dp, y = (-6).dp),
                color = if (isWhite) Color.White.copy(alpha = 0.5f) else LabelGray,
                fontSize = labelFont, fontWeight = FontWeight.Black,
                fontFamily = AppFontFamily,
            )
        }
    }
}

// ==================== Settings ====================
@Composable
private fun SettingsScreen(
    onBack: () -> Unit,
    onDevMode: () -> Unit,
    onSearchUsers: () -> Unit,
    onCleared: () -> Unit,
) {
    var versionClicks by remember { mutableStateOf(0) }
    var titleClicks by remember { mutableStateOf(0) }
    var devMode by remember { mutableStateOf(false) }
    var showDelete by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        versionClicks = StorageService.getDevVersionClicks()
        titleClicks = StorageService.getDevTitleClicks()
    }
    fun check() {
        if (versionClicks >= AppConstants.VERSION_TAP_COUNT &&
            titleClicks >= AppConstants.TITLE_TAP_COUNT && !devMode) {
            devMode = true
            StorageService.setDevVersionClicks(0)
            StorageService.setDevTitleClicks(0)
            onDevMode()
        }
    }
    if (showDelete) {
        AlertDialog(
            onDismissRequest = { showDelete = false },
            title = { Text("Delete All Data?", color = Color.White) },
            text = { Text("This will delete all local data. Cannot be undone.", color = Color.White.copy(alpha = 0.7f)) },
            confirmButton = {
                TextButton(onClick = {
                    StorageService.clearAllData()
                    showDelete = false
                    onCleared()
                }) { Text("Delete", color = DarkRed) }
            },
            dismissButton = {
                TextButton(onClick = { showDelete = false }) { Text("Cancel", color = Color.White.copy(alpha = 0.7f)) }
            },
            containerColor = Color.DarkGray
        )
    }
    Scaffold(
        containerColor = Color.Black,
        topBar = {
            TopAppBar(
                title = {
                    Text("Settings", modifier = Modifier.clickable {
                        titleClicks++
                        StorageService.setDevTitleClicks(titleClicks)
                        check()
                    })
                },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null, tint = DarkRed) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Black)
            )
        }
    ) { p ->
        Column(Modifier.padding(p)) {
            SettingsItem("Package Name", AppConstants.PACKAGE_NAME)
            SettingsItem("Version", AppConstants.VERSION, onClick = {
                versionClicks++
                StorageService.setDevVersionClicks(versionClicks)
                check()
            })
            SettingsItem("Developer", if (devMode) AppConstants.DEVELOPER_DEV_MODE else AppConstants.DEVELOPER)
            if (devMode) {
                HorizontalDivider(color = DarkRed)
                ListItem(
                    headlineContent = { Text("Search Users", color = DarkRed) },
                    trailingContent = { Icon(Icons.Default.Search, null, tint = DarkRed) },
                    modifier = Modifier.clickable { onSearchUsers() }
                )
                ListItem(
                    headlineContent = { Text("Delete All Data", color = DarkRed) },
                    trailingContent = { Icon(Icons.Default.DeleteForever, null, tint = DarkRed) },
                    modifier = Modifier.clickable { showDelete = true }
                )
            }
        }
    }
}

@Composable
private fun SettingsItem(title: String, value: String, onClick: (() -> Unit)? = null) {
    ListItem(
        headlineContent = { Text(title, color = Color.White.copy(alpha = 0.7f)) },
        supportingContent = {
            Text(value, color = if (onClick != null) DarkRed else Color.White,
                fontWeight = if (onClick != null) FontWeight.Bold else FontWeight.Normal)
        },
        modifier = if (onClick != null) Modifier.clickable { onClick() } else Modifier
    )
}

// ==================== Dev Mode Red Screen ====================
@Composable
private fun DevModeRedScreen(onDone: () -> Unit) {
    val ctx = LocalContext.current
    LaunchedEffect(Unit) {
        delay(800)
        onDone()
    }
    Box(Modifier.fillMaxSize().background(DarkRed), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.Settings, null, Modifier.size(80.dp), tint = Color.Black)
            Spacer(Modifier.height(20.dp))
            Text("DEVELOPER MODE", color = Color.Black, fontSize = 32.sp,
                fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
        }
    }
}

// ==================== Search Users ====================
private val firstNames = listOf(
    "James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "David", "Elizabeth",
    "William", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen",
    "Christopher", "Nancy", "Daniel", "Lisa", "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra",
    "Donald", "Ashley", "Steven", "Kimberly", "Paul", "Emily", "Andrew", "Donna", "Joshua", "Michelle",
    "Kenneth", "Dorothy", "Kevin", "Carol", "Brian", "Amanda", "George", "Melissa", "Timothy", "Deborah",
    "Edward", "Stephanie", "Ronald", "Rebecca", "Jason", "Sharon", "Jeffrey", "Laura", "Ryan", "Cynthia",
    "Jacob", "Kathleen", "Gary", "Amy", "Nicholas", "Angela", "Eric", "Shirley", "Jonathan", "Anna",
    "Stephen", "Brenda", "Larry", "Pamela", "Justin", "Emma", "Scott", "Nicole", "Brandon", "Helen",
    "Benjamin", "Samantha", "Samuel", "Katherine", "Raymond", "Christine", "Gregory", "Debra", "Frank", "Rachel",
    "Alexander", "Carolyn", "Patrick", "Janet", "Jack", "Catherine", "Dennis", "Maria", "Jerry", "Heather"
)
private val lastNames = listOf(
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
    "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson",
    "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell", "Carter", "Roberts"
)
private val excludedNames = setOf("admin", "root", "administrator", "system", "superuser", "test", "guest", "user", "moderator", "owner")
private const val pageSize = 30

@Composable
private fun SearchUsersScreen(onBack: () -> Unit) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val users = remember { mutableStateListOf<SearchUser>() }
    var loading by remember { mutableStateOf(true) }
    var loadingMore by remember { mutableStateOf(false) }
    var query by remember { mutableStateOf("") }
    var tick by remember { mutableStateOf(0) }
    var currentUsername by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    LaunchedEffect(Unit) {
        StorageService.loadUserData()?.let { currentUsername = it.username }
        delay(2000)
        users.addAll(generateUsers())
        loading = false
    }
    LaunchedEffect(Unit) {
        while (isActive) { delay(1000); tick++ }
    }
    LaunchedEffect(listState, users) {
        snapshotFlow { listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index }
            .collect { idx ->
                if (idx != null && idx >= users.size - 5 && !loading && !loadingMore) {
                    loadingMore = true
                    delay(300)
                    users.addAll(generateUsers())
                    loadingMore = false
                }
            }
    }

    val filtered = remember(query, users, tick) {
        if (query.isBlank()) users to null
        else {
            val matches = users.filter { it.username.contains(query, ignoreCase = true) }
            var idx: Int? = null
            val list = mutableListOf<SearchUser>()
            if (currentUsername.contains(query, ignoreCase = true) && matches.none { it.username == currentUsername }) {
                list.add(SearchUser(currentUsername, StorageService.loadUserData()!!.deathDate))
                idx = 0
            }
            matches.forEach { u ->
                if (u.username == currentUsername) idx = list.size
                list.add(u)
            }
            list to idx
        }
    }

    Scaffold(
        containerColor = Color.Black,
        topBar = {
            TopAppBar(
                title = { Text("Search Users") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null, tint = DarkRed) }
                },
                actions = {
                    IconButton(onClick = {
                        users.add(0, generateRandomUser())
                        scope.launch { listState.scrollToItem(0) }
                    }) { Icon(Icons.Default.Add, null, tint = DarkRed) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Black)
            )
        }
    ) { p ->
        Column(Modifier.padding(p).fillMaxSize()) {
            OutlinedTextField(
                value = query, onValueChange = { query = it },
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                placeholder = { Text("Search username...", color = Color.Gray) },
                leadingIcon = { Icon(Icons.Default.Search, null, tint = DarkRed) },
                trailingIcon = {
                    val idx = filtered.second
                    if (query.isNotBlank() && idx != null) {
                        IconButton(onClick = {
                            scope.launch { listState.animateScrollToItem(idx) }
                        }) { Icon(Icons.Default.MyLocation, null, tint = DarkRed) }
                    }
                },
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White, unfocusedTextColor = Color.White,
                    cursorColor = DarkRed, focusedBorderColor = DarkRed,
                    unfocusedBorderColor = DarkRed.copy(alpha = 0.8f),
                )
            )
            if (loading) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(color = DarkRed)
                        Spacer(Modifier.height(16.dp))
                        Text("Reading cloud data...", color = Color.White.copy(alpha = 0.7f))
                    }
                }
            } else {
                LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                    items(filtered.first) { u ->
                        val isMe = u.username == currentUsername
                        ListItem(
                            headlineContent = {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(u.username, color = if (isMe) DarkRed else Color.White,
                                        fontWeight = if (isMe) FontWeight.Bold else FontWeight.Normal)
                                    if (isMe) {
                                        Spacer(Modifier.width(8.dp))
                                        Surface(color = DarkRed, shape = RoundedCornerShape(4.dp)) {
                                            Text("YOU", color = Color.Black, fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                                        }
                                    }
                                }
                            },
                            supportingContent = { Text(u.countdownString, color = DarkRed, fontFamily = AppFontFamily) },
                            trailingContent = {
                                Row {
                                    IconButton(onClick = { /* sync - simplified */ }) {
                                        Icon(Icons.Default.CloudUpload, null, tint = DarkRed)
                                    }
                                    IconButton(onClick = { /* edit - simplified */ }) {
                                        Icon(Icons.Default.Edit, null, tint = DarkRed)
                                    }
                                }
                            },
                            modifier = Modifier.background(if (isMe) DarkRed.copy(alpha = 0.2f) else Color.Transparent)
                        )
                    }
                    if (loadingMore) {
                        item { Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(color = DarkRed)
                        } }
                    }
                }
            }
        }
    }
}

private val rng = Random.Default
private fun generateUsers(n: Int = pageSize): List<SearchUser> {
    val out = ArrayList<SearchUser>(n)
    val now = LocalDateTime.now()
    repeat(n) {
        var name: String
        do {
            name = "${firstNames.random(rng)}${lastNames.random(rng)}${rng.nextInt(999)}"
        } while (name.lowercase() in excludedNames || out.any { it.username == name })
        val death = LocalDateTime.of(
            now.year + rng.nextInt(50) + 20,
            rng.nextInt(12) + 1, rng.nextInt(28) + 1,
            rng.nextInt(24), rng.nextInt(60), rng.nextInt(60), rng.nextInt(1000) * 1_000_000
        )
        out.add(SearchUser(name, death))
    }
    return out
}

private fun generateRandomUser() = generateUsers(1).first()
