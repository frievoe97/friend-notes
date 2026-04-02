package com.example.friendnotes.data

import androidx.room.withTransaction
import com.example.friendnotes.data.local.AppDatabase
import com.example.friendnotes.data.local.FriendEntity
import com.example.friendnotes.data.local.FriendEntryEntity
import com.example.friendnotes.data.local.FriendMeetingCrossRef
import com.example.friendnotes.data.local.FriendWithRelations
import com.example.friendnotes.data.local.GiftIdeaEntity
import com.example.friendnotes.data.local.MeetingEntity
import com.example.friendnotes.data.local.MeetingWithFriends
import com.example.friendnotes.domain.model.Friend
import com.example.friendnotes.domain.model.FriendAggregate
import com.example.friendnotes.domain.model.FriendEntry
import com.example.friendnotes.domain.model.FriendEntryCategory
import com.example.friendnotes.domain.model.GiftIdea
import com.example.friendnotes.domain.model.Meeting
import com.example.friendnotes.domain.model.MeetingAggregate
import com.example.friendnotes.domain.model.MeetingKind
import com.example.friendnotes.util.JsonListCodec
import com.example.friendnotes.util.normalizeMeetingDateRange
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

class AppRepository(
    private val database: AppDatabase,
    private val settingsRepository: AppSettingsRepository,
) {
    private val friendDao = database.friendDao()
    private val meetingDao = database.meetingDao()
    private val giftIdeaDao = database.giftIdeaDao()
    private val friendEntryDao = database.friendEntryDao()

    val settingsFlow = settingsRepository.settingsFlow

    val friendsFlow: Flow<List<FriendAggregate>> =
        friendDao.observeFriendsWithRelations().map { list -> list.map(::mapFriendAggregate) }

    val meetingsFlow: Flow<List<MeetingAggregate>> =
        meetingDao.observeMeetingsWithFriends().map { list -> list.map(::mapMeetingAggregate) }

    fun observeFriend(friendId: Long): Flow<FriendAggregate?> =
        friendDao.observeFriendWithRelations(friendId).map { it?.let(::mapFriendAggregate) }

    fun observeMeeting(meetingId: Long): Flow<MeetingAggregate?> =
        meetingDao.observeMeetingWithFriends(meetingId).map { it?.let(::mapMeetingAggregate) }

    suspend fun createFriend(
        firstName: String,
        lastName: String,
        nickname: String,
        birthday: LocalDate?,
        tags: List<String>,
        isFavorite: Boolean,
        entriesByCategory: Map<FriendEntryCategory, List<Pair<String, String>>>,
    ): Long {
        val now = Instant.now().toEpochMilli()
        val friendId = friendDao.insert(
            FriendEntity(
                firstName = firstName.trim(),
                lastName = lastName.trim(),
                nickname = nickname.trim(),
                tagsRaw = JsonListCodec.encode(JsonListCodec.normalizedUnique(tags)),
                birthdayEpochDay = birthday?.toEpochDay(),
                createdAtEpochMillis = now,
                isFavorite = isFavorite,
            )
        )
        entriesByCategory.forEach { (category, entries) ->
            entries
                .map { it.first.trim() to it.second.trim() }
                .filter { it.first.isNotEmpty() }
                .forEachIndexed { index, pair ->
                    friendEntryDao.insert(
                        FriendEntryEntity(
                            friendId = friendId,
                            title = pair.first,
                            note = pair.second,
                            category = category.raw,
                            `order` = index,
                            createdAtEpochMillis = now + index,
                        )
                    )
                }
        }
        return friendId
    }

    suspend fun updateFriend(
        friendId: Long,
        firstName: String,
        lastName: String,
        nickname: String,
        birthday: LocalDate?,
        tags: List<String>,
        isFavorite: Boolean,
    ) {
        val current = friendDao.getById(friendId) ?: return
        friendDao.update(
            current.copy(
                firstName = firstName.trim(),
                lastName = lastName.trim(),
                nickname = nickname.trim(),
                birthdayEpochDay = birthday?.toEpochDay(),
                tagsRaw = JsonListCodec.encode(JsonListCodec.normalizedUnique(tags)),
                isFavorite = isFavorite,
            )
        )
    }

    suspend fun deleteFriend(friendId: Long) {
        database.withTransaction {
            val friend = friendDao.getById(friendId) ?: return@withTransaction
            meetingDao.deleteCrossRefsForFriend(friendId)
            friendDao.delete(friend)
            meetingDao.deleteOrphanMeetings()
        }
    }

    suspend fun upsertGift(
        friendId: Long,
        giftId: Long?,
        title: String,
        note: String,
        isGifted: Boolean,
    ) {
        val now = Instant.now().toEpochMilli()
        if (giftId == null) {
            giftIdeaDao.insert(
                GiftIdeaEntity(
                    friendId = friendId,
                    title = title.trim(),
                    note = note.trim(),
                    isGifted = isGifted,
                    createdAtEpochMillis = now,
                )
            )
            return
        }
        val current = giftIdeaDao.getById(giftId) ?: return
        giftIdeaDao.update(
            current.copy(
                title = title.trim(),
                note = note.trim(),
                isGifted = isGifted,
            )
        )
    }

    suspend fun deleteGift(giftId: Long) {
        val current = giftIdeaDao.getById(giftId) ?: return
        giftIdeaDao.delete(current)
    }

    suspend fun toggleGifted(giftId: Long, isGifted: Boolean) {
        val current = giftIdeaDao.getById(giftId) ?: return
        giftIdeaDao.update(current.copy(isGifted = isGifted))
    }

    suspend fun upsertEntry(
        friendId: Long,
        entryId: Long?,
        category: FriendEntryCategory,
        title: String,
        note: String,
    ) {
        val now = Instant.now().toEpochMilli()
        if (entryId == null) {
            val nextOrder = friendEntryDao.maxOrder(friendId, category.raw) + 1
            friendEntryDao.insert(
                FriendEntryEntity(
                    friendId = friendId,
                    title = title.trim(),
                    note = note.trim(),
                    category = category.raw,
                    `order` = nextOrder,
                    createdAtEpochMillis = now,
                )
            )
            return
        }
        val current = friendEntryDao.getById(entryId) ?: return
        friendEntryDao.update(
            current.copy(
                title = title.trim(),
                note = note.trim(),
            )
        )
    }

    suspend fun deleteEntry(entryId: Long) {
        val current = friendEntryDao.getById(entryId) ?: return
        friendEntryDao.delete(current)
    }

    suspend fun upsertMeeting(
        meetingId: Long?,
        kind: MeetingKind,
        eventTitle: String,
        startDate: ZonedDateTime,
        endDate: ZonedDateTime,
        note: String,
        friendIds: List<Long>,
    ): Long {
        val uniqueFriendIds = friendIds.distinct()
        val (normalizedStart, normalizedEnd) = normalizeMeetingDateRange(kind.raw, startDate, endDate)
        val normalizedTitle = if (kind == MeetingKind.EVENT) eventTitle.trim() else ""

        return database.withTransaction {
            val id = if (meetingId == null) {
                meetingDao.insert(
                    MeetingEntity(
                        eventTitle = normalizedTitle,
                        startDateEpochMillis = normalizedStart.toInstant().toEpochMilli(),
                        endDateEpochMillis = normalizedEnd.toInstant().toEpochMilli(),
                        note = note.trim(),
                        kindRaw = kind.raw,
                    )
                )
            } else {
                val current = meetingDao.getById(meetingId) ?: return@withTransaction meetingId
                meetingDao.update(
                    current.copy(
                        eventTitle = normalizedTitle,
                        startDateEpochMillis = normalizedStart.toInstant().toEpochMilli(),
                        endDateEpochMillis = normalizedEnd.toInstant().toEpochMilli(),
                        note = note.trim(),
                        kindRaw = kind.raw,
                    )
                )
                meetingId
            }
            meetingDao.deleteCrossRefsForMeeting(id)
            if (uniqueFriendIds.isNotEmpty()) {
                meetingDao.insertCrossRefs(uniqueFriendIds.map { FriendMeetingCrossRef(friendId = it, meetingId = id) })
            }
            if (uniqueFriendIds.isEmpty()) {
                val meeting = meetingDao.getById(id)
                if (meeting != null) {
                    meetingDao.delete(meeting)
                }
            }
            id
        }
    }

    suspend fun deleteMeeting(meetingId: Long) {
        database.withTransaction {
            val meeting = meetingDao.getById(meetingId) ?: return@withTransaction
            meetingDao.deleteCrossRefsForMeeting(meetingId)
            meetingDao.delete(meeting)
        }
    }

    suspend fun addGlobalTag(tag: String) {
        settingsRepository.update { settings ->
            val nextTags = JsonListCodec.normalizedUnique(settings.definedFriendTags + tag)
            settings.copy(definedFriendTags = nextTags)
        }
    }

    suspend fun removeGlobalTag(tag: String) {
        val targetLower = tag.trim().lowercase()
        if (targetLower.isBlank()) return

        settingsRepository.update { settings ->
            settings.copy(
                definedFriendTags = settings.definedFriendTags.filterNot { it.trim().lowercase() == targetLower }
            )
        }

        database.withTransaction {
            friendDao.getAllFriends().forEach { entity ->
                val updatedTags = JsonListCodec.decode(entity.tagsRaw)
                    .filterNot { it.trim().lowercase() == targetLower }
                friendDao.updateTags(entity.id, JsonListCodec.encode(updatedTags))
            }
        }
    }

    suspend fun updateSettings(transform: (com.example.friendnotes.domain.model.AppSettings) -> com.example.friendnotes.domain.model.AppSettings) {
        settingsRepository.update(transform)
    }

    private fun mapFriendAggregate(item: FriendWithRelations): FriendAggregate {
        val friend = item.friend.toDomain()
        val friendMeetings = item.meetings.map {
            it.toDomain(friendIds = listOf(friend.id))
        }
        val entries = item.entries.map { it.toDomain() }
        val gifts = item.giftIdeas.map { it.toDomain() }
        return FriendAggregate(
            friend = friend,
            meetings = friendMeetings,
            giftIdeas = gifts,
            entries = entries,
        )
    }

    private fun mapMeetingAggregate(item: MeetingWithFriends): MeetingAggregate {
        val friends = item.friends.map { it.toDomain() }
        return MeetingAggregate(
            meeting = item.meeting.toDomain(friendIds = friends.map { it.id }),
            friends = friends,
        )
    }

    private fun FriendEntity.toDomain(): Friend {
        return Friend(
            id = id,
            firstName = firstName,
            lastName = lastName,
            nickname = nickname,
            tags = JsonListCodec.decode(tagsRaw),
            birthday = birthdayEpochDay?.let(LocalDate::ofEpochDay),
            createdAt = Instant.ofEpochMilli(createdAtEpochMillis),
            isFavorite = isFavorite,
        )
    }

    private fun MeetingEntity.toDomain(friendIds: List<Long>): Meeting {
        val zone = ZoneId.systemDefault()
        return Meeting(
            id = id,
            eventTitle = eventTitle,
            startDate = Instant.ofEpochMilli(startDateEpochMillis).atZone(zone),
            endDate = Instant.ofEpochMilli(endDateEpochMillis).atZone(zone),
            note = note,
            kind = MeetingKind.fromRaw(kindRaw),
            friendIds = friendIds,
        )
    }

    private fun GiftIdeaEntity.toDomain(): GiftIdea {
        return GiftIdea(
            id = id,
            friendId = friendId,
            title = title,
            note = note,
            isGifted = isGifted,
            createdAt = Instant.ofEpochMilli(createdAtEpochMillis),
        )
    }

    private fun FriendEntryEntity.toDomain(): FriendEntry {
        return FriendEntry(
            id = id,
            friendId = friendId,
            title = title,
            note = note,
            category = FriendEntryCategory.fromRaw(category),
            order = `order`,
            createdAt = Instant.ofEpochMilli(createdAtEpochMillis),
        )
    }
}
