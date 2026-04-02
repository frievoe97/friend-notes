package com.example.friendnotes.domain.model

import java.time.Instant
import java.time.LocalDate
import java.time.ZonedDateTime

enum class MeetingKind(val raw: String) {
    MEETING("meeting"),
    EVENT("event");

    companion object {
        fun fromRaw(raw: String): MeetingKind = entries.firstOrNull { it.raw == raw } ?: MEETING
    }
}

enum class FriendEntryCategory(val raw: String) {
    HOBBIES("hobbies"),
    FOODS("foods"),
    MUSICS("musics"),
    MOVIES_SERIES("moviesSeries"),
    NOTES("notes");

    companion object {
        fun fromRaw(raw: String): FriendEntryCategory = entries.firstOrNull { it.raw == raw } ?: NOTES
    }
}

enum class FriendSortMode {
    NAME_ASC,
    NAME_DESC,
    LAST_SEEN_ASC,
    LAST_SEEN_DESC,
    NEXT_MEETING,
    NEXT_EVENT,
}

data class FriendEntry(
    val id: Long,
    val friendId: Long?,
    val title: String,
    val note: String,
    val category: FriendEntryCategory,
    val order: Int,
    val createdAt: Instant,
)

data class GiftIdea(
    val id: Long,
    val friendId: Long?,
    val title: String,
    val note: String,
    val isGifted: Boolean,
    val createdAt: Instant,
)

data class Friend(
    val id: Long,
    val firstName: String,
    val lastName: String,
    val nickname: String,
    val tags: List<String>,
    val birthday: LocalDate?,
    val createdAt: Instant,
    val isFavorite: Boolean,
)

data class Meeting(
    val id: Long,
    val eventTitle: String,
    val startDate: ZonedDateTime,
    val endDate: ZonedDateTime,
    val note: String,
    val kind: MeetingKind,
    val friendIds: List<Long>,
)

data class FriendAggregate(
    val friend: Friend,
    val meetings: List<Meeting>,
    val giftIdeas: List<GiftIdea>,
    val entries: List<FriendEntry>,
)

data class MeetingAggregate(
    val meeting: Meeting,
    val friends: List<Friend>,
)

data class AppSettings(
    val notificationsEnabled: Boolean = true,
    val showBirthdaysOnCalendar: Boolean = true,
    val definedFriendTags: List<String> = emptyList(),
    val globalNotifyBirthday: Boolean = true,
    val globalBirthdayReminderDays: Int = 3,
    val globalNotifyMeetings: Boolean = true,
    val globalMeetingReminderDays: Int = 1,
    val globalNotifyEvents: Boolean = true,
    val globalEventReminderDays: Int = 2,
    val globalNotifyLongNoMeeting: Boolean = false,
    val globalLongNoMeetingWeeks: Int = 4,
    val globalNotifyPostMeetingNote: Boolean = true,
)
