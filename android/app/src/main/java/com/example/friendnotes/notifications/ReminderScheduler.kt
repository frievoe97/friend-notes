package com.example.friendnotes.notifications

import android.content.Context
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.friendnotes.R
import com.example.friendnotes.domain.model.AppSettings
import com.example.friendnotes.domain.model.FriendAggregate
import com.example.friendnotes.domain.model.MeetingAggregate
import com.example.friendnotes.domain.model.MeetingKind
import java.time.Duration
import java.time.LocalTime
import java.time.ZonedDateTime
import java.time.temporal.WeekFields
import java.util.Locale
import java.util.concurrent.TimeUnit

class ReminderScheduler(private val context: Context) {
    private val workManager = WorkManager.getInstance(context)

    fun reschedule(
        settings: AppSettings,
        friends: List<FriendAggregate>,
        meetings: List<MeetingAggregate>,
        now: ZonedDateTime = ZonedDateTime.now(),
    ) {
        workManager.cancelAllWorkByTag(TAG_PREFIX)

        if (!settings.notificationsEnabled) return
        if (!ReminderWorker.canPostNotifications(context)) return

        scheduleBirthdays(settings, friends, now)
        scheduleMeetingAndEventReminders(settings, meetings, now)
        schedulePostMeetingNotes(settings, meetings, now)
        scheduleLongNoMeeting(settings, friends, meetings, now)
    }

    private fun scheduleBirthdays(
        settings: AppSettings,
        friends: List<FriendAggregate>,
        now: ZonedDateTime,
    ) {
        if (!settings.globalNotifyBirthday) return

        friends.forEach { aggregate ->
            val friend = aggregate.friend
            val birthday = friend.birthday ?: return@forEach

            var nextBirthday = birthday.withYear(now.year)
            if (nextBirthday.atTime(NINE_AM).atZone(now.zone).isBefore(now) ||
                nextBirthday.atTime(NINE_AM).atZone(now.zone).isEqual(now)
            ) {
                nextBirthday = nextBirthday.plusYears(1)
            }

            val remindAt = nextBirthday
                .minusDays(settings.globalBirthdayReminderDays.toLong())
                .atTime(NINE_AM)
                .atZone(now.zone)

            if (!remindAt.isAfter(now)) return@forEach

            val title = context.getString(R.string.notification_birthday_title)
            val body = context.getString(R.string.notification_birthday_body, displayName(friend))
            enqueue(
                uniqueName = "${ID_PREFIX}birthday.${friend.id}",
                triggerAt = remindAt,
                title = title,
                body = body,
            )
        }
    }

    private fun scheduleMeetingAndEventReminders(
        settings: AppSettings,
        meetings: List<MeetingAggregate>,
        now: ZonedDateTime,
    ) {
        meetings.forEach { aggregate ->
            val meeting = aggregate.meeting
            when (meeting.kind) {
                MeetingKind.MEETING -> {
                    if (!settings.globalNotifyMeetings) return@forEach
                    val remindAt = meeting.startDate
                        .minusDays(settings.globalMeetingReminderDays.toLong())
                        .with(NINE_AM)
                    if (!remindAt.isAfter(now)) return@forEach
                    enqueue(
                        uniqueName = "${ID_PREFIX}meeting.${meeting.id}",
                        triggerAt = remindAt,
                        title = context.getString(R.string.notification_meeting_title),
                        body = context.getString(
                            R.string.notification_meeting_body,
                            aggregate.friends.joinToString(", ") { displayName(it) },
                        ),
                    )
                }

                MeetingKind.EVENT -> {
                    if (!settings.globalNotifyEvents) return@forEach
                    val remindAt = meeting.startDate
                        .minusDays(settings.globalEventReminderDays.toLong())
                        .with(NINE_AM)
                    if (!remindAt.isAfter(now)) return@forEach
                    enqueue(
                        uniqueName = "${ID_PREFIX}event.${meeting.id}",
                        triggerAt = remindAt,
                        title = context.getString(R.string.notification_event_title),
                        body = context.getString(
                            R.string.notification_event_body,
                            meeting.eventTitle.ifBlank {
                                aggregate.friends.joinToString(", ") { displayName(it) }
                            },
                        ),
                    )
                }
            }
        }
    }

    private fun schedulePostMeetingNotes(
        settings: AppSettings,
        meetings: List<MeetingAggregate>,
        now: ZonedDateTime,
    ) {
        if (!settings.globalNotifyPostMeetingNote) return

        meetings
            .filter { it.meeting.kind == MeetingKind.MEETING }
            .forEach { aggregate ->
                val remindAt = aggregate.meeting.endDate
                    .toLocalDate()
                    .atTime(NINE_AM)
                    .atZone(now.zone)

                if (!remindAt.isAfter(now)) return@forEach

                enqueue(
                    uniqueName = "${ID_PREFIX}postnote.${aggregate.meeting.id}",
                    triggerAt = remindAt,
                    title = context.getString(R.string.notification_post_meeting_title),
                    body = context.getString(
                        R.string.notification_post_meeting_body,
                        aggregate.friends.joinToString(", ") { displayName(it) },
                    ),
                )
            }
    }

    private fun scheduleLongNoMeeting(
        settings: AppSettings,
        friends: List<FriendAggregate>,
        meetings: List<MeetingAggregate>,
        now: ZonedDateTime,
    ) {
        if (!settings.globalNotifyLongNoMeeting) return

        friends.forEach { aggregate ->
            val friend = aggregate.friend
            val lastMeetingEnd = meetings
                .filter { it.meeting.kind == MeetingKind.MEETING && it.meeting.friendIds.contains(friend.id) }
                .maxByOrNull { it.meeting.endDate }
                ?.meeting
                ?.endDate

            val base = lastMeetingEnd ?: friend.createdAt.atZone(now.zone)
            val remindAt = base
                .plusWeeks(settings.globalLongNoMeetingWeeks.toLong())
                .with(NINE_AM)

            if (!remindAt.isAfter(now)) return@forEach

            enqueue(
                uniqueName = "${ID_PREFIX}longnomeeting.${friend.id}",
                triggerAt = remindAt,
                title = context.getString(R.string.notification_long_no_meeting_title),
                body = context.getString(R.string.notification_long_no_meeting_body, displayName(friend)),
            )
        }
    }

    fun weekOfYear(date: ZonedDateTime): Int {
        return date.get(WeekFields.of(Locale.getDefault()).weekOfWeekBasedYear())
    }

    private fun enqueue(
        uniqueName: String,
        triggerAt: ZonedDateTime,
        title: String,
        body: String,
    ) {
        val delayMillis = Duration.between(ZonedDateTime.now(), triggerAt).toMillis()
        if (delayMillis <= 0L) return

        val data = Data.Builder()
            .putString(ReminderWorker.KEY_TITLE, title)
            .putString(ReminderWorker.KEY_BODY, body)
            .putInt(ReminderWorker.KEY_NOTIFICATION_ID, uniqueName.hashCode())
            .build()

        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag(TAG_PREFIX)
            .addTag(uniqueName)
            .build()

        workManager.enqueueUniqueWork(uniqueName, ExistingWorkPolicy.REPLACE, request)
    }

    private fun displayName(friend: com.example.friendnotes.domain.model.Friend): String {
        val nickname = friend.nickname.trim()
        if (nickname.isNotEmpty()) return nickname
        val fullName = "${friend.firstName} ${friend.lastName}".trim()
        return if (fullName.isNotEmpty()) fullName else context.getString(R.string.friends_unnamed)
    }

    companion object {
        private val NINE_AM = LocalTime.of(9, 0)
        private const val TAG_PREFIX = "friendsapp.android"
        private const val ID_PREFIX = "friendsapp.android."
    }
}
