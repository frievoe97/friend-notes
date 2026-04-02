import Foundation
import SwiftData

/// Creates preview/debug seed data for local development.
enum DummyDataSeeder {
    /// Inserts realistic demo data with rich friend profiles, notes, gifts, meetings, and events.
    ///
    /// - Parameter context: Target SwiftData model context.
    static func insertDummyData(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let existingTagsRaw = UserDefaults.standard.string(forKey: AppTagStore.key) ?? "[]"
        if AppTagStore.decode(existingTagsRaw).isEmpty {
            let defaultTags = [
                "Best Friend", "Family", "Work", "Travel", "Gym", "Study",
                "Music", "Foodie", "Tech", "Sports", "Neighbors", "Creative"
            ]
            UserDefaults.standard.set(AppTagStore.encode(defaultTags), forKey: AppTagStore.key)
        }

        // Notification defaults:
        // - 3 days birthday
        // - 1 day meeting/event
        // - 4 weeks long-no-meeting enabled
        // - reminder time: debug -> near "now" for instant testing, release -> 09:00
        let reminderTimeMinutes: Int
        #if DEBUG
        let nowParts = calendar.dateComponents([.hour, .minute], from: now)
        let nowTotalMinutes = ((nowParts.hour ?? 9) * 60) + (nowParts.minute ?? 0)
        reminderTimeMinutes = min(nowTotalMinutes + 2, (23 * 60) + 59)
        #else
        reminderTimeMinutes = 9 * 60
        #endif
        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        UserDefaults.standard.set(true, forKey: "globalNotifyBirthday")
        UserDefaults.standard.set(3, forKey: "globalBirthdayReminderDays")
        UserDefaults.standard.set(true, forKey: "globalNotifyMeetings")
        UserDefaults.standard.set(1, forKey: "globalMeetingReminderDays")
        UserDefaults.standard.set(true, forKey: "globalNotifyEvents")
        UserDefaults.standard.set(1, forKey: "globalEventReminderDays")
        UserDefaults.standard.set(true, forKey: "globalNotifyLongNoMeeting")
        UserDefaults.standard.set(4, forKey: "globalLongNoMeetingWeeks")
        UserDefaults.standard.set(reminderTimeMinutes, forKey: "globalReminderTimeMinutes")
        UserDefaults.standard.set(true, forKey: "globalNotifyPostMeetingNote")

        func day(_ offset: Int, _ hour: Int, _ minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        @discardableResult
        func makeFriend(
            firstName: String,
            lastName: String,
            nickname: String = "",
            tags: [String],
            birthday: Date,
            favorite: Bool = false
        ) -> Friend {
            let friend = Friend(
                firstName: firstName,
                lastName: lastName,
                nickname: nickname,
                tags: tags,
                birthday: birthday,
                isFavorite: favorite
            )
            context.insert(friend)
            return friend
        }

        func makeMeeting(
            dayOffset: Int,
            startHour: Int,
            startMinute: Int,
            durationMinutes: Int,
            note: String,
            friends: [Friend]
        ) -> Meeting {
            let start = day(dayOffset, startHour, startMinute)
            let end = calendar.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
            return Meeting(
                eventTitle: "",
                startDate: start,
                endDate: end,
                note: note,
                kind: .meeting,
                friends: friends
            )
        }

        func makeEvent(
            dayOffset: Int,
            hour: Int,
            minute: Int,
            title: String,
            note: String,
            friends: [Friend]
        ) -> Meeting {
            let start = day(dayOffset, hour, minute)
            return Meeting(
                eventTitle: title,
                startDate: start,
                endDate: start,
                note: note,
                kind: .event,
                friends: friends
            )
        }

        func addDetailedEntries(
            _ values: [(title: String, note: String)],
            category: String,
            to friend: Friend
        ) {
            let existing = Set(
                friend.entryList(for: category).map {
                    $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                }
            )
            var order = friend.entryList(for: category).count
            for value in values where !existing.contains(value.title.lowercased()) {
                let entry = FriendEntry(
                    title: value.title,
                    note: value.note,
                    category: category,
                    order: order
                )
                context.insert(entry)
                friend.entries.append(entry)
                order += 1
            }
        }

        @discardableResult
        func addGift(_ title: String, _ note: String, _ isGifted: Bool = false, to friend: Friend? = nil) -> GiftIdea {
            let idea = GiftIdea(title: title, note: note, isGifted: isGifted)
            if let friend {
                idea.friend = friend
                friend.giftIdeas.append(idea)
            }
            context.insert(idea)
            return idea
        }

        // Exactly 7 friends with rich profile data.
        let mia = makeFriend(
            firstName: "Mia",
            lastName: "Schneider",
            nickname: "Mimi",
            tags: ["Best Friend", "Work", "Foodie"],
            birthday: calendar.date(from: DateComponents(year: 1993, month: 8, day: 17)) ?? now,
            favorite: true
        )
        let leon = makeFriend(
            firstName: "Leon",
            lastName: "Keller",
            tags: ["Gym", "Travel", "Sports"],
            birthday: calendar.date(from: DateComponents(year: 1990, month: 12, day: 3)) ?? now
        )
        let emma = makeFriend(
            firstName: "Emma",
            lastName: "Wagner",
            nickname: "Em",
            tags: ["Family", "Study", "Creative"],
            birthday: calendar.date(from: DateComponents(year: 2000, month: 4, day: 9)) ?? now,
            favorite: true
        )
        let noah = makeFriend(
            firstName: "Noah",
            lastName: "Bergmann",
            nickname: "No",
            tags: ["Work", "Tech", "Neighbors"],
            birthday: calendar.date(from: DateComponents(year: 1988, month: 9, day: 28)) ?? now
        )
        let sofia = makeFriend(
            firstName: "Sofia",
            lastName: "Hartmann",
            nickname: "Sofi",
            tags: ["Travel", "Foodie", "Best Friend"],
            birthday: calendar.date(from: DateComponents(year: 1994, month: 11, day: 21)) ?? now
        )
        let paul = makeFriend(
            firstName: "Paul",
            lastName: "Neumann",
            tags: ["Sports", "Neighbors", "Family"],
            birthday: calendar.date(from: DateComponents(year: 1992, month: 2, day: 14)) ?? now
        )
        let lina = makeFriend(
            firstName: "Lina",
            lastName: "Krüger",
            nickname: "Li",
            tags: ["Creative", "Study", "Music"],
            birthday: calendar.date(from: DateComponents(year: 1998, month: 7, day: 1)) ?? now
        )

        // Make one birthday reminder fire today with default lead time of 3 days.
        let birthdayTargetDate = calendar.date(byAdding: .day, value: 3, to: now) ?? now
        let birthdayParts = calendar.dateComponents([.month, .day], from: birthdayTargetDate)
        let emmaBirthYear = calendar.component(.year, from: emma.birthday ?? now)
        emma.birthday = calendar.date(
            from: DateComponents(
                year: emmaBirthYear,
                month: birthdayParts.month,
                day: birthdayParts.day
            )
        ) ?? emma.birthday

        let friendData: [(friend: Friend, hobbies: [(String, String)], foods: [(String, String)], musics: [(String, String)], movies: [(String, String)], notes: [(String, String)])] = [
            (
                mia,
                [("Bouldering", "Member at Boulderklub Nord, mostly Tue/Thu evenings."), ("Street Photography", "Shoots with Fuji X100V; wants to try film in summer."), ("Pilates", "Prefers classes on Saturday mornings."), ("Weekend City Trips", "One museum + one café rule.")],
                [("Sushi", "Loves salmon nigiri, dislikes too much mayo."), ("Homemade Pasta", "Favorite: cacio e pepe, medium spicy."), ("Falafel Bowl", "No olives; extra lemon dressing."), ("Tiramisu", "Prefers less sweet, espresso-heavy versions.")],
                [("Indie Pop", "Current loop: Japanese House + Phoebe Bridgers."), ("Lo-Fi", "Uses chill playlists while editing photos."), ("Acoustic Sessions", "Collects Tiny Desk performances."), ("Electro Swing", "Dance playlists for house parties.")],
                [("The Bear", "Loves the kitchen pacing."), ("Dune: Part Two", "Wants to rewatch in IMAX."), ("Past Lives", "Favorite from last year."), ("The White Lotus", "Travel aesthetics inspiration.")],
                [("Prefers voice notes over long chats", "Reply window usually same day."), ("Camera lens purchase in Q2", "Comparing 23mm and 35mm options."), ("Planning Porto trip in June", "Needs hotel shortlist."), ("Can do spontaneous weekday dinners", "Best after 18:30.")]
            ),
            (
                leon,
                [("Half-Marathon Training", "Long run Sundays; intervals Wednesdays."), ("Home Cooking", "Batch-cooks for work week."), ("Strength Training", "Lower-body split currently."), ("Hiking", "Planning alpine weekend in May.")],
                [("Ramen", "Prefers tonkotsu, no bamboo shoots."), ("Tacos", "Fish tacos with lime crema."), ("Steak", "Medium rare only."), ("Burrata Salad", "Tomato + peach combo in summer.")],
                [("House", "Friday workout playlist."), ("Hip-Hop", "Old-school + UK rap mix."), ("Techno", "Underground sets for long drives."), ("Drum & Bass", "Pre-run motivation.")],
                [("Severance", "Discusses theories after each episode."), ("Shogun", "Favorite visuals this season."), ("The Gentlemen", "Easy weekend binge."), ("Top Boy", "Rewatch started.")],
                [("Morning person", "Best calls before 9:00."), ("Lisbon trip planning", "Wants running route suggestions."), ("Prefers short messages", "Responsive in afternoons."), ("Buying new running shoes", "Compare support vs. lightweight.")]
            ),
            (
                emma,
                [("Yoga", "Loves vinyasa, avoids hot yoga."), ("Sketching", "Carries A5 sketchbook daily."), ("Reading", "Alternates fiction and essays."), ("Journaling", "Nightly 10-minute reflections.")],
                [("Thai Curry", "Yellow curry with tofu."), ("Dumplings", "Favorite: mushroom + chive."), ("Granola Bowls", "No banana, extra berries."), ("Miso Soup", "Comfort food on busy days.")],
                [("Neo Soul", "Plays while studying."), ("Jazz Piano", "Favorite for calm evenings."), ("Indie Folk", "Sunday cleanup soundtrack."), ("Classical", "Focus playlists during exam prep.")],
                [("Normal People", "Rewatch with friend group."), ("Little Women", "All-time comfort movie."), ("The Bear", "Loves character writing."), ("One Day", "Recent recommendation.")],
                [("Final exams this month", "Avoid late-night meetups."), ("Needs presentation rehearsal", "Help with timing + slides."), ("Birthday dinner idea", "Small group, cozy place."), ("Prefers Sunday check-ins", "Usually free after 17:00.")]
            ),
            (
                noah,
                [("Cycling", "Commutes by bike year-round."), ("Board Games", "Hosts monthly game night."), ("Home Coffee Roasting", "Tracks roast profiles in a sheet."), ("DIY Keyboard Builds", "Trying silent tactile switches.")],
                [("Pho", "Extra herbs, less sugar in broth."), ("Smash Burger", "Double patty, no pickles."), ("Ceviche", "Loves citrus-heavy versions."), ("Shakshuka", "Weekend brunch staple.")],
                [("Ambient", "For deep work blocks."), ("Progressive House", "Night drive playlists."), ("Synthwave", "Coding sessions."), ("Instrumental Hip-Hop", "Morning focus.")],
                [("Black Mirror", "Keeps a ranking list."), ("Arrival", "Rewatch every few months."), ("Mr. Robot", "Tech reference favorite."), ("Silo", "Currently watching.")],
                [("Planning cloud migration", "Decision meeting next week."), ("Prefers async updates", "Slack over phone calls."), ("Available for office lunch", "Tue or Thu works best."), ("Needs monitor stand recommendation", "32-inch ultrawide setup.")]
            ),
            (
                sofia,
                [("Pottery", "Works on cups and small plates."), ("Weekend Trips", "Prefers train-friendly destinations."), ("Pilates", "Mat classes twice a week."), ("Language Learning", "Spanish practice every morning.")],
                [("Tapas", "Loves pimientos + croquetas."), ("Paella", "Seafood only."), ("Soba", "Cold soba in summer."), ("Cheesecake", "Basque style favorite.")],
                [("Latin Pop", "Weekend dance playlist."), ("R&B", "Evening wind-down songs."), ("Afrobeats", "Party starter set."), ("Soul", "Travel playlist staple.")],
                [("The Queen's Gambit", "Rewatching with cousin."), ("Past Lives", "Top recommendation."), ("The Diplomat", "Current series."), ("Emily in Paris", "Guilty pleasure watch.")],
                [("Collects restaurant tips per city", "Keeps Notion list updated."), ("Flying to Lisbon soon", "Send café suggestions."), ("Birthday gift should be handmade", "No generic gift cards."), ("Prefers evening meetup times", "After 19:00 ideal.")]
            ),
            (
                paul,
                [("Tennis", "Doubles every Wednesday."), ("Swimming", "Morning lanes Saturdays."), ("DIY Projects", "Currently building shelf wall."), ("Cycling", "Short evening rides in good weather.")],
                [("Napolitan Pizza", "Thin crust, little cheese."), ("Kebab", "No onions, spicy sauce."), ("Protein Bowl", "Chicken + edamame combo."), ("Sourdough Sandwiches", "Pesto + turkey favorite.")],
                [("Rock", "Workout playlist classic."), ("Pop Punk", "Nostalgic favorites."), ("Alternative", "Weekend cycling mix."), ("Funk", "For house chores.")],
                [("Ted Lasso", "Comfort series."), ("Top Gun: Maverick", "Favorite rewatch."), ("Drive to Survive", "Keeps up each season."), ("The Last Dance", "Sports doc favorite.")],
                [("Morning person", "Best plans before noon."), ("Open for spontaneous bike rides", "Usually available Sundays."), ("Home project help needed", "Lamp installation pending."), ("Birthday dinner likes grills", "Not too loud places.")]
            ),
            (
                lina,
                [("Illustration", "Digital + watercolor mix."), ("Museum Visits", "Modern art focus."), ("Calligraphy", "Copperplate practice weekly."), ("Piano", "Learning jazz standards.")],
                [("Poke Bowl", "Salmon + mango combo."), ("Miso Soup", "Comfort food for study days."), ("Blueberry Pancakes", "Sunday brunch favorite."), ("Kimchi Fried Rice", "Medium spicy.")],
                [("Film Scores", "Hans Zimmer heavy rotation."), ("Classical", "Focus while writing thesis."), ("Dream Pop", "Evening drawing sessions."), ("Singer-Songwriter", "Acoustic study breaks.")],
                [("Amelie", "Visual style inspiration."), ("Howl's Moving Castle", "Comfort rewatch."), ("Portrait of a Lady on Fire", "Top 3 favorite."), ("Everything Everywhere All at Once", "Loved narrative pace.")],
                [("Thesis deadline in two weeks", "Needs low-distraction meetups."), ("Prefers coworking over cafés", "Power outlet required."), ("Loves stationery", "Pen set idea for birthday."), ("Saturday brunch works", "After 11:30 ideal.")]
            )
        ]

        for data in friendData {
            addDetailedEntries(data.hobbies, category: "hobbies", to: data.friend)
            addDetailedEntries(data.foods, category: "foods", to: data.friend)
            addDetailedEntries(data.musics, category: "musics", to: data.friend)
            addDetailedEntries(data.movies, category: "moviesSeries", to: data.friend)
            addDetailedEntries(data.notes, category: "notes", to: data.friend)
        }

        let giftsByFriend: [(Friend, [(String, String, Bool)])] = [
            (mia, [("Vintage Film Camera Strap", "Dark brown leather, minimal logo.", false), ("Ceramic Dripper Set", "V60 size 02 + server.", true), ("Climbing Chalk Bag", "Forest green preferred.", false), ("Photo Book Voucher", "For annual print project.", false)]),
            (leon, [("Running Belt", "Slim model with key clip.", true), ("Gym Towel Set", "Quick-dry microfiber.", false), ("Massage Gun Mini", "Travel-friendly size preferred.", false), ("Meal Prep Glass Containers", "Leak-proof lids are a must.", false)]),
            (emma, [("Premium Sketchbook", "A4, thick paper for markers.", false), ("Bookstore Gift Card", "For post-exam reward.", false), ("Desk Lamp", "Warm light, dimmable.", true), ("Matcha Starter Set", "Bamboo whisk included.", false)]),
            (noah, [("Mechanical Keyboard Keycaps", "Muted grayscale set.", false), ("Smart Bike Light", "USB-C rechargeable.", false), ("Board Game Expansion", "Co-op mode preferred.", true), ("Cable Organizer Kit", "Magnetic desk clips.", false)]),
            (sofia, [("Travel Journal", "Hardcover, blank dotted pages.", false), ("Noise-Cancelling Earbuds", "For flights + coworking.", false), ("Handmade Ceramic Mug", "Terracotta glaze style.", true), ("Packing Cube Set", "Lightweight and washable.", false)]),
            (paul, [("Tennis Grip Bundle", "White + blue mix.", false), ("Swim Goggles Pro", "Anti-fog mirrored lenses.", false), ("DIY Tool Roll", "Compact size preferred.", true), ("Insulated Bottle", "1L, dishwasher safe.", false)]),
            (lina, [("Watercolor Brush Set", "Synthetic sable, travel case.", false), ("Museum Membership Pass", "Annual, flexible dates.", false), ("Premium Pen Set", "Fine nib, black + sepia ink.", true), ("Portable Sketch Light", "USB rechargeable.", false)])
        ]

        for (friend, gifts) in giftsByFriend {
            for gift in gifts {
                addGift(gift.0, gift.1, gift.2, to: friend)
            }
        }

        let extraGiftsByFriend: [(Friend, [(String, String, Bool)])] = [
            (mia, [("Portable Tripod", "Compact phone + camera mount for city walks.", false), ("Specialty Coffee Beans", "Light roast from local roastery.", false), ("Museum Annual Pass", "For modern art exhibitions.", true)]),
            (leon, [("Compression Socks", "For post-run recovery.", false), ("Trail Snack Pack", "High-protein bars + electrolyte tabs.", true), ("Recovery Foam Roller", "Medium density, travel size.", false)]),
            (emma, [("Fountain Pen Ink Set", "Muted colors for journaling.", false), ("Art Store Gift Card", "For canvas + marker refill.", true), ("Noise-Reducing Earplugs", "For focused study sessions.", false)]),
            (noah, [("Desk Cable Dock", "Weighted base for charging cables.", false), ("Cold Brew Bottle", "Heat-resistant glass with filter.", false), ("Bike Saddle Bag", "Slim and waterproof.", true)]),
            (sofia, [("Weekend Duffel Bag", "Cabin-size with shoe compartment.", false), ("Hand Cream Set", "Travel-friendly minis.", true), ("Photography Tour Voucher", "Lisbon old town route.", false)]),
            (paul, [("Sports Massage Voucher", "45-minute deep tissue session.", false), ("Bike Repair Stand", "Foldable for apartment storage.", true), ("Tennis Overgrip 12-Pack", "Dry feel, mixed colors.", false)]),
            (lina, [("Acrylic Marker Set", "Fine + medium tips.", false), ("Foldable Easel", "Tabletop version for small spaces.", false), ("Concert Ticket Voucher", "Open date in autumn.", true)])
        ]

        for (friend, gifts) in extraGiftsByFriend {
            for gift in gifts {
                addGift(gift.0, gift.1, gift.2, to: friend)
            }
        }

        let unassignedGifts: [(String, String, Bool)] = [
            ("Universal Gift Card", "Keep as fallback for spontaneous invites.", false),
            ("Premium Tea Sampler", "Works for almost anyone; mixed herbal set.", false),
            ("Chocolate Praline Box", "Seasonal edition for host gifts.", true),
            ("Scented Candle Duo", "Neutral fragrances for apartment warm-up.", false),
            ("Notebook + Pen Bundle", "Emergency birthday option.", false),
            ("Indoor Herb Kit", "Good for housewarming events.", true)
        ]

        for gift in unassignedGifts {
            addGift(gift.0, gift.1, gift.2)
        }

        let timeline: [Meeting] = [
            makeMeeting(dayOffset: -46, startHour: 18, startMinute: 20, durationMinutes: 95, note: "After-work ramen with Leon and Noah; talked about summer race plans.", friends: [leon, noah]),
            makeEvent(dayOffset: -42, hour: 9, minute: 30, title: "Sofia Visa Appointment", note: "Sent checklist and reminder the day before.", friends: [sofia]),
            makeMeeting(dayOffset: -38, startHour: 19, startMinute: 5, durationMinutes: 105, note: "Museum + late dinner with Mia and Lina.", friends: [mia, lina]),
            makeMeeting(dayOffset: -34, startHour: 12, startMinute: 15, durationMinutes: 70, note: "Lunch walk with Emma near campus before her seminar.", friends: [emma]),
            makeEvent(dayOffset: -31, hour: 17, minute: 45, title: "Paul Apartment Handover", note: "Helped him move smaller boxes and brought snacks.", friends: [paul]),
            makeMeeting(dayOffset: -27, startHour: 20, startMinute: 0, durationMinutes: 115, note: "Game night with Noah, Mia and Leon.", friends: [noah, mia, leon]),
            makeEvent(dayOffset: -23, hour: 8, minute: 20, title: "Leon Physio Check", note: "Recovery update before race block.", friends: [leon]),
            makeMeeting(dayOffset: -18, startHour: 19, startMinute: 0, durationMinutes: 110, note: "Italian dinner catch-up. Mia wants feedback on her photo-book layout.", friends: [mia, emma]),
            makeEvent(dayOffset: -15, hour: 9, minute: 0, title: "Noah Production Rollout", note: "Send a good-luck message before deploy window.", friends: [noah]),
            makeMeeting(dayOffset: -13, startHour: 18, startMinute: 30, durationMinutes: 90, note: "Running session with Leon + Paul, then smoothie stop.", friends: [leon, paul]),
            makeMeeting(dayOffset: -10, startHour: 20, startMinute: 0, durationMinutes: 130, note: "Board-game evening at Noah's, bring card sleeves.", friends: [mia, noah, lina]),
            makeEvent(dayOffset: -8, hour: 14, minute: 15, title: "Emma Oral Exam", note: "Call Emma after exam and plan celebration dinner.", friends: [emma]),
            makeMeeting(dayOffset: -6, startHour: 12, startMinute: 45, durationMinutes: 75, note: "Lunch with Sofia to shortlist Lisbon cafés and coworking spots.", friends: [sofia]),
            makeMeeting(dayOffset: -3, startHour: 19, startMinute: 15, durationMinutes: 105, note: "Pottery + dinner evening with Sofia and Lina.", friends: [sofia, lina]),
            makeMeeting(dayOffset: -1, startHour: 8, startMinute: 10, durationMinutes: 60, note: "Morning tennis + coffee recap with Paul.", friends: [paul]),
            makeMeeting(dayOffset: 4, startHour: 18, startMinute: 30, durationMinutes: 120, note: "Ramen night with Mia and Noah; discuss next mini-trip.", friends: [mia, noah]),
            makeEvent(dayOffset: 2, hour: 10, minute: 0, title: "Lina Thesis Submission", note: "Flowers + short celebration planned for the evening.", friends: [lina]),
            makeMeeting(dayOffset: 3, startHour: 19, startMinute: 40, durationMinutes: 100, note: "Workout + stretch block with Leon and Paul.", friends: [leon, paul]),
            makeEvent(dayOffset: 5, hour: 16, minute: 30, title: "Sofia Flight to Lisbon", note: "Send airport transfer tips and ask for hotel update.", friends: [sofia]),
            makeMeeting(dayOffset: 7, startHour: 11, startMinute: 30, durationMinutes: 95, note: "Brunch and museum plan with Emma + Lina.", friends: [emma, lina]),
            makeMeeting(dayOffset: 9, startHour: 18, startMinute: 0, durationMinutes: 80, note: "Sprint-planning style check-in with Noah and Mia.", friends: [noah, mia]),
            makeEvent(dayOffset: 12, hour: 8, minute: 45, title: "Leon Half Marathon", note: "Meet at km marker 15 with water and snacks.", friends: [leon]),
            makeMeeting(dayOffset: 14, startHour: 20, startMinute: 10, durationMinutes: 125, note: "Movie + dessert night: Emma picks the film.", friends: [emma, mia, sofia]),
            makeMeeting(dayOffset: 17, startHour: 13, startMinute: 0, durationMinutes: 70, note: "Quick lunch catch-up with Paul and Noah near office.", friends: [paul, noah]),
            makeEvent(dayOffset: 21, hour: 19, minute: 0, title: "Mia Photo Walk Meetup", note: "Golden hour route through old town.", friends: [mia, lina]),
            makeMeeting(dayOffset: 24, startHour: 18, startMinute: 20, durationMinutes: 120, note: "Group dinner: discuss summer trip dates.", friends: [mia, leon, emma, sofia, paul, lina]),
            makeMeeting(dayOffset: 29, startHour: 11, startMinute: 0, durationMinutes: 90, note: "Sunday brunch with Sofia and Emma, keep it low-key.", friends: [sofia, emma]),
            makeEvent(dayOffset: 33, hour: 7, minute: 50, title: "Noah Conference Flight", note: "Share terminal info and coffee spot recommendation.", friends: [noah]),
            makeMeeting(dayOffset: 36, startHour: 19, startMinute: 30, durationMinutes: 100, note: "Potluck dinner with Paul and Lina; bring dessert.", friends: [paul, lina]),
            makeEvent(dayOffset: 40, hour: 15, minute: 0, title: "Emma Portfolio Review", note: "Prepare feedback points for her final presentation.", friends: [emma]),
            makeMeeting(dayOffset: 44, startHour: 18, startMinute: 10, durationMinutes: 85, note: "Cycling + smoothie cooldown with Leon.", friends: [leon]),
            makeEvent(dayOffset: 49, hour: 20, minute: 0, title: "Sofia Family Dinner", note: "Send flowers in the afternoon.", friends: [sofia]),
            makeMeeting(dayOffset: 53, startHour: 12, startMinute: 40, durationMinutes: 75, note: "Lunch and stationery shopping with Mia.", friends: [mia]),
            makeEvent(dayOffset: 57, hour: 10, minute: 30, title: "Lina Gallery Opening", note: "Meet at entrance 20 minutes early.", friends: [lina]),
            makeMeeting(dayOffset: 61, startHour: 18, startMinute: 25, durationMinutes: 115, note: "Summer-planning dinner with full group.", friends: [mia, leon, emma, noah, sofia, paul, lina])
        ]
        timeline.forEach { context.insert($0) }
        
        // Notification test fixtures are created once with the initial seed.
        // They are relative to "now" at seed time and then remain stable.
        let reminderWeeks = 4

        // Two natural friends for "long time no see" reminders.
        let hannah = makeFriend(
            firstName: "Hannah",
            lastName: "Weber",
            nickname: "Hanni",
            tags: ["Travel", "Foodie", "Creative"],
            birthday: calendar.date(from: DateComponents(year: 1995, month: 5, day: 11)) ?? now
        )
        let jonas = makeFriend(
            firstName: "Jonas",
            lastName: "Richter",
            nickname: "Jo",
            tags: ["Work", "Gym", "Tech"],
            birthday: calendar.date(from: DateComponents(year: 1991, month: 10, day: 4)) ?? now
        )

        // Meeting/event reminders (default 1 day before):
        // 1 meeting with one person, one with two, one with three, and two events.
        let reminderFixtures: [Meeting] = [
            makeMeeting(
                dayOffset: 1,
                startHour: 17,
                startMinute: 15,
                durationMinutes: 70,
                note: "Kaffee nach der Arbeit in Prenzlauer Berg.",
                friends: [noah]
            ),
            makeMeeting(
                dayOffset: 1,
                startHour: 18,
                startMinute: 30,
                durationMinutes: 80,
                note: "Abendlauf im Park und danach ein schneller Snack.",
                friends: [noah, mia]
            ),
            makeMeeting(
                dayOffset: 1,
                startHour: 19,
                startMinute: 45,
                durationMinutes: 90,
                note: "Spieleabend bei Leon mit Pasta und Musik.",
                friends: [noah, mia, paul]
            ),
            makeEvent(
                dayOffset: 1,
                hour: 16,
                minute: 0,
                title: "Konzert im Stadtpark",
                note: "Treffpunkt am Haupteingang.",
                friends: [noah, mia]
            ),
            makeEvent(
                dayOffset: 1,
                hour: 20,
                minute: 15,
                title: "Open-Air Kinoabend",
                note: "Decken und Snacks mitbringen.",
                friends: [noah, mia, paul]
            )
        ]
        reminderFixtures.forEach { context.insert($0) }

        // Long-time-no-see baseline meetings older than the 4-week threshold.
        let oldStart = calendar.date(byAdding: .weekOfYear, value: -(reminderWeeks + 2), to: now) ?? now
        let oldEnd = calendar.date(byAdding: .minute, value: 60, to: oldStart) ?? oldStart
        let longNoSeeBaselines: [Meeting] = [
            Meeting(
                eventTitle: "",
                startDate: oldStart,
                endDate: max(oldEnd, oldStart),
                note: "Frühstück im Altbau-Café, seitdem gab es kein neues Treffen.",
                kind: .meeting,
                friends: [hannah]
            ),
            Meeting(
                eventTitle: "",
                startDate: oldStart,
                endDate: max(oldEnd, oldStart),
                note: "Kurzer Spaziergang an der Spree, seit Wochen keinen neuen Termin geschafft.",
                kind: .meeting,
                friends: [jonas]
            )
        ]
        longNoSeeBaselines.forEach { context.insert($0) }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save dummy data: \(error)")
        }
    }
}
