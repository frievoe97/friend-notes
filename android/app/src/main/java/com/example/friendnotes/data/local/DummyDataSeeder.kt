package com.example.friendnotes.data.local

import androidx.room.withTransaction
import com.example.friendnotes.data.AppSettingsRepository
import java.time.LocalDate
import java.time.ZonedDateTime

/**
 * Creates preview/debug seed data for local development.
 */
internal object DummyDataSeeder {

    private val defaultTags = listOf(
        "Best Friend", "Family", "Work", "Travel", "Gym", "Study",
        "Music", "Foodie", "Tech", "Sports", "Neighbors", "Creative",
    )

    suspend fun seedIfNeeded(
        database: AppDatabase,
        settingsRepository: AppSettingsRepository,
    ) {
        settingsRepository.update { settings ->
            if (settings.definedFriendTags.isEmpty()) {
                settings.copy(definedFriendTags = defaultTags)
            } else {
                settings
            }
        }

        database.withTransaction {
            val friendDao = database.friendDao()
            val meetingDao = database.meetingDao()
            val giftIdeaDao = database.giftIdeaDao()
            val friendEntryDao = database.friendEntryDao()

            if (friendDao.getAllFriends().isNotEmpty()) return@withTransaction

            val now = ZonedDateTime.now()
            var createdAtCursor = now.toInstant().toEpochMilli()

            fun nextCreatedAt(): Long = createdAtCursor++

            fun day(offset: Int, hour: Int, minute: Int): ZonedDateTime {
                return now
                    .plusDays(offset.toLong())
                    .withHour(hour)
                    .withMinute(minute)
                    .withSecond(0)
                    .withNano(0)
            }

            fun birthday(year: Int, month: Int, day: Int): Long =
                LocalDate.of(year, month, day).toEpochDay()

            suspend fun makeFriend(
                firstName: String,
                lastName: String,
                nickname: String = "",
                tags: List<String>,
                birthdayEpochDay: Long,
                favorite: Boolean = false,
            ): Long {
                return friendDao.insert(
                    FriendEntity(
                        firstName = firstName,
                        lastName = lastName,
                        nickname = nickname,
                        tagsRaw = org.json.JSONArray(tags).toString(),
                        birthdayEpochDay = birthdayEpochDay,
                        createdAtEpochMillis = nextCreatedAt(),
                        isFavorite = favorite,
                    )
                )
            }

            suspend fun addDetailedEntries(
                values: List<Pair<String, String>>,
                category: String,
                friendId: Long,
            ) {
                val existing = mutableSetOf<String>()
                var order = 0
                values.forEach { (titleRaw, noteRaw) ->
                    val title = titleRaw.trim()
                    val note = noteRaw.trim()
                    val key = title.lowercase()
                    if (title.isBlank() || !existing.add(key)) return@forEach
                    friendEntryDao.insert(
                        FriendEntryEntity(
                            friendId = friendId,
                            title = title,
                            note = note,
                            category = category,
                            `order` = order,
                            createdAtEpochMillis = nextCreatedAt(),
                        )
                    )
                    order += 1
                }
            }

            suspend fun addGift(
                title: String,
                note: String,
                isGifted: Boolean,
                friendId: Long,
            ) {
                giftIdeaDao.insert(
                    GiftIdeaEntity(
                        friendId = friendId,
                        title = title,
                        note = note,
                        isGifted = isGifted,
                        createdAtEpochMillis = nextCreatedAt(),
                    )
                )
            }

            suspend fun makeMeeting(
                dayOffset: Int,
                startHour: Int,
                startMinute: Int,
                durationMinutes: Int,
                note: String,
                friendIds: List<Long>,
            ) {
                val start = day(dayOffset, startHour, startMinute)
                val end = start.plusMinutes(durationMinutes.toLong())
                val meetingId = meetingDao.insert(
                    MeetingEntity(
                        eventTitle = "",
                        startDateEpochMillis = start.toInstant().toEpochMilli(),
                        endDateEpochMillis = end.toInstant().toEpochMilli(),
                        note = note,
                        kindRaw = "meeting",
                    )
                )
                meetingDao.insertCrossRefs(friendIds.distinct().map { FriendMeetingCrossRef(it, meetingId) })
            }

            suspend fun makeEvent(
                dayOffset: Int,
                hour: Int,
                minute: Int,
                title: String,
                note: String,
                friendIds: List<Long>,
            ) {
                val start = day(dayOffset, hour, minute)
                val eventId = meetingDao.insert(
                    MeetingEntity(
                        eventTitle = title,
                        startDateEpochMillis = start.toInstant().toEpochMilli(),
                        endDateEpochMillis = start.toInstant().toEpochMilli(),
                        note = note,
                        kindRaw = "event",
                    )
                )
                meetingDao.insertCrossRefs(friendIds.distinct().map { FriendMeetingCrossRef(it, eventId) })
            }

            val mia = makeFriend(
                firstName = "Mia",
                lastName = "Schneider",
                nickname = "Mimi",
                tags = listOf("Best Friend", "Work", "Foodie"),
                birthdayEpochDay = birthday(1993, 8, 17),
                favorite = true,
            )
            val leon = makeFriend(
                firstName = "Leon",
                lastName = "Keller",
                tags = listOf("Gym", "Travel", "Sports"),
                birthdayEpochDay = birthday(1990, 12, 3),
            )
            val emma = makeFriend(
                firstName = "Emma",
                lastName = "Wagner",
                nickname = "Em",
                tags = listOf("Family", "Study", "Creative"),
                birthdayEpochDay = birthday(2000, 4, 9),
                favorite = true,
            )
            val noah = makeFriend(
                firstName = "Noah",
                lastName = "Bergmann",
                nickname = "No",
                tags = listOf("Work", "Tech", "Neighbors"),
                birthdayEpochDay = birthday(1988, 9, 28),
            )
            val sofia = makeFriend(
                firstName = "Sofia",
                lastName = "Hartmann",
                nickname = "Sofi",
                tags = listOf("Travel", "Foodie", "Best Friend"),
                birthdayEpochDay = birthday(1994, 11, 21),
            )
            val paul = makeFriend(
                firstName = "Paul",
                lastName = "Neumann",
                tags = listOf("Sports", "Neighbors", "Family"),
                birthdayEpochDay = birthday(1992, 2, 14),
            )
            val lina = makeFriend(
                firstName = "Lina",
                lastName = "Krüger",
                nickname = "Li",
                tags = listOf("Creative", "Study", "Music"),
                birthdayEpochDay = birthday(1998, 7, 1),
            )

            data class ProfileData(
                val friendId: Long,
                val hobbies: List<Pair<String, String>>,
                val foods: List<Pair<String, String>>,
                val musics: List<Pair<String, String>>,
                val movies: List<Pair<String, String>>,
                val notes: List<Pair<String, String>>,
            )

            val profileData = listOf(
                ProfileData(
                    friendId = mia,
                    hobbies = listOf(
                        "Bouldering" to "Member at Boulderklub Nord, mostly Tue/Thu evenings.",
                        "Street Photography" to "Shoots with Fuji X100V; wants to try film in summer.",
                        "Pilates" to "Prefers classes on Saturday mornings.",
                        "Weekend City Trips" to "One museum + one cafe rule.",
                    ),
                    foods = listOf(
                        "Sushi" to "Loves salmon nigiri, dislikes too much mayo.",
                        "Homemade Pasta" to "Favorite: cacio e pepe, medium spicy.",
                        "Falafel Bowl" to "No olives; extra lemon dressing.",
                        "Tiramisu" to "Prefers less sweet, espresso-heavy versions.",
                    ),
                    musics = listOf(
                        "Indie Pop" to "Current loop: Japanese House + Phoebe Bridgers.",
                        "Lo-Fi" to "Uses chill playlists while editing photos.",
                        "Acoustic Sessions" to "Collects Tiny Desk performances.",
                        "Electro Swing" to "Dance playlists for house parties.",
                    ),
                    movies = listOf(
                        "The Bear" to "Loves the kitchen pacing.",
                        "Dune: Part Two" to "Wants to rewatch in IMAX.",
                        "Past Lives" to "Favorite from last year.",
                        "The White Lotus" to "Travel aesthetics inspiration.",
                    ),
                    notes = listOf(
                        "Prefers voice notes over long chats" to "Reply window usually same day.",
                        "Camera lens purchase in Q2" to "Comparing 23mm and 35mm options.",
                        "Planning Porto trip in June" to "Needs hotel shortlist.",
                        "Can do spontaneous weekday dinners" to "Best after 18:30.",
                    ),
                ),
                ProfileData(
                    friendId = leon,
                    hobbies = listOf(
                        "Half-Marathon Training" to "Long run Sundays; intervals Wednesdays.",
                        "Home Cooking" to "Batch-cooks for work week.",
                        "Strength Training" to "Lower-body split currently.",
                        "Hiking" to "Planning alpine weekend in May.",
                    ),
                    foods = listOf(
                        "Ramen" to "Prefers tonkotsu, no bamboo shoots.",
                        "Tacos" to "Fish tacos with lime crema.",
                        "Steak" to "Medium rare only.",
                        "Burrata Salad" to "Tomato + peach combo in summer.",
                    ),
                    musics = listOf(
                        "House" to "Friday workout playlist.",
                        "Hip-Hop" to "Old-school + UK rap mix.",
                        "Techno" to "Underground sets for long drives.",
                        "Drum & Bass" to "Pre-run motivation.",
                    ),
                    movies = listOf(
                        "Severance" to "Discusses theories after each episode.",
                        "Shogun" to "Favorite visuals this season.",
                        "The Gentlemen" to "Easy weekend binge.",
                        "Top Boy" to "Rewatch started.",
                    ),
                    notes = listOf(
                        "Morning person" to "Best calls before 9:00.",
                        "Lisbon trip planning" to "Wants running route suggestions.",
                        "Prefers short messages" to "Responsive in afternoons.",
                        "Buying new running shoes" to "Compare support vs. lightweight.",
                    ),
                ),
                ProfileData(
                    friendId = emma,
                    hobbies = listOf(
                        "Yoga" to "Loves vinyasa, avoids hot yoga.",
                        "Sketching" to "Carries A5 sketchbook daily.",
                        "Reading" to "Alternates fiction and essays.",
                        "Journaling" to "Nightly 10-minute reflections.",
                    ),
                    foods = listOf(
                        "Thai Curry" to "Yellow curry with tofu.",
                        "Dumplings" to "Favorite: mushroom + chive.",
                        "Granola Bowls" to "No banana, extra berries.",
                        "Miso Soup" to "Comfort food on busy days.",
                    ),
                    musics = listOf(
                        "Neo Soul" to "Plays while studying.",
                        "Jazz Piano" to "Favorite for calm evenings.",
                        "Indie Folk" to "Sunday cleanup soundtrack.",
                        "Classical" to "Focus playlists during exam prep.",
                    ),
                    movies = listOf(
                        "Normal People" to "Rewatch with friend group.",
                        "Little Women" to "All-time comfort movie.",
                        "The Bear" to "Loves character writing.",
                        "One Day" to "Recent recommendation.",
                    ),
                    notes = listOf(
                        "Final exams this month" to "Avoid late-night meetups.",
                        "Needs presentation rehearsal" to "Help with timing + slides.",
                        "Birthday dinner idea" to "Small group, cozy place.",
                        "Prefers Sunday check-ins" to "Usually free after 17:00.",
                    ),
                ),
                ProfileData(
                    friendId = noah,
                    hobbies = listOf(
                        "Cycling" to "Commutes by bike year-round.",
                        "Board Games" to "Hosts monthly game night.",
                        "Home Coffee Roasting" to "Tracks roast profiles in a sheet.",
                        "DIY Keyboard Builds" to "Trying silent tactile switches.",
                    ),
                    foods = listOf(
                        "Pho" to "Extra herbs, less sugar in broth.",
                        "Smash Burger" to "Double patty, no pickles.",
                        "Ceviche" to "Loves citrus-heavy versions.",
                        "Shakshuka" to "Weekend brunch staple.",
                    ),
                    musics = listOf(
                        "Ambient" to "For deep work blocks.",
                        "Progressive House" to "Night drive playlists.",
                        "Synthwave" to "Coding sessions.",
                        "Instrumental Hip-Hop" to "Morning focus.",
                    ),
                    movies = listOf(
                        "Black Mirror" to "Keeps a ranking list.",
                        "Arrival" to "Rewatch every few months.",
                        "Mr. Robot" to "Tech reference favorite.",
                        "Silo" to "Currently watching.",
                    ),
                    notes = listOf(
                        "Planning cloud migration" to "Decision meeting next week.",
                        "Prefers async updates" to "Slack over phone calls.",
                        "Available for office lunch" to "Tue or Thu works best.",
                        "Needs monitor stand recommendation" to "32-inch ultrawide setup.",
                    ),
                ),
                ProfileData(
                    friendId = sofia,
                    hobbies = listOf(
                        "Pottery" to "Works on cups and small plates.",
                        "Weekend Trips" to "Prefers train-friendly destinations.",
                        "Pilates" to "Mat classes twice a week.",
                        "Language Learning" to "Spanish practice every morning.",
                    ),
                    foods = listOf(
                        "Tapas" to "Loves pimientos + croquetas.",
                        "Paella" to "Seafood only.",
                        "Soba" to "Cold soba in summer.",
                        "Cheesecake" to "Basque style favorite.",
                    ),
                    musics = listOf(
                        "Latin Pop" to "Weekend dance playlist.",
                        "R&B" to "Evening wind-down songs.",
                        "Afrobeats" to "Party starter set.",
                        "Soul" to "Travel playlist staple.",
                    ),
                    movies = listOf(
                        "The Queen's Gambit" to "Rewatching with cousin.",
                        "Past Lives" to "Top recommendation.",
                        "The Diplomat" to "Current series.",
                        "Emily in Paris" to "Guilty pleasure watch.",
                    ),
                    notes = listOf(
                        "Collects restaurant tips per city" to "Keeps Notion list updated.",
                        "Flying to Lisbon soon" to "Send cafe suggestions.",
                        "Birthday gift should be handmade" to "No generic gift cards.",
                        "Prefers evening meetup times" to "After 19:00 ideal.",
                    ),
                ),
                ProfileData(
                    friendId = paul,
                    hobbies = listOf(
                        "Tennis" to "Doubles every Wednesday.",
                        "Swimming" to "Morning lanes Saturdays.",
                        "DIY Projects" to "Currently building shelf wall.",
                        "Cycling" to "Short evening rides in good weather.",
                    ),
                    foods = listOf(
                        "Napolitan Pizza" to "Thin crust, little cheese.",
                        "Kebab" to "No onions, spicy sauce.",
                        "Protein Bowl" to "Chicken + edamame combo.",
                        "Sourdough Sandwiches" to "Pesto + turkey favorite.",
                    ),
                    musics = listOf(
                        "Rock" to "Workout playlist classic.",
                        "Pop Punk" to "Nostalgic favorites.",
                        "Alternative" to "Weekend cycling mix.",
                        "Funk" to "For house chores.",
                    ),
                    movies = listOf(
                        "Ted Lasso" to "Comfort series.",
                        "Top Gun: Maverick" to "Favorite rewatch.",
                        "Drive to Survive" to "Keeps up each season.",
                        "The Last Dance" to "Sports doc favorite.",
                    ),
                    notes = listOf(
                        "Morning person" to "Best plans before noon.",
                        "Open for spontaneous bike rides" to "Usually available Sundays.",
                        "Home project help needed" to "Lamp installation pending.",
                        "Birthday dinner likes grills" to "Not too loud places.",
                    ),
                ),
                ProfileData(
                    friendId = lina,
                    hobbies = listOf(
                        "Illustration" to "Digital + watercolor mix.",
                        "Museum Visits" to "Modern art focus.",
                        "Calligraphy" to "Copperplate practice weekly.",
                        "Piano" to "Learning jazz standards.",
                    ),
                    foods = listOf(
                        "Poke Bowl" to "Salmon + mango combo.",
                        "Miso Soup" to "Comfort food for study days.",
                        "Blueberry Pancakes" to "Sunday brunch favorite.",
                        "Kimchi Fried Rice" to "Medium spicy.",
                    ),
                    musics = listOf(
                        "Film Scores" to "Hans Zimmer heavy rotation.",
                        "Classical" to "Focus while writing thesis.",
                        "Dream Pop" to "Evening drawing sessions.",
                        "Singer-Songwriter" to "Acoustic study breaks.",
                    ),
                    movies = listOf(
                        "Amelie" to "Visual style inspiration.",
                        "Howl's Moving Castle" to "Comfort rewatch.",
                        "Portrait of a Lady on Fire" to "Top 3 favorite.",
                        "Everything Everywhere All at Once" to "Loved narrative pace.",
                    ),
                    notes = listOf(
                        "Thesis deadline in two weeks" to "Needs low-distraction meetups.",
                        "Prefers coworking over cafes" to "Power outlet required.",
                        "Loves stationery" to "Pen set idea for birthday.",
                        "Saturday brunch works" to "After 11:30 ideal.",
                    ),
                ),
            )

            profileData.forEach { data ->
                addDetailedEntries(data.hobbies, category = "hobbies", friendId = data.friendId)
                addDetailedEntries(data.foods, category = "foods", friendId = data.friendId)
                addDetailedEntries(data.musics, category = "musics", friendId = data.friendId)
                addDetailedEntries(data.movies, category = "moviesSeries", friendId = data.friendId)
                addDetailedEntries(data.notes, category = "notes", friendId = data.friendId)
            }

            data class GiftProfile(val friendId: Long, val gifts: List<Triple<String, String, Boolean>>)

            val giftsByFriend = listOf(
                GiftProfile(
                    friendId = mia,
                    gifts = listOf(
                        Triple("Vintage Film Camera Strap", "Dark brown leather, minimal logo.", false),
                        Triple("Ceramic Dripper Set", "V60 size 02 + server.", true),
                        Triple("Climbing Chalk Bag", "Forest green preferred.", false),
                        Triple("Photo Book Voucher", "For annual print project.", false),
                    ),
                ),
                GiftProfile(
                    friendId = leon,
                    gifts = listOf(
                        Triple("Running Belt", "Slim model with key clip.", true),
                        Triple("Gym Towel Set", "Quick-dry microfiber.", false),
                        Triple("Massage Gun Mini", "Travel-friendly size preferred.", false),
                        Triple("Meal Prep Glass Containers", "Leak-proof lids are a must.", false),
                    ),
                ),
                GiftProfile(
                    friendId = emma,
                    gifts = listOf(
                        Triple("Premium Sketchbook", "A4, thick paper for markers.", false),
                        Triple("Bookstore Gift Card", "For post-exam reward.", false),
                        Triple("Desk Lamp", "Warm light, dimmable.", true),
                        Triple("Matcha Starter Set", "Bamboo whisk included.", false),
                    ),
                ),
                GiftProfile(
                    friendId = noah,
                    gifts = listOf(
                        Triple("Mechanical Keyboard Keycaps", "Muted grayscale set.", false),
                        Triple("Smart Bike Light", "USB-C rechargeable.", false),
                        Triple("Board Game Expansion", "Co-op mode preferred.", true),
                        Triple("Cable Organizer Kit", "Magnetic desk clips.", false),
                    ),
                ),
                GiftProfile(
                    friendId = sofia,
                    gifts = listOf(
                        Triple("Travel Journal", "Hardcover, blank dotted pages.", false),
                        Triple("Noise-Cancelling Earbuds", "For flights + coworking.", false),
                        Triple("Handmade Ceramic Mug", "Terracotta glaze style.", true),
                        Triple("Packing Cube Set", "Lightweight and washable.", false),
                    ),
                ),
                GiftProfile(
                    friendId = paul,
                    gifts = listOf(
                        Triple("Tennis Grip Bundle", "White + blue mix.", false),
                        Triple("Swim Goggles Pro", "Anti-fog mirrored lenses.", false),
                        Triple("DIY Tool Roll", "Compact size preferred.", true),
                        Triple("Insulated Bottle", "1L, dishwasher safe.", false),
                    ),
                ),
                GiftProfile(
                    friendId = lina,
                    gifts = listOf(
                        Triple("Watercolor Brush Set", "Synthetic sable, travel case.", false),
                        Triple("Museum Membership Pass", "Annual, flexible dates.", false),
                        Triple("Premium Pen Set", "Fine nib, black + sepia ink.", true),
                        Triple("Portable Sketch Light", "USB rechargeable.", false),
                    ),
                ),
            )

            giftsByFriend.forEach { (friendId, gifts) ->
                gifts.forEach { (title, note, gifted) ->
                    addGift(title, note, gifted, friendId)
                }
            }

            data class TimelineSeed(
                val isEvent: Boolean,
                val dayOffset: Int,
                val startHour: Int,
                val startMinute: Int,
                val durationMinutes: Int,
                val title: String,
                val note: String,
                val friendIds: List<Long>,
            )

            val timeline = listOf(
                TimelineSeed(false, -18, 19, 0, 110, "", "Italian dinner catch-up. Mia wants feedback on her photo-book layout.", listOf(mia, emma)),
                TimelineSeed(true, -15, 9, 0, 0, "Noah Production Rollout", "Send a good-luck message before deploy window.", listOf(noah)),
                TimelineSeed(false, -13, 18, 30, 90, "", "Running session with Leon + Paul, then smoothie stop.", listOf(leon, paul)),
                TimelineSeed(false, -10, 20, 0, 130, "", "Board-game evening at Noah's, bring card sleeves.", listOf(mia, noah, lina)),
                TimelineSeed(true, -8, 14, 15, 0, "Emma Oral Exam", "Call Emma after exam and plan celebration dinner.", listOf(emma)),
                TimelineSeed(false, -6, 12, 45, 75, "", "Lunch with Sofia to shortlist Lisbon cafes and coworking spots.", listOf(sofia)),
                TimelineSeed(false, -3, 19, 15, 105, "", "Pottery + dinner evening with Sofia and Lina.", listOf(sofia, lina)),
                TimelineSeed(false, -1, 8, 10, 60, "", "Morning tennis + coffee recap with Paul.", listOf(paul)),
                TimelineSeed(false, 1, 18, 30, 120, "", "Ramen night with Mia and Noah; discuss next mini-trip.", listOf(mia, noah)),
                TimelineSeed(true, 2, 10, 0, 0, "Lina Thesis Submission", "Flowers + short celebration planned for the evening.", listOf(lina)),
                TimelineSeed(false, 3, 19, 40, 100, "", "Workout + stretch block with Leon and Paul.", listOf(leon, paul)),
                TimelineSeed(true, 5, 16, 30, 0, "Sofia Flight to Lisbon", "Send airport transfer tips and ask for hotel update.", listOf(sofia)),
                TimelineSeed(false, 7, 11, 30, 95, "", "Brunch and museum plan with Emma + Lina.", listOf(emma, lina)),
                TimelineSeed(false, 9, 18, 0, 80, "", "Sprint-planning style check-in with Noah and Mia.", listOf(noah, mia)),
                TimelineSeed(true, 12, 8, 45, 0, "Leon Half Marathon", "Meet at km marker 15 with water and snacks.", listOf(leon)),
                TimelineSeed(false, 14, 20, 10, 125, "", "Movie + dessert night: Emma picks the film.", listOf(emma, mia, sofia)),
                TimelineSeed(false, 17, 13, 0, 70, "", "Quick lunch catch-up with Paul and Noah near office.", listOf(paul, noah)),
                TimelineSeed(true, 21, 19, 0, 0, "Mia Photo Walk Meetup", "Golden hour route through old town.", listOf(mia, lina)),
                TimelineSeed(false, 24, 18, 20, 120, "", "Group dinner: discuss summer trip dates.", listOf(mia, leon, emma, sofia, paul, lina)),
                TimelineSeed(false, 29, 11, 0, 90, "", "Sunday brunch with Sofia and Emma, keep it low-key.", listOf(sofia, emma)),
            )

            timeline.forEach { seed ->
                if (seed.isEvent) {
                    makeEvent(
                        dayOffset = seed.dayOffset,
                        hour = seed.startHour,
                        minute = seed.startMinute,
                        title = seed.title,
                        note = seed.note,
                        friendIds = seed.friendIds,
                    )
                } else {
                    makeMeeting(
                        dayOffset = seed.dayOffset,
                        startHour = seed.startHour,
                        startMinute = seed.startMinute,
                        durationMinutes = seed.durationMinutes,
                        note = seed.note,
                        friendIds = seed.friendIds,
                    )
                }
            }
        }
    }
}
