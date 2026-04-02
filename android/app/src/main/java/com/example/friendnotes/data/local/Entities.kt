package com.example.friendnotes.data.local

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Junction
import androidx.room.PrimaryKey
import androidx.room.Relation

@Entity(tableName = "friends")
data class FriendEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val firstName: String,
    val lastName: String,
    val nickname: String,
    val tagsRaw: String,
    val birthdayEpochDay: Long?,
    val createdAtEpochMillis: Long,
    val isFavorite: Boolean,
)

@Entity(tableName = "meetings", indices = [Index("kindRaw"), Index("startDateEpochMillis")])
data class MeetingEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val eventTitle: String,
    val startDateEpochMillis: Long,
    val endDateEpochMillis: Long,
    val note: String,
    val kindRaw: String,
)

@Entity(
    tableName = "gift_ideas",
    foreignKeys = [
        ForeignKey(
            entity = FriendEntity::class,
            parentColumns = ["id"],
            childColumns = ["friendId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("friendId")],
)
data class GiftIdeaEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val friendId: Long?,
    val title: String,
    val note: String,
    val isGifted: Boolean,
    val createdAtEpochMillis: Long,
)

@Entity(
    tableName = "friend_entries",
    foreignKeys = [
        ForeignKey(
            entity = FriendEntity::class,
            parentColumns = ["id"],
            childColumns = ["friendId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("friendId"), Index("category")],
)
data class FriendEntryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val friendId: Long?,
    val title: String,
    val note: String,
    val category: String,
    val `order`: Int,
    val createdAtEpochMillis: Long,
)

@Entity(
    tableName = "friend_meeting",
    primaryKeys = ["friendId", "meetingId"],
    foreignKeys = [
        ForeignKey(
            entity = FriendEntity::class,
            parentColumns = ["id"],
            childColumns = ["friendId"],
            onDelete = ForeignKey.CASCADE,
        ),
        ForeignKey(
            entity = MeetingEntity::class,
            parentColumns = ["id"],
            childColumns = ["meetingId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("meetingId")],
)
data class FriendMeetingCrossRef(
    val friendId: Long,
    val meetingId: Long,
)

data class FriendWithRelations(
    @Embedded val friend: FriendEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "friendId",
    )
    val giftIdeas: List<GiftIdeaEntity>,
    @Relation(
        parentColumn = "id",
        entityColumn = "friendId",
    )
    val entries: List<FriendEntryEntity>,
    @Relation(
        parentColumn = "id",
        entityColumn = "id",
        associateBy = Junction(
            value = FriendMeetingCrossRef::class,
            parentColumn = "friendId",
            entityColumn = "meetingId",
        ),
    )
    val meetings: List<MeetingEntity>,
)

data class MeetingWithFriends(
    @Embedded val meeting: MeetingEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "id",
        associateBy = Junction(
            value = FriendMeetingCrossRef::class,
            parentColumn = "meetingId",
            entityColumn = "friendId",
        ),
    )
    val friends: List<FriendEntity>,
)
