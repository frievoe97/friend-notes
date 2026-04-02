package com.example.friendnotes.domain.usecase

import com.example.friendnotes.domain.model.FriendAggregate
import com.example.friendnotes.domain.model.FriendSortMode
import com.example.friendnotes.domain.model.MeetingKind
import java.time.Duration
import java.time.ZonedDateTime

class FriendSearchSortUseCase {
    operator fun invoke(
        friends: List<FriendAggregate>,
        query: String,
        sortMode: FriendSortMode,
        now: ZonedDateTime = ZonedDateTime.now(),
    ): List<FriendAggregate> {
        val normalizedQuery = query.trim().lowercase()
        val filtered = if (normalizedQuery.isBlank()) {
            friends
        } else {
            friends.filter { aggregate ->
                val friend = aggregate.friend
                val values = buildList {
                    add(friend.firstName)
                    add(friend.lastName)
                    add(friend.nickname)
                    addAll(friend.tags)
                    addAll(aggregate.entries.map { it.title })
                    addAll(aggregate.entries.map { it.note })
                }
                values.any { it.lowercase().contains(normalizedQuery) }
            }
        }

        val comparator = when (sortMode) {
            FriendSortMode.NAME_ASC -> compareBy<FriendAggregate> { it.friendDisplayName().lowercase() }
            FriendSortMode.NAME_DESC -> compareByDescending<FriendAggregate> { it.friendDisplayName().lowercase() }
            FriendSortMode.LAST_SEEN_ASC -> compareBy<FriendAggregate> { lastSeenDate(it, now) ?: ZonedDateTime.ofInstant(it.friend.createdAt, now.zone) }
            FriendSortMode.LAST_SEEN_DESC -> compareByDescending<FriendAggregate> { lastSeenDate(it, now) ?: ZonedDateTime.ofInstant(it.friend.createdAt, now.zone) }
            FriendSortMode.NEXT_MEETING -> compareBy<FriendAggregate> { nextDateByKind(it, MeetingKind.MEETING, now) ?: ZonedDateTime.ofInstant(it.friend.createdAt, now.zone).plusYears(100) }
            FriendSortMode.NEXT_EVENT -> compareBy<FriendAggregate> { nextDateByKind(it, MeetingKind.EVENT, now) ?: ZonedDateTime.ofInstant(it.friend.createdAt, now.zone).plusYears(100) }
        }

        return filtered
            .sortedWith(comparator.thenBy { it.friendDisplayName().lowercase() })
            .sortedByDescending { it.friend.isFavorite }
    }

    fun lastSeenLabelKey(friend: FriendAggregate, now: ZonedDateTime): LastSeenLabel {
        val lastSeen = lastSeenDate(friend, now) ?: return LastSeenLabel.Never
        val days = Duration.between(lastSeen.toLocalDate().atStartOfDay(now.zone), now.toLocalDate().atStartOfDay(now.zone)).toDays().toInt()
        return when {
            days <= 0 -> LastSeenLabel.Today
            days < 7 -> LastSeenLabel.Days(days)
            days < 30 -> LastSeenLabel.Weeks(days / 7)
            days < 365 -> LastSeenLabel.Months(days / 30)
            else -> LastSeenLabel.Years(days / 365)
        }
    }

    private fun friendDisplayName(friend: FriendAggregate): String {
        val nick = friend.friend.nickname.trim()
        if (nick.isNotEmpty()) return nick
        val full = "${friend.friend.firstName} ${friend.friend.lastName}".trim()
        if (full.isNotEmpty()) return full
        return ""
    }

    private fun lastSeenDate(friend: FriendAggregate, now: ZonedDateTime): ZonedDateTime? {
        return friend.meetings
            .filter { it.endDate.isBefore(now) || it.endDate.isEqual(now) }
            .maxByOrNull { it.endDate }
            ?.endDate
    }

    private fun nextDateByKind(friend: FriendAggregate, kind: MeetingKind, now: ZonedDateTime): ZonedDateTime? {
        return friend.meetings
            .filter { it.kind == kind }
            .map { it.startDate }
            .filter { it.isAfter(now) }
            .minOrNull()
    }

    sealed class LastSeenLabel {
        data object Today : LastSeenLabel()
        data class Days(val value: Int) : LastSeenLabel()
        data class Weeks(val value: Int) : LastSeenLabel()
        data class Months(val value: Int) : LastSeenLabel()
        data class Years(val value: Int) : LastSeenLabel()
        data object Never : LastSeenLabel()
    }
}

private fun FriendAggregate.friendDisplayName(): String {
    val nick = friend.nickname.trim()
    if (nick.isNotEmpty()) return nick
    val full = "${friend.firstName} ${friend.lastName}".trim()
    return full
}
