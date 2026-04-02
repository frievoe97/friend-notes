package com.example.friendnotes.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface FriendDao {
    @Transaction
    @Query("SELECT * FROM friends")
    fun observeFriendsWithRelations(): Flow<List<FriendWithRelations>>

    @Transaction
    @Query("SELECT * FROM friends WHERE id = :friendId")
    fun observeFriendWithRelations(friendId: Long): Flow<FriendWithRelations?>

    @Query("SELECT * FROM friends")
    suspend fun getAllFriends(): List<FriendEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(friend: FriendEntity): Long

    @Update
    suspend fun update(friend: FriendEntity): Int

    @Delete
    suspend fun delete(friend: FriendEntity): Int

    @Query("SELECT * FROM friends WHERE id = :friendId")
    suspend fun getById(friendId: Long): FriendEntity?

    @Query("UPDATE friends SET tagsRaw = :tagsRaw WHERE id = :friendId")
    suspend fun updateTags(friendId: Long, tagsRaw: String): Int
}

@Dao
interface MeetingDao {
    @Transaction
    @Query("SELECT * FROM meetings")
    fun observeMeetingsWithFriends(): Flow<List<MeetingWithFriends>>

    @Transaction
    @Query("SELECT * FROM meetings WHERE id = :meetingId")
    fun observeMeetingWithFriends(meetingId: Long): Flow<MeetingWithFriends?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(meeting: MeetingEntity): Long

    @Update
    suspend fun update(meeting: MeetingEntity): Int

    @Delete
    suspend fun delete(meeting: MeetingEntity): Int

    @Query("SELECT * FROM meetings WHERE id = :meetingId")
    suspend fun getById(meetingId: Long): MeetingEntity?

    @Query("DELETE FROM friend_meeting WHERE meetingId = :meetingId")
    suspend fun deleteCrossRefsForMeeting(meetingId: Long): Int

    @Query("DELETE FROM friend_meeting WHERE friendId = :friendId")
    suspend fun deleteCrossRefsForFriend(friendId: Long): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCrossRefs(crossRefs: List<FriendMeetingCrossRef>)

    @Query("SELECT meetingId FROM friend_meeting WHERE friendId = :friendId")
    suspend fun getMeetingIdsForFriend(friendId: Long): List<Long>

    @Query("SELECT COUNT(*) FROM friend_meeting WHERE meetingId = :meetingId")
    suspend fun countParticipants(meetingId: Long): Int

    @Query(
        """
        DELETE FROM meetings
        WHERE id IN (
            SELECT m.id
            FROM meetings m
            LEFT JOIN friend_meeting fm ON m.id = fm.meetingId
            GROUP BY m.id
            HAVING COUNT(fm.friendId) = 0
        )
        """
    )
    suspend fun deleteOrphanMeetings(): Int

    @Query("SELECT * FROM meetings")
    suspend fun getAllMeetings(): List<MeetingEntity>

    @Query("SELECT friendId FROM friend_meeting WHERE meetingId = :meetingId")
    suspend fun getFriendIdsForMeeting(meetingId: Long): List<Long>
}

@Dao
interface GiftIdeaDao {
    @Query("SELECT * FROM gift_ideas WHERE friendId = :friendId ORDER BY isGifted ASC, createdAtEpochMillis DESC")
    fun observeByFriend(friendId: Long): Flow<List<GiftIdeaEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(giftIdea: GiftIdeaEntity): Long

    @Update
    suspend fun update(giftIdea: GiftIdeaEntity): Int

    @Delete
    suspend fun delete(giftIdea: GiftIdeaEntity): Int

    @Query("SELECT * FROM gift_ideas WHERE id = :giftId")
    suspend fun getById(giftId: Long): GiftIdeaEntity?
}

@Dao
interface FriendEntryDao {
    @Query(
        """
        SELECT * FROM friend_entries
        WHERE friendId = :friendId AND category = :category
        ORDER BY `order` ASC, createdAtEpochMillis ASC
        """
    )
    fun observeByFriendAndCategory(friendId: Long, category: String): Flow<List<FriendEntryEntity>>

    @Query(
        """
        SELECT COALESCE(MAX(`order`), -1)
        FROM friend_entries
        WHERE friendId = :friendId AND category = :category
        """
    )
    suspend fun maxOrder(friendId: Long, category: String): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entry: FriendEntryEntity): Long

    @Update
    suspend fun update(entry: FriendEntryEntity): Int

    @Delete
    suspend fun delete(entry: FriendEntryEntity): Int

    @Query("SELECT * FROM friend_entries WHERE id = :entryId")
    suspend fun getById(entryId: Long): FriendEntryEntity?
}
