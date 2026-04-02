package com.example.friendnotes.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        FriendEntity::class,
        MeetingEntity::class,
        GiftIdeaEntity::class,
        FriendEntryEntity::class,
        FriendMeetingCrossRef::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun friendDao(): FriendDao
    abstract fun meetingDao(): MeetingDao
    abstract fun giftIdeaDao(): GiftIdeaDao
    abstract fun friendEntryDao(): FriendEntryDao

    companion object {
        @Volatile
        private var instance: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "friend_notes.db",
                ).build().also { instance = it }
            }
        }
    }
}
