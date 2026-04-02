package com.example.friendnotes.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.friendnotes.domain.model.AppSettings
import com.example.friendnotes.util.JsonListCodec
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "friend_notes_settings")

class AppSettingsRepository(private val context: Context) {
    private val dataStore = context.settingsDataStore

    val settingsFlow: Flow<AppSettings> = dataStore.data.map { preferences ->
        AppSettings(
            notificationsEnabled = preferences[Keys.NOTIFICATIONS_ENABLED] ?: true,
            showBirthdaysOnCalendar = preferences[Keys.SHOW_BIRTHDAYS_ON_CALENDAR] ?: true,
            definedFriendTags = JsonListCodec.decode(preferences[Keys.DEFINED_FRIEND_TAGS] ?: "[]"),
            globalNotifyBirthday = preferences[Keys.GLOBAL_NOTIFY_BIRTHDAY] ?: true,
            globalBirthdayReminderDays = preferences[Keys.GLOBAL_BIRTHDAY_REMINDER_DAYS] ?: 3,
            globalNotifyMeetings = preferences[Keys.GLOBAL_NOTIFY_MEETINGS] ?: true,
            globalMeetingReminderDays = preferences[Keys.GLOBAL_MEETING_REMINDER_DAYS] ?: 1,
            globalNotifyEvents = preferences[Keys.GLOBAL_NOTIFY_EVENTS] ?: true,
            globalEventReminderDays = preferences[Keys.GLOBAL_EVENT_REMINDER_DAYS] ?: 2,
            globalNotifyLongNoMeeting = preferences[Keys.GLOBAL_NOTIFY_LONG_NO_MEETING] ?: false,
            globalLongNoMeetingWeeks = preferences[Keys.GLOBAL_LONG_NO_MEETING_WEEKS] ?: 4,
            globalNotifyPostMeetingNote = preferences[Keys.GLOBAL_NOTIFY_POST_MEETING_NOTE] ?: true,
        )
    }

    suspend fun update(transform: (AppSettings) -> AppSettings) {
        dataStore.edit { prefs ->
            val current = AppSettings(
                notificationsEnabled = prefs[Keys.NOTIFICATIONS_ENABLED] ?: true,
                showBirthdaysOnCalendar = prefs[Keys.SHOW_BIRTHDAYS_ON_CALENDAR] ?: true,
                definedFriendTags = JsonListCodec.decode(prefs[Keys.DEFINED_FRIEND_TAGS] ?: "[]"),
                globalNotifyBirthday = prefs[Keys.GLOBAL_NOTIFY_BIRTHDAY] ?: true,
                globalBirthdayReminderDays = prefs[Keys.GLOBAL_BIRTHDAY_REMINDER_DAYS] ?: 3,
                globalNotifyMeetings = prefs[Keys.GLOBAL_NOTIFY_MEETINGS] ?: true,
                globalMeetingReminderDays = prefs[Keys.GLOBAL_MEETING_REMINDER_DAYS] ?: 1,
                globalNotifyEvents = prefs[Keys.GLOBAL_NOTIFY_EVENTS] ?: true,
                globalEventReminderDays = prefs[Keys.GLOBAL_EVENT_REMINDER_DAYS] ?: 2,
                globalNotifyLongNoMeeting = prefs[Keys.GLOBAL_NOTIFY_LONG_NO_MEETING] ?: false,
                globalLongNoMeetingWeeks = prefs[Keys.GLOBAL_LONG_NO_MEETING_WEEKS] ?: 4,
                globalNotifyPostMeetingNote = prefs[Keys.GLOBAL_NOTIFY_POST_MEETING_NOTE] ?: true,
            )
            val next = transform(current)
            prefs[Keys.NOTIFICATIONS_ENABLED] = next.notificationsEnabled
            prefs[Keys.SHOW_BIRTHDAYS_ON_CALENDAR] = next.showBirthdaysOnCalendar
            prefs[Keys.DEFINED_FRIEND_TAGS] = JsonListCodec.encode(next.definedFriendTags)
            prefs[Keys.GLOBAL_NOTIFY_BIRTHDAY] = next.globalNotifyBirthday
            prefs[Keys.GLOBAL_BIRTHDAY_REMINDER_DAYS] = next.globalBirthdayReminderDays.coerceIn(1, 7)
            prefs[Keys.GLOBAL_NOTIFY_MEETINGS] = next.globalNotifyMeetings
            prefs[Keys.GLOBAL_MEETING_REMINDER_DAYS] = next.globalMeetingReminderDays.coerceIn(1, 7)
            prefs[Keys.GLOBAL_NOTIFY_EVENTS] = next.globalNotifyEvents
            prefs[Keys.GLOBAL_EVENT_REMINDER_DAYS] = next.globalEventReminderDays.coerceIn(1, 7)
            prefs[Keys.GLOBAL_NOTIFY_LONG_NO_MEETING] = next.globalNotifyLongNoMeeting
            prefs[Keys.GLOBAL_LONG_NO_MEETING_WEEKS] = next.globalLongNoMeetingWeeks.coerceIn(1, 26)
            prefs[Keys.GLOBAL_NOTIFY_POST_MEETING_NOTE] = next.globalNotifyPostMeetingNote
        }
    }

    private object Keys {
        val NOTIFICATIONS_ENABLED = booleanPreferencesKey("notificationsEnabled")
        val SHOW_BIRTHDAYS_ON_CALENDAR = booleanPreferencesKey("showBirthdaysOnCalendar")
        val DEFINED_FRIEND_TAGS = stringPreferencesKey("definedFriendTags")
        val GLOBAL_NOTIFY_BIRTHDAY = booleanPreferencesKey("globalNotifyBirthday")
        val GLOBAL_BIRTHDAY_REMINDER_DAYS = intPreferencesKey("globalBirthdayReminderDays")
        val GLOBAL_NOTIFY_MEETINGS = booleanPreferencesKey("globalNotifyMeetings")
        val GLOBAL_MEETING_REMINDER_DAYS = intPreferencesKey("globalMeetingReminderDays")
        val GLOBAL_NOTIFY_EVENTS = booleanPreferencesKey("globalNotifyEvents")
        val GLOBAL_EVENT_REMINDER_DAYS = intPreferencesKey("globalEventReminderDays")
        val GLOBAL_NOTIFY_LONG_NO_MEETING = booleanPreferencesKey("globalNotifyLongNoMeeting")
        val GLOBAL_LONG_NO_MEETING_WEEKS = intPreferencesKey("globalLongNoMeetingWeeks")
        val GLOBAL_NOTIFY_POST_MEETING_NOTE = booleanPreferencesKey("globalNotifyPostMeetingNote")
    }
}
