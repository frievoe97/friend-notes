package com.example.friendnotes.app

import android.content.Context
import android.content.pm.ApplicationInfo
import com.example.friendnotes.data.AppRepository
import com.example.friendnotes.data.AppSettingsRepository
import com.example.friendnotes.data.local.AppDatabase
import com.example.friendnotes.data.local.DummyDataSeeder
import com.example.friendnotes.domain.usecase.FriendSearchSortUseCase
import com.example.friendnotes.notifications.ReminderScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class AppContainer(context: Context) {
    private val appContext = context.applicationContext
    private val database = AppDatabase.getInstance(appContext)
    private val settingsRepository = AppSettingsRepository(appContext)
    private val backgroundScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    val repository = AppRepository(
        database = database,
        settingsRepository = settingsRepository,
    )

    val friendSearchSortUseCase = FriendSearchSortUseCase()
    val reminderScheduler = ReminderScheduler(appContext)

    init {
        val isDebuggable = (appContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            backgroundScope.launch {
                DummyDataSeeder.seedIfNeeded(
                    database = database,
                    settingsRepository = settingsRepository,
                )
            }
        }
    }
}
