package com.example.friendnotes.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.friendnotes.app.AppContainer
import com.example.friendnotes.domain.model.AppSettings
import com.example.friendnotes.domain.model.Friend
import com.example.friendnotes.domain.model.FriendAggregate
import com.example.friendnotes.domain.model.FriendEntryCategory
import com.example.friendnotes.domain.model.FriendSortMode
import com.example.friendnotes.domain.model.MeetingKind
import com.example.friendnotes.domain.usecase.FriendSearchSortUseCase
import com.example.friendnotes.util.JsonListCodec
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZonedDateTime

@OptIn(FlowPreview::class)
class FriendNotesViewModel(application: Application) : AndroidViewModel(application) {
    private val container = AppContainer(application)
    private val repository = container.repository
    private val friendSearchSort = container.friendSearchSortUseCase
    private val reminderScheduler = container.reminderScheduler

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery

    private val _sortMode = MutableStateFlow(FriendSortMode.NAME_ASC)
    val sortMode: StateFlow<FriendSortMode> = _sortMode

    val friends = repository.friendsFlow.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = emptyList(),
    )

    val meetings = repository.meetingsFlow.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = emptyList(),
    )

    val settings = repository.settingsFlow.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = AppSettings(),
    )

    val sortedFilteredFriends = combine(friends, searchQuery, sortMode) { allFriends, query, mode ->
        friendSearchSort(allFriends, query, mode, ZonedDateTime.now())
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = emptyList(),
    )

    init {
        viewModelScope.launch {
            combine(settings, friends, meetings) { currentSettings, currentFriends, currentMeetings ->
                Triple(currentSettings, currentFriends, currentMeetings)
            }
                .debounce(250)
                .collect { (currentSettings, currentFriends, currentMeetings) ->
                    reminderScheduler.reschedule(currentSettings, currentFriends, currentMeetings)
                }
        }
    }

    fun setSearchQuery(value: String) {
        _searchQuery.value = value
    }

    fun setSortMode(mode: FriendSortMode) {
        _sortMode.value = mode
    }

    suspend fun createFriend(
        firstName: String,
        lastName: String,
        nickname: String,
        birthday: LocalDate?,
        tags: List<String>,
        isFavorite: Boolean,
        entriesByCategory: Map<FriendEntryCategory, List<Pair<String, String>>>,
    ): Boolean {
        if (firstName.isBlank() && lastName.isBlank()) return false
        repository.createFriend(
            firstName = firstName,
            lastName = lastName,
            nickname = nickname,
            birthday = birthday,
            tags = tags,
            isFavorite = isFavorite,
            entriesByCategory = entriesByCategory,
        )
        return true
    }

    suspend fun updateFriend(
        friendId: Long,
        firstName: String,
        lastName: String,
        nickname: String,
        birthday: LocalDate?,
        tags: List<String>,
        isFavorite: Boolean,
    ): Boolean {
        if (firstName.isBlank() && lastName.isBlank()) return false
        repository.updateFriend(
            friendId = friendId,
            firstName = firstName,
            lastName = lastName,
            nickname = nickname,
            birthday = birthday,
            tags = tags,
            isFavorite = isFavorite,
        )
        return true
    }

    suspend fun deleteFriend(friendId: Long) {
        repository.deleteFriend(friendId)
    }

    suspend fun upsertEntry(
        friendId: Long,
        entryId: Long?,
        category: FriendEntryCategory,
        title: String,
        note: String,
    ): Boolean {
        if (title.isBlank()) return false
        repository.upsertEntry(friendId, entryId, category, title, note)
        return true
    }

    suspend fun deleteEntry(entryId: Long) {
        repository.deleteEntry(entryId)
    }

    suspend fun upsertGift(
        friendId: Long,
        giftId: Long?,
        title: String,
        note: String,
        isGifted: Boolean,
    ): Boolean {
        if (title.isBlank()) return false
        repository.upsertGift(friendId, giftId, title, note, isGifted)
        return true
    }

    suspend fun toggleGifted(giftId: Long, isGifted: Boolean) {
        repository.toggleGifted(giftId, isGifted)
    }

    suspend fun deleteGift(giftId: Long) {
        repository.deleteGift(giftId)
    }

    suspend fun upsertMeeting(
        meetingId: Long?,
        kind: MeetingKind,
        eventTitle: String,
        startDate: ZonedDateTime,
        endDate: ZonedDateTime,
        note: String,
        friendIds: List<Long>,
    ): MeetingValidation {
        if (kind == MeetingKind.MEETING && friendIds.isEmpty()) {
            return MeetingValidation.InvalidMissingFriends
        }
        if (kind == MeetingKind.EVENT && eventTitle.isBlank()) {
            return MeetingValidation.InvalidEventTitle
        }
        if (kind == MeetingKind.EVENT && friendIds.isEmpty()) {
            return MeetingValidation.InvalidMissingFriends
        }
        if (kind == MeetingKind.MEETING && endDate.isBefore(startDate)) {
            return MeetingValidation.InvalidDateRange
        }

        repository.upsertMeeting(
            meetingId = meetingId,
            kind = kind,
            eventTitle = eventTitle,
            startDate = startDate,
            endDate = if (kind == MeetingKind.EVENT) startDate else endDate,
            note = note,
            friendIds = friendIds,
        )
        return MeetingValidation.Ok
    }

    suspend fun deleteMeeting(meetingId: Long) {
        repository.deleteMeeting(meetingId)
    }

    suspend fun updateSettings(transform: (AppSettings) -> AppSettings) {
        repository.updateSettings(transform)
    }

    suspend fun addGlobalTag(tag: String): TagResult {
        val normalized = tag.trim()
        if (normalized.isBlank()) return TagResult.Invalid
        val existing = settings.value.definedFriendTags
        if (existing.any { it.trim().equals(normalized, ignoreCase = true) }) {
            return TagResult.Duplicate
        }
        repository.addGlobalTag(normalized)
        return TagResult.Added
    }

    suspend fun removeGlobalTag(tag: String) {
        repository.removeGlobalTag(tag)
    }

    fun displayName(friend: Friend): String {
        val nickname = friend.nickname.trim()
        if (nickname.isNotEmpty()) return nickname
        val fullName = "${friend.firstName} ${friend.lastName}".trim()
        return if (fullName.isNotEmpty()) fullName else ""
    }

    fun initials(friend: Friend): String {
        val name = displayName(friend)
        if (name.isBlank()) return "?"
        val chunks = name.split(" ").filter { it.isNotBlank() }
        if (chunks.isEmpty()) return "?"
        return chunks.take(2).joinToString("") { it.first().uppercase() }
    }

    fun lastSeenLabel(friend: FriendAggregate): FriendSearchSortUseCase.LastSeenLabel {
        return friendSearchSort.lastSeenLabelKey(friend, ZonedDateTime.now())
    }

    fun normalizedTags(tags: List<String>): List<String> = JsonListCodec.normalizedUnique(tags)

    sealed class MeetingValidation {
        data object Ok : MeetingValidation()
        data object InvalidMissingFriends : MeetingValidation()
        data object InvalidEventTitle : MeetingValidation()
        data object InvalidDateRange : MeetingValidation()
    }

    enum class TagResult {
        Added,
        Duplicate,
        Invalid,
    }
}
