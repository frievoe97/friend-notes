@file:OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)

package com.example.friendnotes.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TimePickerDefaults
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.friendnotes.R
import com.example.friendnotes.domain.model.Friend
import com.example.friendnotes.domain.model.FriendAggregate
import com.example.friendnotes.domain.model.FriendEntryCategory
import com.example.friendnotes.domain.model.FriendSortMode
import com.example.friendnotes.domain.model.Meeting
import com.example.friendnotes.domain.model.MeetingAggregate
import com.example.friendnotes.domain.model.MeetingKind
import com.example.friendnotes.ui.components.AppBackground
import com.example.friendnotes.ui.components.FriendAvatar
import com.example.friendnotes.ui.theme.FriendNotesTheme
import com.example.friendnotes.ui.theme.FriendNotesThemeExtras
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.time.format.TextStyle
import java.time.temporal.WeekFields
import java.util.Locale

private object Routes {
    const val FRIENDS = "friends"
    const val CALENDAR = "calendar"
    const val SETTINGS = "settings"
    const val ADD_FRIEND = "friend/add"
    const val FRIEND_DETAIL = "friend/{friendId}"
    const val FRIEND_HISTORY = "friend/{friendId}/history"
    const val ENTRY_CATEGORY = "friend/{friendId}/entries/{category}"
    const val GIFTS = "friend/{friendId}/gifts"
    const val MEETING_EDIT = "meeting/{meetingId}"
    const val MEETING_CREATE = "meeting/create/{kind}"

    fun friendDetail(friendId: Long) = "friend/$friendId"
    fun friendHistory(friendId: Long) = "friend/$friendId/history"
    fun entryCategory(friendId: Long, category: String) = "friend/$friendId/entries/$category"
    fun gifts(friendId: Long) = "friend/$friendId/gifts"
    fun meetingEdit(meetingId: Long) = "meeting/$meetingId"
    fun meetingCreate(kind: MeetingKind) = "meeting/create/${kind.raw}"
}

@Composable
fun FriendNotesApp(viewModel: FriendNotesViewModel = viewModel()) {
    FriendNotesTheme {
        Box(modifier = Modifier.fillMaxSize()) {
            AppBackground()
            SplashGate {
                FriendNotesNavHost(viewModel)
            }
        }
    }
}

@Composable
private fun SplashGate(content: @Composable () -> Unit) {
    var showSplash by rememberSaveable { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        delay(2_000)
        showSplash = false
    }

    Box(modifier = Modifier.fillMaxSize()) {
        AnimatedVisibility(
            visible = showSplash,
            enter = fadeIn(animationSpec = tween(300)),
            exit = fadeOut(animationSpec = tween(250)),
        ) {
            SplashScreen()
        }

        AnimatedVisibility(
            visible = !showSplash,
            enter = fadeIn(animationSpec = tween(350)),
        ) {
            content()
        }
    }
}

@Composable
private fun SplashScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(164.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)),
            contentAlignment = Alignment.Center,
        ) {
            Image(
                painter = painterResource(R.drawable.splash_logo),
                contentDescription = null,
                modifier = Modifier.width(138.dp),
            )
        }
        Spacer(modifier = Modifier.height(18.dp))
        Text(
            text = stringResource(R.string.splash_title),
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FriendNotesNavHost(viewModel: FriendNotesViewModel) {
    val navController = rememberNavController()
    val backStack by navController.currentBackStackEntryAsState()
    val route = backStack?.destination?.route.orEmpty()

    val showBottomBar = route in setOf(Routes.FRIENDS, Routes.CALENDAR, Routes.SETTINGS)

    val snackbarHostState = remember { SnackbarHostState() }

    Scaffold(
        containerColor = Color.Transparent,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            if (showBottomBar) {
                BottomNavigationBar(
                    route = route,
                    onSelect = { selected ->
                        navController.navigate(selected) {
                            launchSingleTop = true
                            popUpTo(Routes.FRIENDS) { saveState = true }
                            restoreState = true
                        }
                    },
                )
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Routes.FRIENDS,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Routes.FRIENDS) {
                FriendsScreen(
                    viewModel = viewModel,
                    onOpenFriend = { navController.navigate(Routes.friendDetail(it)) },
                    onAddFriend = { navController.navigate(Routes.ADD_FRIEND) },
                )
            }
            composable(Routes.CALENDAR) {
                CalendarScreen(
                    viewModel = viewModel,
                    onOpenFriend = { navController.navigate(Routes.friendDetail(it)) },
                    onOpenMeeting = { navController.navigate(Routes.meetingEdit(it)) },
                    onCreateMeeting = { kind -> navController.navigate(Routes.meetingCreate(kind)) },
                )
            }
            composable(Routes.SETTINGS) {
                SettingsScreen(viewModel = viewModel, snackbarHostState = snackbarHostState)
            }
            composable(Routes.ADD_FRIEND) {
                AddFriendScreen(
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                    snackbarHostState = snackbarHostState,
                )
            }
            composable(
                route = Routes.FRIEND_DETAIL,
                arguments = listOf(navArgument("friendId") { type = NavType.LongType }),
            ) { entry ->
                val friendId = entry.arguments?.getLong("friendId") ?: return@composable
                FriendDetailScreen(
                    viewModel = viewModel,
                    friendId = friendId,
                    onBack = { navController.popBackStack() },
                    onOpenEntryCategory = { category -> navController.navigate(Routes.entryCategory(friendId, category.raw)) },
                    onOpenHistory = { navController.navigate(Routes.friendHistory(friendId)) },
                    onOpenGifts = { navController.navigate(Routes.gifts(friendId)) },
                    onOpenMeeting = { meetingId -> navController.navigate(Routes.meetingEdit(meetingId)) },
                    onCreateMeeting = { kind -> navController.navigate(Routes.meetingCreate(kind)) },
                    snackbarHostState = snackbarHostState,
                )
            }
            composable(
                route = Routes.FRIEND_HISTORY,
                arguments = listOf(navArgument("friendId") { type = NavType.LongType }),
            ) { entry ->
                val friendId = entry.arguments?.getLong("friendId") ?: return@composable
                FriendHistoryScreen(
                    viewModel = viewModel,
                    friendId = friendId,
                    onBack = { navController.popBackStack() },
                    onOpenMeeting = { navController.navigate(Routes.meetingEdit(it)) },
                    onCreateMeeting = { kind -> navController.navigate(Routes.meetingCreate(kind)) },
                )
            }
            composable(
                route = Routes.ENTRY_CATEGORY,
                arguments = listOf(
                    navArgument("friendId") { type = NavType.LongType },
                    navArgument("category") { type = NavType.StringType },
                ),
            ) { entry ->
                val friendId = entry.arguments?.getLong("friendId") ?: return@composable
                val category = FriendEntryCategory.fromRaw(entry.arguments?.getString("category").orEmpty())
                EntryCategoryScreen(
                    viewModel = viewModel,
                    friendId = friendId,
                    category = category,
                    onBack = { navController.popBackStack() },
                    snackbarHostState = snackbarHostState,
                )
            }
            composable(
                route = Routes.GIFTS,
                arguments = listOf(navArgument("friendId") { type = NavType.LongType }),
            ) { entry ->
                val friendId = entry.arguments?.getLong("friendId") ?: return@composable
                GiftsScreen(
                    viewModel = viewModel,
                    friendId = friendId,
                    onBack = { navController.popBackStack() },
                    snackbarHostState = snackbarHostState,
                )
            }
            composable(
                route = Routes.MEETING_EDIT,
                arguments = listOf(navArgument("meetingId") { type = NavType.LongType }),
            ) { entry ->
                val meetingId = entry.arguments?.getLong("meetingId") ?: return@composable
                MeetingEditorScreen(
                    viewModel = viewModel,
                    initialKind = null,
                    meetingId = meetingId,
                    onBack = { navController.popBackStack() },
                    snackbarHostState = snackbarHostState,
                )
            }
            composable(
                route = Routes.MEETING_CREATE,
                arguments = listOf(navArgument("kind") { type = NavType.StringType }),
            ) { entry ->
                val kind = MeetingKind.fromRaw(entry.arguments?.getString("kind").orEmpty())
                MeetingEditorScreen(
                    viewModel = viewModel,
                    initialKind = kind,
                    meetingId = null,
                    onBack = { navController.popBackStack() },
                    snackbarHostState = snackbarHostState,
                )
            }
        }
    }
}

@Composable
private fun BottomNavigationBar(route: String, onSelect: (String) -> Unit) {
    data class BottomItem(val route: String, val label: String, val icon: ImageVector)

    val colors = FriendNotesThemeExtras.colors
    val items = listOf(
        BottomItem(Routes.FRIENDS, stringResource(R.string.tab_friends), Icons.Default.PeopleAlt),
        BottomItem(Routes.CALENDAR, stringResource(R.string.tab_calendar), Icons.Default.CalendarMonth),
        BottomItem(Routes.SETTINGS, stringResource(R.string.tab_settings), Icons.Default.Settings),
    )

    NavigationBar(
        modifier = Modifier.navigationBarsPadding(),
        containerColor = colors.surfaceElevated.copy(alpha = 0.88f),
        tonalElevation = 0.dp,
    ) {
        items.forEach { item ->
            val selected = route == item.route
            NavigationBarItem(
                selected = selected,
                onClick = { onSelect(item.route) },
                icon = { Icon(item.icon, contentDescription = null) },
                label = { Text(item.label) },
                colors = androidx.compose.material3.NavigationBarItemDefaults.colors(
                    selectedIconColor = MaterialTheme.colorScheme.onBackground,
                    selectedTextColor = MaterialTheme.colorScheme.onBackground,
                    indicatorColor = colors.subtleFillSelected.copy(alpha = 0.9f),
                    unselectedIconColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.76f),
                    unselectedTextColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.76f),
                ),
            )
        }
    }
}

@Composable
private fun HeaderIconButton(
    onClick: () -> Unit,
    icon: ImageVector,
    modifier: Modifier = Modifier,
) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(999.dp),
        color = colors.surfaceElevated.copy(alpha = 0.42f),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.34f)),
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onBackground)
        }
    }
}

@Composable
private fun HeaderTextButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(999.dp),
        color = colors.surfaceElevated.copy(alpha = 0.42f),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.34f)),
    ) {
        Box(
            modifier = Modifier
                .clickable(onClick = onClick)
                .padding(horizontal = 16.dp, vertical = 11.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = text,
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
            )
        }
    }
}

@Composable
private fun LargeScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    leading: @Composable (() -> Unit)? = null,
    trailing: @Composable RowScope.() -> Unit = {},
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 60.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopStart),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (leading != null) {
                leading()
            }
            Spacer(modifier = Modifier.weight(1f))
            trailing()
        }
        Text(
            text = title,
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(top = 8.dp, end = 84.dp),
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground,
        )
    }
}

@Composable
private fun HeaderActionCluster(content: @Composable RowScope.() -> Unit) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        shape = RoundedCornerShape(999.dp),
        color = colors.surfaceElevated.copy(alpha = 0.42f),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.34f)),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            content = content,
        )
    }
}

@Composable
private fun AppDropdownMenu(
    expanded: Boolean,
    onDismissRequest: () -> Unit,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = FriendNotesThemeExtras.colors
    DropdownMenu(
        expanded = expanded,
        onDismissRequest = onDismissRequest,
        shape = RoundedCornerShape(20.dp),
        containerColor = colors.surfaceCard.copy(alpha = 0.95f),
        tonalElevation = 0.dp,
        shadowElevation = 18.dp,
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.34f)),
        content = content,
    )
}

@Composable
private fun AppAlertDialog(
    onDismissRequest: () -> Unit,
    title: @Composable (() -> Unit)? = null,
    text: @Composable (() -> Unit)? = null,
    confirmButton: @Composable () -> Unit,
    dismissButton: @Composable (() -> Unit)? = null,
) {
    val colors = FriendNotesThemeExtras.colors
    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = title,
        text = text,
        confirmButton = confirmButton,
        dismissButton = dismissButton,
        shape = RoundedCornerShape(28.dp),
        containerColor = colors.surfaceCard.copy(alpha = 0.96f),
        titleContentColor = MaterialTheme.colorScheme.onBackground,
        textContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.82f),
        tonalElevation = 0.dp,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AppDatePickerDialog(
    initialDate: LocalDate,
    onDismiss: () -> Unit,
    onConfirm: (LocalDate) -> Unit,
) {
    val zoneId = remember { ZoneId.systemDefault() }
    val colors = FriendNotesThemeExtras.colors
    val pickerState = rememberDatePickerState(
        initialSelectedDateMillis = initialDate
            .atStartOfDay(zoneId)
            .toInstant()
            .toEpochMilli(),
    )

    AppAlertDialog(
        onDismissRequest = onDismiss,
        title = null,
        text = {
            DatePicker(
                state = pickerState,
                showModeToggle = false,
                colors = DatePickerDefaults.colors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground,
                    headlineContentColor = MaterialTheme.colorScheme.onBackground,
                    weekdayContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.62f),
                    subheadContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.68f),
                    yearContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.72f),
                    currentYearContentColor = MaterialTheme.colorScheme.primary,
                    selectedYearContentColor = MaterialTheme.colorScheme.onPrimary,
                    selectedYearContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.9f),
                    dayContentColor = MaterialTheme.colorScheme.onBackground,
                    disabledDayContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.28f),
                    selectedDayContentColor = MaterialTheme.colorScheme.onPrimary,
                    disabledSelectedDayContentColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.36f),
                    selectedDayContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.88f),
                    disabledSelectedDayContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                    todayContentColor = MaterialTheme.colorScheme.primary,
                    todayDateBorderColor = colors.cardBorder.copy(alpha = 0.7f),
                    dividerColor = colors.cardBorder.copy(alpha = 0.3f),
                ),
            )
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val selected = pickerState.selectedDateMillis ?: return@TextButton
                    onConfirm(
                        Instant.ofEpochMilli(selected)
                            .atZone(zoneId)
                            .toLocalDate(),
                    )
                },
            ) {
                Text(stringResource(R.string.common_save))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AppDateTimePickerDialog(
    initial: ZonedDateTime,
    onDismiss: () -> Unit,
    onConfirm: (ZonedDateTime) -> Unit,
) {
    val zoneId = remember { ZoneId.systemDefault() }
    val colors = FriendNotesThemeExtras.colors
    var selectingTime by remember { mutableStateOf(false) }
    var selectedDate by remember(initial) { mutableStateOf(initial.toLocalDate()) }
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = initial
            .toLocalDate()
            .atStartOfDay(zoneId)
            .toInstant()
            .toEpochMilli(),
    )
    val timePickerState = rememberTimePickerState(
        initialHour = initial.hour,
        initialMinute = initial.minute,
        is24Hour = true,
    )

    AppAlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (selectingTime) {
                    stringResource(R.string.meeting_end)
                } else {
                    stringResource(R.string.meeting_start)
                },
            )
        },
        text = {
            if (selectingTime) {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center,
                ) {
                    TimePicker(
                        state = timePickerState,
                        colors = TimePickerDefaults.colors(
                            clockDialColor = colors.surfaceElevated.copy(alpha = 0.72f),
                            clockDialSelectedContentColor = MaterialTheme.colorScheme.onPrimary,
                            clockDialUnselectedContentColor = MaterialTheme.colorScheme.onBackground,
                            selectorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.9f),
                            containerColor = Color.Transparent,
                            periodSelectorBorderColor = colors.cardBorder.copy(alpha = 0.34f),
                            periodSelectorSelectedContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.82f),
                            periodSelectorUnselectedContainerColor = colors.surfaceElevated.copy(alpha = 0.5f),
                            periodSelectorSelectedContentColor = MaterialTheme.colorScheme.onPrimary,
                            periodSelectorUnselectedContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.76f),
                            timeSelectorSelectedContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.88f),
                            timeSelectorUnselectedContainerColor = colors.surfaceElevated.copy(alpha = 0.56f),
                            timeSelectorSelectedContentColor = MaterialTheme.colorScheme.onPrimary,
                            timeSelectorUnselectedContentColor = MaterialTheme.colorScheme.onBackground,
                        ),
                    )
                }
            } else {
                DatePicker(
                    state = datePickerState,
                    showModeToggle = false,
                    colors = DatePickerDefaults.colors(
                        containerColor = Color.Transparent,
                        titleContentColor = MaterialTheme.colorScheme.onBackground,
                        headlineContentColor = MaterialTheme.colorScheme.onBackground,
                        weekdayContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.62f),
                        subheadContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.68f),
                        yearContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.72f),
                        currentYearContentColor = MaterialTheme.colorScheme.primary,
                        selectedYearContentColor = MaterialTheme.colorScheme.onPrimary,
                        selectedYearContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.9f),
                        dayContentColor = MaterialTheme.colorScheme.onBackground,
                        disabledDayContentColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.28f),
                        selectedDayContentColor = MaterialTheme.colorScheme.onPrimary,
                        disabledSelectedDayContentColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.36f),
                        selectedDayContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.88f),
                        disabledSelectedDayContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                        todayContentColor = MaterialTheme.colorScheme.primary,
                        todayDateBorderColor = colors.cardBorder.copy(alpha = 0.7f),
                        dividerColor = colors.cardBorder.copy(alpha = 0.3f),
                    ),
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (!selectingTime) {
                        val selectedMillis = datePickerState.selectedDateMillis ?: return@TextButton
                        selectedDate = Instant.ofEpochMilli(selectedMillis).atZone(zoneId).toLocalDate()
                        selectingTime = true
                    } else {
                        onConfirm(
                            initial
                                .withYear(selectedDate.year)
                                .withMonth(selectedDate.monthValue)
                                .withDayOfMonth(selectedDate.dayOfMonth)
                                .withHour(timePickerState.hour)
                                .withMinute(timePickerState.minute),
                        )
                    }
                },
            ) {
                Text(stringResource(if (selectingTime) R.string.common_save else R.string.common_next))
            }
        },
        dismissButton = {
            TextButton(
                onClick = {
                    if (selectingTime) {
                        selectingTime = false
                    } else {
                        onDismiss()
                    }
                },
            ) {
                Text(stringResource(R.string.common_cancel))
            }
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FriendsScreen(
    viewModel: FriendNotesViewModel,
    onOpenFriend: (Long) -> Unit,
    onAddFriend: () -> Unit,
) {
    val friends by viewModel.sortedFilteredFriends.collectAsStateWithLifecycle()
    val query by viewModel.searchQuery.collectAsStateWithLifecycle()
    var sortMenuExpanded by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = Color.Transparent,
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .statusBarsPadding()
                .padding(horizontal = 16.dp),
        ) {
            LargeScreenHeader(
                title = stringResource(R.string.friends_title),
                leading = null,
                trailing = {
                    HeaderActionCluster {
                        IconButton(onClick = { sortMenuExpanded = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        }
                        IconButton(onClick = onAddFriend) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        }
                    }
                    AppDropdownMenu(expanded = sortMenuExpanded, onDismissRequest = { sortMenuExpanded = false }) {
                        listOf(
                            FriendSortMode.NAME_ASC to R.string.sort_name_asc,
                            FriendSortMode.NAME_DESC to R.string.sort_name_desc,
                            FriendSortMode.LAST_SEEN_ASC to R.string.sort_last_seen_asc,
                            FriendSortMode.LAST_SEEN_DESC to R.string.sort_last_seen_desc,
                            FriendSortMode.NEXT_MEETING to R.string.sort_next_meeting,
                            FriendSortMode.NEXT_EVENT to R.string.sort_next_event,
                        ).forEach { (mode, label) ->
                            DropdownMenuItem(
                                text = { Text(stringResource(label)) },
                                onClick = {
                                    sortMenuExpanded = false
                                    viewModel.setSortMode(mode)
                                },
                            )
                        }
                    }
                },
            )

            Spacer(modifier = Modifier.height(12.dp))

            FriendsSearchField(
                value = query,
                onValueChange = viewModel::setSearchQuery,
            )

            Spacer(modifier = Modifier.height(14.dp))

            if (friends.isEmpty()) {
                EmptyFriendsState(onAddFriend = onAddFriend)
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 110.dp),
                    verticalArrangement = Arrangement.spacedBy(0.dp),
                ) {
                    items(friends, key = { it.friend.id }) { item ->
                        FriendRow(
                            viewModel = viewModel,
                            item = item,
                            onClick = { onOpenFriend(item.friend.id) },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FriendsSearchField(
    value: String,
    onValueChange: (String) -> Unit,
) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.28f)),
        color = colors.surfaceElevated.copy(alpha = 0.34f),
    ) {
        TextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text(stringResource(R.string.friends_search_hint)) },
            leadingIcon = {
                Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp))
            },
            trailingIcon = {
                if (value.isNotBlank()) {
                    IconButton(onClick = { onValueChange("") }) {
                        Icon(Icons.Default.Close, contentDescription = null, modifier = Modifier.size(18.dp))
                    }
                }
            },
            singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                disabledContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
            ),
        )
    }
}

@Composable
private fun EmptyFriendsState(onAddFriend: () -> Unit) {
    val colors = FriendNotesThemeExtras.colors
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            color = colors.surfaceCard.copy(alpha = 0.95f),
            border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.65f)),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 26.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = stringResource(R.string.friends_empty_title),
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Center,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.friends_empty_subtitle),
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center,
                )
                Spacer(modifier = Modifier.height(18.dp))
                Button(onClick = onAddFriend) {
                    Text(stringResource(R.string.friends_add_cta))
                }
            }
        }
    }
}

@Composable
private fun FriendSortRow(current: FriendSortMode, onSortSelected: (FriendSortMode) -> Unit) {
    val sorts = listOf(
        FriendSortMode.NAME_ASC to R.string.sort_name_asc,
        FriendSortMode.NAME_DESC to R.string.sort_name_desc,
        FriendSortMode.LAST_SEEN_ASC to R.string.sort_last_seen_asc,
        FriendSortMode.LAST_SEEN_DESC to R.string.sort_last_seen_desc,
        FriendSortMode.NEXT_MEETING to R.string.sort_next_meeting,
        FriendSortMode.NEXT_EVENT to R.string.sort_next_event,
    )

    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        items(sorts.size) { index ->
            val (mode, label) = sorts[index]
            FilterChip(
                selected = mode == current,
                onClick = { onSortSelected(mode) },
                label = { Text(stringResource(label)) },
                shape = RoundedCornerShape(12.dp),
            )
        }
    }
}

@Composable
private fun TransparentListItem(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    accentColor: Color = MaterialTheme.colorScheme.primary,
    content: @Composable RowScope.() -> Unit,
) {
    val colors = FriendNotesThemeExtras.colors

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
        shape = RoundedCornerShape(16.dp),
        color = Color.Transparent,
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.18f)),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 11.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(34.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(accentColor.copy(alpha = 0.55f)),
            )
            Spacer(modifier = Modifier.width(12.dp))
            content()
        }
    }
}

@Composable
private fun FriendRow(
    viewModel: FriendNotesViewModel,
    item: FriendAggregate,
    onClick: () -> Unit,
) {
    val friend = item.friend
    val colors = FriendNotesThemeExtras.colors
    val displayName = viewModel.displayName(friend).ifBlank { stringResource(R.string.friends_unnamed) }
    val fullName = "${friend.firstName} ${friend.lastName}".trim()
    val lastSeenState = viewModel.lastSeenLabel(item)
    val lastSeenLabel = when (lastSeenState) {
        is com.example.friendnotes.domain.usecase.FriendSearchSortUseCase.LastSeenLabel.Today -> stringResource(R.string.last_seen_today)
        is com.example.friendnotes.domain.usecase.FriendSearchSortUseCase.LastSeenLabel.Days -> stringResource(R.string.last_seen_days, lastSeenState.value)
        is com.example.friendnotes.domain.usecase.FriendSearchSortUseCase.LastSeenLabel.Weeks -> stringResource(R.string.last_seen_weeks, lastSeenState.value)
        is com.example.friendnotes.domain.usecase.FriendSearchSortUseCase.LastSeenLabel.Months -> stringResource(R.string.last_seen_months, lastSeenState.value)
        is com.example.friendnotes.domain.usecase.FriendSearchSortUseCase.LastSeenLabel.Years -> stringResource(R.string.last_seen_years, lastSeenState.value)
        is com.example.friendnotes.domain.usecase.FriendSearchSortUseCase.LastSeenLabel.Never -> stringResource(R.string.last_seen_never)
    }
    val latestNote = item.entries
        .sortedByDescending { it.createdAt }
        .firstOrNull { it.note.isNotBlank() }
        ?.note
        .orEmpty()
    val supporting = if (latestNote.isNotBlank()) latestNote else fullName
    val tags = friend.tags.take(3)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                FriendAvatar(initials = viewModel.initials(friend), size = 46.dp)
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(displayName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        if (friend.isFavorite) {
                            Spacer(modifier = Modifier.width(6.dp))
                            Icon(
                                imageVector = Icons.Default.Star,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(15.dp),
                            )
                        }
                    }
                    if (supporting.isNotBlank()) {
                        Text(
                            text = supporting,
                            style = MaterialTheme.typography.bodySmall,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.66f),
                        )
                    }
                }
                Icon(
                    imageVector = Icons.Default.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                )
            }

            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = lastSeenLabel,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.72f),
            )
            if (tags.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    tags.forEach { tag ->
                        Surface(
                            shape = RoundedCornerShape(30.dp),
                            color = colors.surfaceChip.copy(alpha = 0.42f),
                        ) {
                            Text(
                                text = tag,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                }
            }
        }
        Spacer(modifier = Modifier.height(10.dp))
        HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.22f))
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
private fun AddFriendScreen(
    viewModel: FriendNotesViewModel,
    onBack: () -> Unit,
    snackbarHostState: SnackbarHostState,
) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var firstName by rememberSaveable { mutableStateOf("") }
    var lastName by rememberSaveable { mutableStateOf("") }
    var nickname by rememberSaveable { mutableStateOf("") }
    var birthday by rememberSaveable { mutableStateOf<LocalDate?>(null) }
    var isFavorite by rememberSaveable { mutableStateOf(false) }
    var showBirthdayPicker by rememberSaveable { mutableStateOf(false) }
    val selectedTags = remember { mutableStateListOf<String>() }

    val categoryInputs = remember {
        FriendEntryCategory.entries.associateWith { mutableStateOf("") }
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.add_friend_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = null)
                    }
                },
                actions = {
                    TextButton(onClick = {
                        scope.launch {
                            val entries = categoryInputs.mapValues { (_, state) ->
                                state.value
                                    .split("\n")
                                    .mapNotNull { row ->
                                        val parts = row.split(":", limit = 2)
                                        val title = parts.firstOrNull().orEmpty().trim()
                                        val note = parts.getOrNull(1).orEmpty().trim()
                                        if (title.isBlank()) null else title to note
                                    }
                            }

                            val ok = viewModel.createFriend(
                                firstName = firstName,
                                lastName = lastName,
                                nickname = nickname,
                                birthday = birthday,
                                tags = selectedTags,
                                isFavorite = isFavorite,
                                entriesByCategory = entries,
                            )
                            if (ok) {
                                onBack()
                            } else {
                                snackbarHostState.showSnackbar(context.getString(R.string.required_name_message))
                            }
                        }
                    }) {
                        Text(stringResource(R.string.common_save))
                    }
                },
                colors = topAppBarColors(),
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            FriendIdentityForm(
                firstName = firstName,
                onFirstNameChange = { firstName = it },
                lastName = lastName,
                onLastNameChange = { lastName = it },
                nickname = nickname,
                onNicknameChange = { nickname = it },
                birthday = birthday,
                onBirthdayClick = { showBirthdayPicker = true },
                onBirthdayClear = { birthday = null },
                isFavorite = isFavorite,
                onFavoriteChange = { isFavorite = it },
            )

            Text(stringResource(R.string.friends_tags), style = MaterialTheme.typography.titleMedium)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                settings.definedFriendTags.forEach { tag ->
                    FilterChip(
                        selected = selectedTags.any { it.equals(tag, ignoreCase = true) },
                        onClick = {
                            if (selectedTags.any { it.equals(tag, ignoreCase = true) }) {
                                selectedTags.removeAll { it.equals(tag, ignoreCase = true) }
                            } else {
                                selectedTags.add(tag)
                            }
                        },
                        label = { Text(tag) },
                    )
                }
            }

            FriendEntryCategory.entries.forEach { category ->
                val titleRes = categoryTitleRes(category)
                OutlinedTextField(
                    value = categoryInputs.getValue(category).value,
                    onValueChange = { categoryInputs.getValue(category).value = it },
                    label = { Text(stringResource(titleRes)) },
                    placeholder = { Text(stringResource(R.string.entry_multiline_hint)) },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2,
                )
            }

            Spacer(modifier = Modifier.height(28.dp))
        }
    }

    if (showBirthdayPicker) {
        AppDatePickerDialog(
            initialDate = birthday ?: LocalDate.now(),
            onDismiss = { showBirthdayPicker = false },
            onConfirm = {
                birthday = it
                showBirthdayPicker = false
            },
        )
    }
}

@Composable
private fun FriendIdentityForm(
    firstName: String,
    onFirstNameChange: (String) -> Unit,
    lastName: String,
    onLastNameChange: (String) -> Unit,
    nickname: String,
    onNicknameChange: (String) -> Unit,
    birthday: LocalDate?,
    onBirthdayClick: () -> Unit,
    onBirthdayClear: () -> Unit,
    isFavorite: Boolean,
    onFavoriteChange: (Boolean) -> Unit,
) {
    OutlinedTextField(
        value = firstName,
        onValueChange = onFirstNameChange,
        label = { Text(stringResource(R.string.first_name)) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
    )
    OutlinedTextField(
        value = lastName,
        onValueChange = onLastNameChange,
        label = { Text(stringResource(R.string.last_name)) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
    )
    OutlinedTextField(
        value = nickname,
        onValueChange = onNicknameChange,
        label = { Text(stringResource(R.string.nickname)) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
    )

    Row(verticalAlignment = Alignment.CenterVertically) {
        Button(onClick = onBirthdayClick) {
            Text(birthday?.format(localizedDateFormatter()) ?: stringResource(R.string.birthday_optional))
        }
        if (birthday != null) {
            Spacer(modifier = Modifier.width(8.dp))
            TextButton(onClick = onBirthdayClear) {
                Text(stringResource(R.string.friends_remove_birthday))
            }
        }
    }

    Row(verticalAlignment = Alignment.CenterVertically) {
        Checkbox(checked = isFavorite, onCheckedChange = onFavoriteChange)
        Text(stringResource(R.string.friends_favorite))
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FriendDetailScreen(
    viewModel: FriendNotesViewModel,
    friendId: Long,
    onBack: () -> Unit,
    onOpenEntryCategory: (FriendEntryCategory) -> Unit,
    onOpenHistory: () -> Unit,
    onOpenGifts: () -> Unit,
    onOpenMeeting: (Long) -> Unit,
    onCreateMeeting: (MeetingKind) -> Unit,
    snackbarHostState: SnackbarHostState,
) {
    val allFriends by viewModel.friends.collectAsStateWithLifecycle()
    val friendAggregate = allFriends.firstOrNull { it.friend.id == friendId }
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    if (friendAggregate == null) {
        LaunchedEffect(Unit) { onBack() }
        return
    }

    val friend = friendAggregate.friend
    val displayName = viewModel.displayName(friend).ifBlank { stringResource(R.string.friends_unnamed) }
    val fullName = "${friend.firstName} ${friend.lastName}".trim()
    val birthdayLabel = friend.birthday?.format(localizedDateFormatter())
        ?: stringResource(R.string.friend_no_birthday)
    val upcomingMeetings = friendAggregate.meetings
        .filter { !it.startDate.isBefore(ZonedDateTime.now()) }
        .sortedBy { it.startDate }
    val previewMeetings = upcomingMeetings.take(3)
    val hasMoreMeetings = friendAggregate.meetings.size > previewMeetings.size

    var editMode by rememberSaveable(friendId) { mutableStateOf(false) }
    var showDeleteDialog by rememberSaveable(friendId) { mutableStateOf(false) }

    var firstName by rememberSaveable(friendId) { mutableStateOf(friend.firstName) }
    var lastName by rememberSaveable(friendId) { mutableStateOf(friend.lastName) }
    var nickname by rememberSaveable(friendId) { mutableStateOf(friend.nickname) }
    var birthday by rememberSaveable(friendId) { mutableStateOf(friend.birthday) }
    var isFavorite by rememberSaveable(friendId) { mutableStateOf(friend.isFavorite) }
    var showBirthdayPicker by rememberSaveable(friendId) { mutableStateOf(false) }
    val selectedTags = remember(friendId) { mutableStateListOf<String>().apply { addAll(friend.tags) } }

    fun resetDraftFromCurrentFriend() {
        firstName = friend.firstName
        lastName = friend.lastName
        nickname = friend.nickname
        birthday = friend.birthday
        isFavorite = friend.isFavorite
        selectedTags.clear()
        selectedTags.addAll(friend.tags)
    }

    Scaffold(
        containerColor = Color.Transparent,
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .statusBarsPadding()
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(bottom = 42.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    HeaderIconButton(onClick = onBack, icon = Icons.Default.ArrowBack)
                    Spacer(modifier = Modifier.weight(1f))
                    if (editMode) {
                        HeaderIconButton(
                            onClick = { isFavorite = !isFavorite },
                            icon = if (isFavorite) Icons.Default.Star else Icons.Default.StarBorder,
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        HeaderTextButton(
                            text = stringResource(R.string.common_save),
                            onClick = {
                                scope.launch {
                                    val ok = viewModel.updateFriend(
                                        friendId = friendId,
                                        firstName = firstName,
                                        lastName = lastName,
                                        nickname = nickname,
                                        birthday = birthday,
                                        tags = selectedTags,
                                        isFavorite = isFavorite,
                                    )
                                    if (ok) {
                                        editMode = false
                                    } else {
                                        snackbarHostState.showSnackbar(context.getString(R.string.required_name_message))
                                    }
                                }
                            },
                        )
                    } else {
                        HeaderTextButton(
                            text = stringResource(R.string.common_edit),
                            onClick = {
                                resetDraftFromCurrentFriend()
                                editMode = true
                            },
                        )
                    }
                }
            }
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(24.dp),
                    color = Color.Transparent,
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        FriendAvatar(initials = viewModel.initials(friend), size = 78.dp)
                        Spacer(modifier = Modifier.height(14.dp))
                        if (editMode) {
                            OutlinedTextField(
                                value = firstName,
                                onValueChange = { firstName = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text(stringResource(R.string.first_name)) },
                                singleLine = true,
                            )
                            Spacer(modifier = Modifier.height(10.dp))
                            OutlinedTextField(
                                value = lastName,
                                onValueChange = { lastName = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text(stringResource(R.string.last_name)) },
                                singleLine = true,
                            )
                            Spacer(modifier = Modifier.height(10.dp))
                            OutlinedTextField(
                                value = nickname,
                                onValueChange = { nickname = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text(stringResource(R.string.nickname)) },
                                singleLine = true,
                            )
                        } else {
                            Text(
                                text = displayName,
                                style = MaterialTheme.typography.headlineMedium,
                                textAlign = TextAlign.Center,
                            )
                            if (friend.nickname.isNotBlank() && fullName.isNotBlank()) {
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = fullName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.74f),
                                    textAlign = TextAlign.Center,
                                )
                            }
                        }
                    }
                }
            }

            item {
                DetailSectionCard(title = stringResource(R.string.friends_birthday)) {
                    if (editMode) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Button(
                                onClick = { showBirthdayPicker = true },
                            ) {
                                Text(
                                    birthday?.format(localizedDateFormatter())
                                        ?: stringResource(R.string.birthday_optional)
                                )
                            }
                            if (birthday != null) {
                                Spacer(modifier = Modifier.width(8.dp))
                                TextButton(onClick = { birthday = null }) {
                                    Text(stringResource(R.string.friends_remove_birthday))
                                }
                            }
                        }
                    } else {
                        Text(
                            text = birthdayLabel,
                            style = MaterialTheme.typography.bodyLarge,
                            color = if (friend.birthday == null) {
                                MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f)
                            } else {
                                MaterialTheme.colorScheme.onSurface
                            },
                        )
                    }
                }
            }

            item {
                DetailSectionCard(title = stringResource(R.string.friends_tags)) {
                    if (editMode) {
                        if (settings.definedFriendTags.isEmpty()) {
                            Text(
                                text = stringResource(R.string.friend_tags_empty_hint),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                            )
                        } else {
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                settings.definedFriendTags.forEach { tag ->
                                    val isSelected = selectedTags.any { it.equals(tag, ignoreCase = true) }
                                    FilterChip(
                                        selected = isSelected,
                                        onClick = {
                                            if (isSelected) {
                                                selectedTags.removeAll { it.equals(tag, ignoreCase = true) }
                                            } else {
                                                selectedTags.add(tag)
                                            }
                                        },
                                        label = { Text(tag) },
                                    )
                                }
                            }
                        }
                    } else if (friend.tags.isEmpty()) {
                        Text(
                            text = stringResource(R.string.friend_tags_none),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        )
                    } else {
                        FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            friend.tags.forEach { tag ->
                                AssistChip(onClick = {}, label = { Text(tag) })
                            }
                        }
                    }
                }
            }

            item {
                CategoryRow(
                    title = stringResource(R.string.category_hobbies),
                    count = friendAggregate.entries.count { it.category == FriendEntryCategory.HOBBIES },
                    onClick = { onOpenEntryCategory(FriendEntryCategory.HOBBIES) },
                )
                CategoryRow(
                    title = stringResource(R.string.category_foods),
                    count = friendAggregate.entries.count { it.category == FriendEntryCategory.FOODS },
                    onClick = { onOpenEntryCategory(FriendEntryCategory.FOODS) },
                )
                CategoryRow(
                    title = stringResource(R.string.category_musics),
                    count = friendAggregate.entries.count { it.category == FriendEntryCategory.MUSICS },
                    onClick = { onOpenEntryCategory(FriendEntryCategory.MUSICS) },
                )
                CategoryRow(
                    title = stringResource(R.string.category_movies_series),
                    count = friendAggregate.entries.count { it.category == FriendEntryCategory.MOVIES_SERIES },
                    onClick = { onOpenEntryCategory(FriendEntryCategory.MOVIES_SERIES) },
                )
                CategoryRow(
                    title = stringResource(R.string.category_notes),
                    count = friendAggregate.entries.count { it.category == FriendEntryCategory.NOTES },
                    onClick = { onOpenEntryCategory(FriendEntryCategory.NOTES) },
                )
                CategoryRow(
                    title = stringResource(R.string.category_meetings_events),
                    count = friendAggregate.meetings.size,
                    onClick = onOpenHistory,
                )
                CategoryRow(
                    title = stringResource(R.string.category_gift_ideas),
                    count = friendAggregate.giftIdeas.size,
                    onClick = onOpenGifts,
                )
            }

            item {
                DetailSectionCard(title = stringResource(R.string.category_meetings_events)) {
                    if (previewMeetings.isEmpty()) {
                        Text(
                            text = stringResource(R.string.meeting_history_empty),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        )
                    } else {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            previewMeetings.forEach { meeting ->
                                MeetingLineItem(
                                    meeting = meeting,
                                    onClick = { onOpenMeeting(meeting.id) },
                                )
                            }
                            if (hasMoreMeetings) {
                                TextButton(onClick = onOpenHistory) {
                                    Text(stringResource(R.string.meeting_show_more, friendAggregate.meetings.size - previewMeetings.size))
                                }
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = { onCreateMeeting(MeetingKind.MEETING) }) {
                            Text(stringResource(R.string.calendar_new_meeting))
                        }
                        Button(onClick = { onCreateMeeting(MeetingKind.EVENT) }) {
                            Text(stringResource(R.string.calendar_new_event))
                        }
                    }
                }
            }

            if (editMode) {
                item {
                    TextButton(onClick = { showDeleteDialog = true }) {
                        Icon(Icons.Default.Delete, contentDescription = null)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(stringResource(R.string.common_delete), color = FriendNotesThemeExtras.colors.semanticDanger)
                    }
                }
            }
        }
    }

    if (showDeleteDialog) {
        AppAlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.common_delete)) },
            text = { Text(stringResource(R.string.friends_delete_warning)) },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        viewModel.deleteFriend(friendId)
                        showDeleteDialog = false
                        onBack()
                    }
                }) {
                    Text(stringResource(R.string.common_delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        )
    }

    if (showBirthdayPicker) {
        AppDatePickerDialog(
            initialDate = birthday ?: friend.birthday ?: LocalDate.now(),
            onDismiss = { showBirthdayPicker = false },
            onConfirm = {
                birthday = it
                showBirthdayPicker = false
            },
        )
    }
}

@Composable
private fun DetailSectionCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        color = FriendNotesThemeExtras.colors.surfaceCard.copy(alpha = 0.42f),
        border = BorderStroke(1.dp, FriendNotesThemeExtras.colors.cardBorder.copy(alpha = 0.24f)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            content = {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                )
                content()
            },
        )
    }
}

@Composable
private fun GroupedPanel(content: @Composable ColumnScope.() -> Unit) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp),
        color = colors.surfaceCard.copy(alpha = 0.4f),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.2f)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            content = content,
        )
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.72f),
        fontWeight = FontWeight.SemiBold,
    )
}

@Composable
private fun CategoryRow(title: String, count: Int, onClick: () -> Unit) {
    TransparentListItem(
        onClick = onClick,
        accentColor = MaterialTheme.colorScheme.primary,
    ) {
        Row(
            modifier = Modifier
                .weight(1f),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(title)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("$count", fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    imageVector = Icons.Default.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FriendHistoryScreen(
    viewModel: FriendNotesViewModel,
    friendId: Long,
    onBack: () -> Unit,
    onOpenMeeting: (Long) -> Unit,
    onCreateMeeting: (MeetingKind) -> Unit,
) {
    val allFriends by viewModel.friends.collectAsStateWithLifecycle()
    val friendAggregate = allFriends.firstOrNull { it.friend.id == friendId }

    if (friendAggregate == null) {
        LaunchedEffect(Unit) { onBack() }
        return
    }

    var showAddMenu by remember { mutableStateOf(false) }
    var showAllUpcoming by rememberSaveable(friendId) { mutableStateOf(false) }
    val now = ZonedDateTime.now()
    val upcoming = friendAggregate.meetings
        .filter { !it.startDate.isBefore(now) }
        .sortedBy { it.startDate }
    val past = friendAggregate.meetings
        .filter { it.startDate.isBefore(now) }
        .sortedByDescending { it.startDate }
    val visibleUpcoming = if (showAllUpcoming) upcoming else upcoming.take(5)

    Scaffold(
        containerColor = Color.Transparent,
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .statusBarsPadding()
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(bottom = 48.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                LargeScreenHeader(
                    title = stringResource(R.string.meeting_history_title),
                    leading = { HeaderIconButton(onClick = onBack, icon = Icons.Default.ArrowBack) },
                    trailing = {
                        HeaderTextButton(
                            text = stringResource(R.string.common_add),
                            onClick = { showAddMenu = true },
                        )
                        AppDropdownMenu(expanded = showAddMenu, onDismissRequest = { showAddMenu = false }) {
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.calendar_new_meeting)) },
                                onClick = {
                                    showAddMenu = false
                                    onCreateMeeting(MeetingKind.MEETING)
                                },
                            )
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.calendar_new_event)) },
                                onClick = {
                                    showAddMenu = false
                                    onCreateMeeting(MeetingKind.EVENT)
                                },
                            )
                        }
                    },
                )
                if (upcoming.isEmpty() && past.isEmpty()) {
                    DetailSectionCard(title = stringResource(R.string.meeting_history_title)) {
                        Text(
                            text = stringResource(R.string.meeting_history_empty),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        )
                    }
                }
            }

            if (upcoming.isNotEmpty()) {
                item {
                    DetailSectionCard(title = stringResource(R.string.meeting_section_upcoming)) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            visibleUpcoming.forEach { meeting ->
                                MeetingLineItem(
                                    meeting = meeting,
                                    onClick = { onOpenMeeting(meeting.id) },
                                )
                            }
                            if (upcoming.size > visibleUpcoming.size) {
                                TextButton(onClick = { showAllUpcoming = true }) {
                                    Text(stringResource(R.string.meeting_show_more, upcoming.size - visibleUpcoming.size))
                                }
                            }
                        }
                    }
                }
            }

            if (past.isNotEmpty()) {
                item {
                    DetailSectionCard(title = stringResource(R.string.meeting_section_past)) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            past.forEach { meeting ->
                                MeetingLineItem(
                                    meeting = meeting,
                                    onClick = { onOpenMeeting(meeting.id) },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EntryCategoryScreen(
    viewModel: FriendNotesViewModel,
    friendId: Long,
    category: FriendEntryCategory,
    onBack: () -> Unit,
    snackbarHostState: SnackbarHostState,
) {
    val allFriends by viewModel.friends.collectAsStateWithLifecycle()
    val friendAggregate = allFriends.firstOrNull { it.friend.id == friendId }
    val entries = friendAggregate?.entries
        ?.filter { it.category == category }
        ?.sortedWith(compareBy({ it.order }, { it.createdAt }))
        .orEmpty()

    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var editingEntryId by rememberSaveable { mutableStateOf<Long?>(null) }
    var titleInput by rememberSaveable { mutableStateOf("") }
    var noteInput by rememberSaveable { mutableStateOf("") }
    var showDialog by rememberSaveable { mutableStateOf(false) }

    fun openForEdit(entryId: Long?) {
        editingEntryId = entryId
        val current = entries.firstOrNull { it.id == entryId }
        titleInput = current?.title.orEmpty()
        noteInput = current?.note.orEmpty()
        showDialog = true
    }

    Scaffold(
        containerColor = Color.Transparent,
        floatingActionButton = {
            FloatingActionButton(onClick = { openForEdit(null) }) {
                Icon(Icons.Default.Add, contentDescription = null)
            }
        },
    ) { innerPadding ->
        if (entries.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Column {
                    LargeScreenHeader(
                        title = stringResource(categoryTitleRes(category)),
                        leading = { HeaderIconButton(onClick = onBack, icon = Icons.Default.ArrowBack) },
                        trailing = { HeaderTextButton(text = stringResource(R.string.common_add), onClick = { openForEdit(null) }) },
                    )
                    Spacer(modifier = Modifier.height(40.dp))
                    Text(stringResource(R.string.entry_empty))
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                contentPadding = PaddingValues(bottom = 100.dp),
            ) {
                item {
                    LargeScreenHeader(
                        title = stringResource(categoryTitleRes(category)),
                        leading = { HeaderIconButton(onClick = onBack, icon = Icons.Default.ArrowBack) },
                        trailing = { HeaderTextButton(text = stringResource(R.string.common_add), onClick = { openForEdit(null) }) },
                    )
                }
                items(entries, key = { it.id }) { entry ->
                    TransparentListItem(
                        accentColor = MaterialTheme.colorScheme.primary,
                    ) {
                        Row(
                            modifier = Modifier
                                .weight(1f),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(entry.title, fontWeight = FontWeight.SemiBold)
                                if (entry.note.isNotBlank()) {
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(entry.note, style = MaterialTheme.typography.bodySmall)
                                }
                            }
                            IconButton(onClick = { openForEdit(entry.id) }) {
                                Icon(Icons.Default.Edit, contentDescription = null)
                            }
                            IconButton(onClick = {
                                scope.launch {
                                    viewModel.deleteEntry(entry.id)
                                }
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = null)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showDialog) {
        AppAlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text(stringResource(if (editingEntryId == null) R.string.entry_add else R.string.entry_edit)) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = titleInput,
                        onValueChange = { titleInput = it },
                        label = { Text(stringResource(R.string.entry_title)) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                    OutlinedTextField(
                        value = noteInput,
                        onValueChange = { noteInput = it },
                        label = { Text(stringResource(R.string.entry_note)) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        val ok = viewModel.upsertEntry(
                            friendId = friendId,
                            entryId = editingEntryId,
                            category = category,
                            title = titleInput,
                            note = noteInput,
                        )
                        if (!ok) {
                            snackbarHostState.showSnackbar(context.getString(R.string.entry_required_title))
                        } else {
                            showDialog = false
                        }
                    }
                }) {
                    Text(stringResource(R.string.common_save))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDialog = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun GiftsScreen(
    viewModel: FriendNotesViewModel,
    friendId: Long,
    onBack: () -> Unit,
    snackbarHostState: SnackbarHostState,
) {
    val allFriends by viewModel.friends.collectAsStateWithLifecycle()
    val friendAggregate = allFriends.firstOrNull { it.friend.id == friendId }
    val gifts = friendAggregate?.giftIdeas.orEmpty()

    val openIdeas = gifts.filter { !it.isGifted }
    val doneIdeas = gifts.filter { it.isGifted }

    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var editingGiftId by rememberSaveable { mutableStateOf<Long?>(null) }
    var titleInput by rememberSaveable { mutableStateOf("") }
    var noteInput by rememberSaveable { mutableStateOf("") }
    var isGiftedInput by rememberSaveable { mutableStateOf(false) }
    var showDialog by rememberSaveable { mutableStateOf(false) }

    fun openEdit(giftId: Long?) {
        editingGiftId = giftId
        val current = gifts.firstOrNull { it.id == giftId }
        titleInput = current?.title.orEmpty()
        noteInput = current?.note.orEmpty()
        isGiftedInput = current?.isGifted ?: false
        showDialog = true
    }

    Scaffold(
        containerColor = Color.Transparent,
        floatingActionButton = {
            FloatingActionButton(onClick = { openEdit(null) }) {
                Icon(Icons.Default.Add, contentDescription = null)
            }
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .statusBarsPadding()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(bottom = 96.dp),
        ) {
            item {
                LargeScreenHeader(
                    title = stringResource(R.string.gifts_title),
                    leading = { HeaderIconButton(onClick = onBack, icon = Icons.Default.ArrowBack) },
                )
            }
            item {
                GiftSection(
                    title = stringResource(R.string.gifts_open),
                    emptyText = stringResource(R.string.gifts_empty),
                    count = openIdeas.size,
                ) {
                    openIdeas.forEach { gift ->
                        GiftRow(
                            title = gift.title,
                            note = gift.note,
                            isGifted = gift.isGifted,
                            onToggleGifted = {
                                scope.launch { viewModel.toggleGifted(gift.id, !gift.isGifted) }
                            },
                            onTap = { openEdit(gift.id) },
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
            item {
                GiftSection(
                    title = stringResource(R.string.gifts_done),
                    emptyText = stringResource(R.string.gifts_empty),
                    count = doneIdeas.size,
                ) {
                    doneIdeas.forEach { gift ->
                        GiftRow(
                            title = gift.title,
                            note = gift.note,
                            isGifted = gift.isGifted,
                            onToggleGifted = {
                                scope.launch { viewModel.toggleGifted(gift.id, !gift.isGifted) }
                            },
                            onTap = { openEdit(gift.id) },
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }

    if (showDialog) {
        AppAlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text(stringResource(if (editingGiftId == null) R.string.gift_add else R.string.gift_edit)) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = titleInput,
                        onValueChange = { titleInput = it },
                        label = { Text(stringResource(R.string.entry_title)) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                    OutlinedTextField(
                        value = noteInput,
                        onValueChange = { noteInput = it },
                        label = { Text(stringResource(R.string.entry_note)) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = isGiftedInput, onCheckedChange = { isGiftedInput = it })
                        Text(stringResource(R.string.gifts_done))
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        val ok = viewModel.upsertGift(
                            friendId = friendId,
                            giftId = editingGiftId,
                            title = titleInput,
                            note = noteInput,
                            isGifted = isGiftedInput,
                        )
                        if (ok) {
                            showDialog = false
                        } else {
                            snackbarHostState.showSnackbar(context.getString(R.string.gift_required_title))
                        }
                    }
                }) {
                    Text(stringResource(R.string.common_save))
                }
            },
            dismissButton = {
                Row {
                    if (editingGiftId != null) {
                        TextButton(onClick = {
                            scope.launch {
                                viewModel.deleteGift(editingGiftId!!)
                                showDialog = false
                            }
                        }) {
                            Text(stringResource(R.string.common_delete))
                        }
                    }
                    TextButton(onClick = { showDialog = false }) {
                        Text(stringResource(R.string.common_cancel))
                    }
                }
            },
        )
    }
}

@Composable
private fun GiftSection(
    title: String,
    count: Int,
    emptyText: String,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.24f)),
        color = colors.surfaceCard.copy(alpha = 0.48f),
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Surface(
                    shape = RoundedCornerShape(999.dp),
                    color = colors.surfaceChip,
                ) {
                    Text(
                        text = "$count",
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 3.dp),
                        style = MaterialTheme.typography.labelLarge,
                    )
                }
            }
            Spacer(modifier = Modifier.height(10.dp))
            if (count == 0) {
                Text(
                    text = emptyText,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.78f),
                )
            } else {
                content()
            }
        }
    }
}

@Composable
private fun GiftRow(
    title: String,
    note: String,
    isGifted: Boolean,
    onToggleGifted: () -> Unit,
    onTap: () -> Unit,
) {
    TransparentListItem(
        onClick = onTap,
        accentColor = if (isGifted) MaterialTheme.colorScheme.primary else FriendNotesThemeExtras.colors.semanticEvent,
    ) {
        Row(
            modifier = Modifier
                .weight(1f),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .clip(CircleShape)
                    .clickable { onToggleGifted() },
                contentAlignment = Alignment.Center,
            ) {
                Surface(
                    modifier = Modifier.size(22.dp),
                    shape = CircleShape,
                    color = Color.Transparent,
                    border = BorderStroke(
                        1.dp,
                        if (isGifted) {
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.55f)
                        } else {
                            FriendNotesThemeExtras.colors.cardBorder.copy(alpha = 0.45f)
                        },
                    ),
                ) {}
                if (isGifted) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(14.dp),
                    )
                }
            }
            Spacer(modifier = Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    title,
                    fontWeight = FontWeight.SemiBold,
                    textDecoration = if (isGifted) TextDecoration.LineThrough else null,
                )
                if (note.isNotBlank()) {
                    Text(
                        note,
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f),
                        textDecoration = if (isGifted) TextDecoration.LineThrough else null,
                    )
                }
            }
            Icon(
                imageVector = Icons.Default.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CalendarScreen(
    viewModel: FriendNotesViewModel,
    onOpenFriend: (Long) -> Unit,
    onOpenMeeting: (Long) -> Unit,
    onCreateMeeting: (MeetingKind) -> Unit,
) {
    val allFriends by viewModel.friends.collectAsStateWithLifecycle()
    val meetings by viewModel.meetings.collectAsStateWithLifecycle()
    val settings by viewModel.settings.collectAsStateWithLifecycle()

    var mode by rememberSaveable { mutableStateOf(0) }
    var selectedDate by rememberSaveable { mutableStateOf(LocalDate.now()) }
    var currentMonth by rememberSaveable { mutableStateOf(YearMonth.now()) }
    var showAddMenu by remember { mutableStateOf(false) }

    val eventsByDay = remember(meetings, allFriends, settings.showBirthdaysOnCalendar, currentMonth) {
        buildMap<LocalDate, MutableList<DayCalendarItem>> {
            meetings.forEach { aggregate ->
                val date = aggregate.meeting.startDate.toLocalDate()
                getOrPut(date) { mutableListOf() }.add(
                    DayCalendarItem.MeetingItem(aggregate)
                )
            }
            if (settings.showBirthdaysOnCalendar) {
                allFriends.forEach { friendAggregate ->
                    friendAggregate.friend.birthday?.let { birthday ->
                        val day = birthday.withYear(currentMonth.year)
                        getOrPut(day) { mutableListOf() }.add(DayCalendarItem.BirthdayItem(friendAggregate.friend))
                    }
                }
            }
        }
    }

    val selectedItems = eventsByDay[selectedDate].orEmpty()

    LaunchedEffect(currentMonth) {
        selectedDate = if (currentMonth == YearMonth.now()) {
            LocalDate.now()
        } else {
            currentMonth.atDay(1)
        }
    }

    Scaffold(
        containerColor = Color.Transparent,
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .statusBarsPadding()
                .padding(horizontal = 16.dp),
        ) {
            LargeScreenHeader(
                title = stringResource(R.string.calendar_title),
                trailing = {
                    HeaderTextButton(
                        text = stringResource(R.string.common_add),
                        onClick = { showAddMenu = true },
                    )
                    AppDropdownMenu(expanded = showAddMenu, onDismissRequest = { showAddMenu = false }) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.calendar_new_meeting)) },
                            onClick = {
                                showAddMenu = false
                                onCreateMeeting(MeetingKind.MEETING)
                            },
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.calendar_new_event)) },
                            onClick = {
                                showAddMenu = false
                                onCreateMeeting(MeetingKind.EVENT)
                            },
                        )
                    }
                },
            )
            Spacer(modifier = Modifier.height(12.dp))
            CalendarModeSwitch(mode = mode, onModeChange = { mode = it })
            Spacer(modifier = Modifier.height(14.dp))

            Crossfade(targetState = mode, label = "calendarMode") { selectedMode ->
                if (selectedMode == 0) {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        CalendarMonthView(
                            currentMonth = currentMonth,
                            selectedDate = selectedDate,
                            eventsByDay = eventsByDay,
                            onPreviousMonth = { currentMonth = currentMonth.minusMonths(1) },
                            onNextMonth = { currentMonth = currentMonth.plusMonths(1) },
                            onDateSelected = { selectedDate = it },
                        )

                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(18.dp),
                            color = FriendNotesThemeExtras.colors.surfaceCard.copy(alpha = 0.82f),
                            border = BorderStroke(1.dp, FriendNotesThemeExtras.colors.cardBorder.copy(alpha = 0.45f)),
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Text(stringResource(R.string.calendar_meetings_events), style = MaterialTheme.typography.titleMedium)
                                Spacer(modifier = Modifier.height(8.dp))
                                if (selectedItems.isEmpty()) {
                                    Text(
                                        text = stringResource(R.string.calendar_no_items),
                                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.72f),
                                    )
                                } else {
                                    val listState = rememberLazyListState()
                                    LazyColumn(
                                        state = listState,
                                        verticalArrangement = Arrangement.spacedBy(8.dp),
                                        contentPadding = PaddingValues(bottom = 4.dp),
                                    ) {
                                        items(selectedItems) { item ->
                                            when (item) {
                                                is DayCalendarItem.BirthdayItem -> {
                                                    BirthdayLine(
                                                        friend = item.friend,
                                                        onClick = { onOpenFriend(item.friend.id) },
                                                    )
                                                }
                                                is DayCalendarItem.MeetingItem -> {
                                                    MeetingLineItem(item.aggregate.meeting, onClick = { onOpenMeeting(item.aggregate.meeting.id) })
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    UpcomingList(
                        allFriends = allFriends,
                        meetings = meetings,
                        onOpenFriend = onOpenFriend,
                        onOpenMeeting = onOpenMeeting,
                    )
                }
            }
        }
    }
}

@Composable
private fun CalendarModeSwitch(mode: Int, onModeChange: (Int) -> Unit) {
    val colors = FriendNotesThemeExtras.colors
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.38f)),
        color = colors.surfaceElevated.copy(alpha = 0.72f),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(5.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            listOf(
                0 to stringResource(R.string.calendar_mode_calendar),
                1 to stringResource(R.string.calendar_mode_upcoming),
            ).forEach { (index, label) ->
                val selected = mode == index
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(12.dp))
                        .clickable { onModeChange(index) },
                    color = if (selected) colors.subtleFillSelected else Color.Transparent,
                ) {
                    Text(
                        text = label,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 9.dp),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelLarge,
                        color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f),
                    )
                }
            }
        }
    }
}

@Composable
private fun CalendarMonthView(
    currentMonth: YearMonth,
    selectedDate: LocalDate,
    eventsByDay: Map<LocalDate, List<DayCalendarItem>>,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    onDateSelected: (LocalDate) -> Unit,
) {
    val colors = FriendNotesThemeExtras.colors
    val firstDay = currentMonth.atDay(1)
    val locale = Locale.getDefault()
    val firstDayOfWeek = WeekFields.of(locale).firstDayOfWeek
    val firstDayOffset = (firstDay.dayOfWeek.value - firstDayOfWeek.value + 7) % 7
    val daysInMonth = currentMonth.lengthOfMonth()

    val cells = buildList<LocalDate?> {
        repeat(firstDayOffset) { add(null) }
        for (day in 1..daysInMonth) {
            add(currentMonth.atDay(day))
        }
        while (size % 7 != 0) {
            add(null)
        }
    }

    Surface(
        shape = RoundedCornerShape(18.dp),
        color = colors.surfaceCard.copy(alpha = 0.84f),
        border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.45f)),
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconButton(onClick = onPreviousMonth) {
                    Icon(Icons.Default.ArrowBack, contentDescription = null)
                }
                Text(
                    text = currentMonth.format(DateTimeFormatter.ofPattern("MMMM yyyy", locale)),
                    style = MaterialTheme.typography.titleMedium,
                )
                IconButton(onClick = onNextMonth) {
                    Icon(Icons.Default.ArrowForward, contentDescription = null, modifier = Modifier.size(20.dp))
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                val weekdays = orderedWeekdays(firstDayOfWeek)
                weekdays.forEach { label ->
                    Text(
                        text = label.getDisplayName(TextStyle.SHORT, locale),
                        modifier = Modifier
                            .weight(1f)
                            .height(28.dp),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.78f),
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))
            cells.chunked(7).forEach { week ->
                Row(modifier = Modifier.fillMaxWidth()) {
                    week.forEach { date ->
                        val isSelected = date == selectedDate
                        val isToday = date == LocalDate.now()
                        val hasBirthday = date != null && eventsByDay[date]?.any { it is DayCalendarItem.BirthdayItem } == true
                        val hasMeeting = date != null && eventsByDay[date]?.any { it is DayCalendarItem.MeetingItem } == true

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .padding(vertical = 2.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Column(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(RoundedCornerShape(14.dp))
                                    .background(
                                        when {
                                            isSelected -> colors.subtleFillSelected
                                            isToday -> colors.subtleFill
                                            else -> Color.Transparent
                                        }
                                    )
                                    .clickable(enabled = date != null) { date?.let(onDateSelected) },
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center,
                            ) {
                                Text(
                                    text = date?.dayOfMonth?.toString().orEmpty(),
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = if (date == null) 0f else 1f),
                                )
                                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                                    if (hasBirthday) {
                                        Box(
                                            modifier = Modifier
                                                .size(5.dp)
                                                .clip(CircleShape)
                                                .background(colors.semanticBirthday)
                                        )
                                    }
                                    if (hasMeeting) {
                                        Box(
                                            modifier = Modifier
                                                .size(5.dp)
                                                .clip(CircleShape)
                                                .background(colors.semanticEvent)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer(modifier = Modifier.height(3.dp))
            }
        }
    }
}

@Composable
private fun UpcomingList(
    allFriends: List<FriendAggregate>,
    meetings: List<MeetingAggregate>,
    onOpenFriend: (Long) -> Unit,
    onOpenMeeting: (Long) -> Unit,
) {
    val colors = FriendNotesThemeExtras.colors
    val now = ZonedDateTime.now()

    val upcomingItems = remember(allFriends, meetings) {
        buildList<UpcomingItem> {
            meetings
                .filter { it.meeting.startDate.isAfter(now) }
                .forEach { aggregate ->
                    add(UpcomingItem.MeetingItem(aggregate))
                }
            allFriends.forEach { friendAggregate ->
                val birthday = friendAggregate.friend.birthday ?: return@forEach
                var nextBirthday = birthday.withYear(now.year)
                if (!nextBirthday.atStartOfDay(now.zone).isAfter(now)) {
                    nextBirthday = nextBirthday.plusYears(1)
                }
                add(UpcomingItem.BirthdayItem(friendAggregate.friend, nextBirthday))
            }
        }.sortedBy { it.dateTime() }
    }

    if (upcomingItems.isEmpty()) {
        Text(stringResource(R.string.calendar_upcoming_empty))
        return
    }

    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(bottom = 16.dp),
    ) {
        var lastWeek: Int? = null
        upcomingItems.forEach { item ->
            val week = item.dateTime().get(WeekFields.of(Locale.getDefault()).weekOfWeekBasedYear())
            if (lastWeek != week) {
                item {
                    Surface(
                        shape = RoundedCornerShape(999.dp),
                        color = colors.surfaceChip.copy(alpha = 0.9f),
                    ) {
                        Text(
                            text = stringResource(R.string.calendar_week_label, week),
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 5.dp),
                            style = MaterialTheme.typography.labelLarge,
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                }
                lastWeek = week
            }
            item {
                when (item) {
                    is UpcomingItem.BirthdayItem -> BirthdayLine(
                        friend = item.friend,
                        date = item.date,
                        onClick = { onOpenFriend(item.friend.id) },
                    )
                    is UpcomingItem.MeetingItem -> MeetingLineItem(item.aggregate.meeting) { onOpenMeeting(item.aggregate.meeting.id) }
                }
            }
        }
    }
}

@Composable
private fun BirthdayLine(friend: Friend, date: LocalDate? = friend.birthday, onClick: (() -> Unit)? = null) {
    val displayName = buildString {
        val nick = friend.nickname.trim()
        val full = "${friend.firstName} ${friend.lastName}".trim()
        append(if (nick.isNotBlank()) nick else if (full.isNotBlank()) full else "?")
    }

    val ageText = date?.let {
        if (friend.birthday != null && friend.birthday.year > 1900) {
            val age = it.year - friend.birthday.year
            if (age > 0) " (${stringResource(R.string.calendar_age, age)})" else ""
        } else {
            ""
        }
    } ?: ""

    TransparentListItem(
        onClick = onClick,
        accentColor = FriendNotesThemeExtras.colors.semanticBirthday,
    ) {
        Row(
            modifier = Modifier
                .weight(1f),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Default.Cake,
                contentDescription = null,
                tint = FriendNotesThemeExtras.colors.semanticBirthday,
                modifier = Modifier.size(18.dp),
            )
            Spacer(modifier = Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "$displayName$ageText",
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    date?.format(localizedDateFormatter()).orEmpty(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.78f),
                )
            }
        }
    }
}

@Composable
private fun MeetingLineItem(
    meeting: Meeting,
    onClick: () -> Unit,
) {
    val leadingColor = if (meeting.kind == MeetingKind.EVENT) {
        FriendNotesThemeExtras.colors.semanticEvent
    } else {
        MaterialTheme.colorScheme.primary
    }
    TransparentListItem(
        onClick = onClick,
        accentColor = leadingColor,
    ) {
        Row(
            modifier = Modifier
                .weight(1f),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = if (meeting.kind == MeetingKind.EVENT) Icons.Default.Flag else Icons.Default.PeopleAlt,
                contentDescription = null,
                tint = leadingColor,
                modifier = Modifier.size(18.dp),
            )
            Spacer(modifier = Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                val title = if (meeting.kind == MeetingKind.EVENT && meeting.eventTitle.isNotBlank()) {
                    meeting.eventTitle
                } else if (meeting.kind == MeetingKind.EVENT) {
                    stringResource(R.string.event_title)
                } else {
                    stringResource(R.string.meeting_title)
                }
                Text(title, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = formatMeetingDateRange(meeting),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.78f),
                )
            }
            Icon(
                imageVector = Icons.Default.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
            )
        }
    }
}

private sealed class UpcomingItem {
    abstract fun dateTime(): ZonedDateTime

    data class MeetingItem(val aggregate: MeetingAggregate) : UpcomingItem() {
        override fun dateTime(): ZonedDateTime = aggregate.meeting.startDate
    }

    data class BirthdayItem(val friend: Friend, val date: LocalDate) : UpcomingItem() {
        override fun dateTime(): ZonedDateTime = date.atStartOfDay(ZonedDateTime.now().zone)
    }
}

private sealed class DayCalendarItem {
    data class BirthdayItem(val friend: Friend) : DayCalendarItem()
    data class MeetingItem(val aggregate: MeetingAggregate) : DayCalendarItem()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsScreen(viewModel: FriendNotesViewModel, snackbarHostState: SnackbarHostState) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var newTag by rememberSaveable { mutableStateOf("") }

    Scaffold(
        containerColor = Color.Transparent,
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            LargeScreenHeader(title = stringResource(R.string.settings_title))

            SectionLabel(stringResource(R.string.settings_section_notifications))
            GroupedPanel {
                SettingsToggleRow(
                    title = stringResource(R.string.settings_notifications),
                    checked = settings.notificationsEnabled,
                    showDivider = settings.notificationsEnabled,
                    onCheckedChange = { value ->
                        scope.launch { viewModel.updateSettings { it.copy(notificationsEnabled = value) } }
                    },
                )
                if (settings.notificationsEnabled) {
                    SettingsToggleRow(
                        title = stringResource(R.string.settings_notify_birthday),
                        checked = settings.globalNotifyBirthday,
                        showDivider = true,
                        onCheckedChange = { value ->
                            scope.launch { viewModel.updateSettings { it.copy(globalNotifyBirthday = value) } }
                        },
                    )
                    if (settings.globalNotifyBirthday) {
                        SettingsMenuRow(
                            label = stringResource(R.string.settings_when),
                            value = reminderDaysValueLabel(settings.globalBirthdayReminderDays),
                            options = (1..7).map { it to reminderDaysValueLabel(it) },
                            showDivider = true,
                            onSelect = { selected ->
                                scope.launch { viewModel.updateSettings { it.copy(globalBirthdayReminderDays = selected) } }
                            },
                        )
                    }

                    SettingsToggleRow(
                        title = stringResource(R.string.settings_notify_meetings),
                        checked = settings.globalNotifyMeetings,
                        showDivider = true,
                        onCheckedChange = { value ->
                            scope.launch { viewModel.updateSettings { it.copy(globalNotifyMeetings = value) } }
                        },
                    )
                    if (settings.globalNotifyMeetings) {
                        SettingsMenuRow(
                            label = stringResource(R.string.settings_when),
                            value = reminderDaysValueLabel(settings.globalMeetingReminderDays),
                            options = (1..7).map { it to reminderDaysValueLabel(it) },
                            showDivider = true,
                            onSelect = { selected ->
                                scope.launch { viewModel.updateSettings { it.copy(globalMeetingReminderDays = selected) } }
                            },
                        )
                    }

                    SettingsToggleRow(
                        title = stringResource(R.string.settings_notify_events),
                        checked = settings.globalNotifyEvents,
                        showDivider = true,
                        onCheckedChange = { value ->
                            scope.launch { viewModel.updateSettings { it.copy(globalNotifyEvents = value) } }
                        },
                    )
                    if (settings.globalNotifyEvents) {
                        SettingsMenuRow(
                            label = stringResource(R.string.settings_when),
                            value = reminderDaysValueLabel(settings.globalEventReminderDays),
                            options = (1..7).map { it to reminderDaysValueLabel(it) },
                            showDivider = true,
                            onSelect = { selected ->
                                scope.launch { viewModel.updateSettings { it.copy(globalEventReminderDays = selected) } }
                            },
                        )
                    }

                    SettingsToggleRow(
                        title = stringResource(R.string.settings_notify_long_no_meeting),
                        checked = settings.globalNotifyLongNoMeeting,
                        showDivider = true,
                        onCheckedChange = { value ->
                            scope.launch { viewModel.updateSettings { it.copy(globalNotifyLongNoMeeting = value) } }
                        },
                    )
                    if (settings.globalNotifyLongNoMeeting) {
                        SettingsMenuRow(
                            label = stringResource(R.string.settings_when),
                            value = weeksValueLabel(settings.globalLongNoMeetingWeeks),
                            options = (1..26).map { it to weeksValueLabel(it) },
                            showDivider = true,
                            onSelect = { selected ->
                                scope.launch { viewModel.updateSettings { it.copy(globalLongNoMeetingWeeks = selected) } }
                            },
                        )
                    }

                    SettingsToggleRow(
                        title = stringResource(R.string.settings_notify_post_meeting_note),
                        checked = settings.globalNotifyPostMeetingNote,
                        showDivider = false,
                        onCheckedChange = { value ->
                            scope.launch { viewModel.updateSettings { it.copy(globalNotifyPostMeetingNote = value) } }
                        },
                    )
                }
            }

            SectionLabel(stringResource(R.string.settings_section_calendar))
            GroupedPanel {
                SettingsToggleRow(
                    title = stringResource(R.string.settings_show_birthdays_calendar),
                    checked = settings.showBirthdaysOnCalendar,
                    showDivider = false,
                    onCheckedChange = { value ->
                        scope.launch { viewModel.updateSettings { it.copy(showBirthdaysOnCalendar = value) } }
                    },
                )
            }

            SectionLabel(stringResource(R.string.settings_section_tags))
            GroupedPanel {
                if (settings.definedFriendTags.isEmpty()) {
                    Text(
                        text = stringResource(R.string.settings_tags_empty),
                        modifier = Modifier.padding(vertical = 12.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.72f),
                    )
                } else {
                    settings.definedFriendTags.forEachIndexed { index, tag ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(text = tag, modifier = Modifier.weight(1f))
                            IconButton(onClick = {
                                scope.launch { viewModel.removeGlobalTag(tag) }
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = null, tint = FriendNotesThemeExtras.colors.semanticDanger.copy(alpha = 0.8f))
                            }
                        }
                        if (index != settings.definedFriendTags.lastIndex) {
                            HorizontalDivider(color = FriendNotesThemeExtras.colors.cardBorder.copy(alpha = 0.22f))
                        }
                    }
                }
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = newTag,
                    onValueChange = { newTag = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text(stringResource(R.string.settings_add_tag_hint)) },
                    singleLine = true,
                )
                Spacer(modifier = Modifier.width(8.dp))
                HeaderTextButton(
                    text = stringResource(R.string.settings_add_tag),
                    onClick = {
                        scope.launch {
                            when (viewModel.addGlobalTag(newTag)) {
                                FriendNotesViewModel.TagResult.Added -> newTag = ""
                                FriendNotesViewModel.TagResult.Duplicate -> snackbarHostState.showSnackbar(
                                    context.getString(R.string.settings_duplicate_tag)
                                )
                                FriendNotesViewModel.TagResult.Invalid -> snackbarHostState.showSnackbar(
                                    context.getString(R.string.settings_invalid_tag)
                                )
                            }
                        }
                    },
                )
            }

            SectionLabel(stringResource(R.string.privacy_title))
            Text(
                text = stringResource(R.string.privacy_body),
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.72f),
            )
            Spacer(modifier = Modifier.height(28.dp))
        }
    }
}

@Composable
private fun SettingsToggleRow(
    title: String,
    checked: Boolean,
    showDivider: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(title)
            Switch(checked = checked, onCheckedChange = onCheckedChange)
        }
        if (showDivider) {
            HorizontalDivider(color = FriendNotesThemeExtras.colors.cardBorder.copy(alpha = 0.22f))
        }
    }
}

@Composable
private fun SettingsMenuRow(
    label: String,
    value: String,
    options: List<Pair<Int, String>>,
    showDivider: Boolean,
    onSelect: (Int) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = true }
                .padding(vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = label,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.68f),
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = value,
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.88f),
                )
                Spacer(modifier = Modifier.width(4.dp))
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.74f),
                )
            }
            AppDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                options.forEach { (option, optionLabel) ->
                    DropdownMenuItem(
                        text = { Text(optionLabel) },
                        onClick = {
                            expanded = false
                            onSelect(option)
                        },
                    )
                }
            }
        }
        if (showDivider) {
            HorizontalDivider(color = FriendNotesThemeExtras.colors.cardBorder.copy(alpha = 0.22f))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MeetingEditorScreen(
    viewModel: FriendNotesViewModel,
    initialKind: MeetingKind?,
    meetingId: Long?,
    onBack: () -> Unit,
    snackbarHostState: SnackbarHostState,
) {
    val meetings by viewModel.meetings.collectAsStateWithLifecycle()
    val friends by viewModel.friends.collectAsStateWithLifecycle()

    val existing = meetings.firstOrNull { it.meeting.id == meetingId }
    val kind = initialKind ?: existing?.meeting?.kind ?: MeetingKind.MEETING
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var editMode by rememberSaveable { mutableStateOf(meetingId == null) }
    var eventTitle by rememberSaveable(meetingId) { mutableStateOf(existing?.meeting?.eventTitle.orEmpty()) }
    var startDate by rememberSaveable(meetingId) { mutableStateOf(existing?.meeting?.startDate ?: ZonedDateTime.now()) }
    var endDate by rememberSaveable(meetingId) { mutableStateOf(existing?.meeting?.endDate ?: ZonedDateTime.now().plusHours(1)) }
    var note by rememberSaveable(meetingId) { mutableStateOf(existing?.meeting?.note.orEmpty()) }
    val selectedFriendIds = remember(meetingId) {
        mutableStateListOf<Long>().apply {
            addAll(existing?.meeting?.friendIds.orEmpty())
        }
    }
    var showDeleteDialog by rememberSaveable { mutableStateOf(false) }
    var showStartPicker by rememberSaveable { mutableStateOf(false) }
    var showEndPicker by rememberSaveable { mutableStateOf(false) }
    val displayTitle = when {
        kind == MeetingKind.EVENT && eventTitle.isNotBlank() -> eventTitle
        kind == MeetingKind.EVENT -> context.getString(R.string.event_title)
        else -> context.getString(R.string.meeting_title)
    }

    LaunchedEffect(existing?.meeting?.id) {
        if (meetingId != null && existing != null && !editMode) {
            eventTitle = existing.meeting.eventTitle
            startDate = existing.meeting.startDate
            endDate = existing.meeting.endDate
            note = existing.meeting.note
            selectedFriendIds.clear()
            selectedFriendIds.addAll(existing.meeting.friendIds)
        }
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        when {
                            meetingId == null && kind == MeetingKind.EVENT -> stringResource(R.string.event_create_title)
                            meetingId == null -> stringResource(R.string.meeting_create_title)
                            else -> displayTitle
                        }
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = null)
                    }
                },
                actions = {
                    if (meetingId != null && !editMode) {
                        TextButton(onClick = { editMode = true }) {
                            Text(stringResource(R.string.common_edit))
                        }
                    }
                    if (editMode) {
                        TextButton(onClick = {
                            scope.launch {
                                val validation = viewModel.upsertMeeting(
                                    meetingId = meetingId,
                                    kind = kind,
                                    eventTitle = eventTitle,
                                    startDate = startDate,
                                    endDate = if (kind == MeetingKind.EVENT) startDate else endDate,
                                    note = note,
                                    friendIds = selectedFriendIds,
                                )
                                when (validation) {
                                    FriendNotesViewModel.MeetingValidation.Ok -> onBack()
                                    FriendNotesViewModel.MeetingValidation.InvalidMissingFriends -> snackbarHostState.showSnackbar(
                                        context.getString(R.string.meeting_validation_friend_required)
                                    )
                                    FriendNotesViewModel.MeetingValidation.InvalidEventTitle -> snackbarHostState.showSnackbar(
                                        context.getString(R.string.event_validation_fields_required)
                                    )
                                    FriendNotesViewModel.MeetingValidation.InvalidDateRange -> snackbarHostState.showSnackbar(
                                        context.getString(R.string.meeting_validation_date_order)
                                    )
                                }
                            }
                        }) {
                            Text(stringResource(R.string.common_save))
                        }
                    }
                },
                colors = topAppBarColors(),
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            if (kind == MeetingKind.EVENT) {
                if (editMode) {
                    OutlinedTextField(
                        value = eventTitle,
                        onValueChange = { eventTitle = it },
                        label = { Text(stringResource(R.string.meeting_title_field)) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                } else {
                    Text(displayTitle, style = MaterialTheme.typography.titleLarge)
                }
            }

            DateTimeRow(
                label = stringResource(R.string.meeting_start),
                value = startDate,
                editable = editMode,
                onPick = { showStartPicker = true },
            )

            if (kind == MeetingKind.MEETING) {
                DateTimeRow(
                    label = stringResource(R.string.meeting_end),
                    value = endDate,
                    editable = editMode,
                    onPick = { showEndPicker = true },
                )
            }

            Text(stringResource(R.string.meeting_friends), style = MaterialTheme.typography.titleMedium)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                friends.forEach { aggregate ->
                    val friend = aggregate.friend
                    val isSelected = selectedFriendIds.contains(friend.id)
                    FilterChip(
                        selected = isSelected,
                        onClick = {
                            if (!editMode) return@FilterChip
                            if (isSelected) {
                                selectedFriendIds.remove(friend.id)
                            } else {
                                selectedFriendIds.add(friend.id)
                            }
                        },
                        label = {
                            val text = viewModel.displayName(friend).ifBlank { stringResource(R.string.friends_unnamed) }
                            Text(text)
                        },
                    )
                }
            }

            if (editMode) {
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it },
                    label = { Text(stringResource(R.string.entry_note)) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 120.dp),
                    minLines = 4,
                )
            } else {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    color = FriendNotesThemeExtras.colors.surfaceCard,
                ) {
                    Text(
                        text = note.ifBlank { stringResource(R.string.meeting_note_empty) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        color = if (note.isBlank()) {
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f)
                        } else {
                            MaterialTheme.colorScheme.onSurface
                        },
                    )
                }
            }

            if (meetingId != null && editMode) {
                TextButton(onClick = { showDeleteDialog = true }) {
                    Icon(Icons.Default.Delete, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(stringResource(R.string.common_delete), color = FriendNotesThemeExtras.colors.semanticDanger)
                }
            }

            Spacer(modifier = Modifier.height(28.dp))
        }
    }

    if (showDeleteDialog && meetingId != null) {
        AppAlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.common_delete)) },
            text = { Text(stringResource(R.string.meeting_delete_warning)) },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        viewModel.deleteMeeting(meetingId)
                        showDeleteDialog = false
                        onBack()
                    }
                }) {
                    Text(stringResource(R.string.common_delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        )
    }

    if (showStartPicker) {
        AppDateTimePickerDialog(
            initial = startDate,
            onDismiss = { showStartPicker = false },
            onConfirm = { picked ->
                startDate = picked
                if (kind == MeetingKind.EVENT) {
                    endDate = picked
                }
                showStartPicker = false
            },
        )
    }

    if (showEndPicker) {
        AppDateTimePickerDialog(
            initial = endDate,
            onDismiss = { showEndPicker = false },
            onConfirm = { picked ->
                endDate = picked
                showEndPicker = false
            },
        )
    }
}

@Composable
private fun DateTimeRow(
    label: String,
    value: ZonedDateTime,
    editable: Boolean,
    onPick: () -> Unit,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = FriendNotesThemeExtras.colors.surfaceCard,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column {
                Text(label)
                Text(
                    text = value.format(localizedDateTimeFormatter()),
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            if (editable) {
                IconButton(onClick = onPick) {
                    Icon(Icons.Default.CalendarMonth, contentDescription = null)
                }
            }
        }
    }
}

private fun localizedDateFormatter(): DateTimeFormatter =
    DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(Locale.getDefault())

private fun localizedDateTimeFormatter(): DateTimeFormatter =
    DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM, FormatStyle.SHORT).withLocale(Locale.getDefault())

private fun formatMeetingDateRange(meeting: Meeting): String {
    val dateFormatter = localizedDateFormatter()
    val timeFormatter = DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT).withLocale(Locale.getDefault())
    return if (meeting.kind == MeetingKind.MEETING) {
        "${meeting.startDate.format(dateFormatter)} · ${meeting.startDate.format(timeFormatter)}-${meeting.endDate.format(timeFormatter)}"
    } else {
        meeting.startDate.format(localizedDateTimeFormatter())
    }
}

@Composable
private fun reminderDaysValueLabel(value: Int): String {
    return if (value == 1) {
        stringResource(R.string.settings_day_before_one)
    } else {
        stringResource(R.string.settings_day_before_other, value)
    }
}

@Composable
private fun weeksValueLabel(value: Int): String {
    return if (value == 1) {
        stringResource(R.string.settings_week_one)
    } else {
        stringResource(R.string.settings_week_other, value)
    }
}

private fun orderedWeekdays(firstDayOfWeek: DayOfWeek): List<DayOfWeek> {
    val allDays = DayOfWeek.entries
    val startIndex = allDays.indexOf(firstDayOfWeek)
    return allDays.drop(startIndex) + allDays.take(startIndex)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun topAppBarColors() =
    androidx.compose.material3.TopAppBarDefaults.centerAlignedTopAppBarColors(
        containerColor = Color.Transparent,
        scrolledContainerColor = Color.Transparent,
        navigationIconContentColor = MaterialTheme.colorScheme.onBackground,
        titleContentColor = MaterialTheme.colorScheme.onBackground,
        actionIconContentColor = MaterialTheme.colorScheme.onBackground,
    )

private fun categoryTitleRes(category: FriendEntryCategory): Int {
    return when (category) {
        FriendEntryCategory.HOBBIES -> R.string.category_hobbies
        FriendEntryCategory.FOODS -> R.string.category_foods
        FriendEntryCategory.MUSICS -> R.string.category_musics
        FriendEntryCategory.MOVIES_SERIES -> R.string.category_movies_series
        FriendEntryCategory.NOTES -> R.string.category_notes
    }
}
