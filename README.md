# Friend Notes (iOS)

Friend Notes helps you stay close to the people who matter most.  
Track friends, birthdays, meetings/events, and gift ideas in one private, local-first app.

**Status:** The app is currently **not** available on the App Store.
  
**Platform:** iPhone only (portrait mode).

Repository: [frievoe97/friend-notes](https://github.com/frievoe97/friend-notes)

## Target & Quick Start

Friend Notes is built for people who want a lightweight personal CRM without complexity.  
It turns scattered mental notes into a simple, searchable workflow on iPhone.

## Features

- Keep a structured friend list with names, nicknames, tags, birthday, and favorites.
- Add category notes per friend (hobbies, food, music, movies/series, free notes).
- Plan meetings and events with date/time, participants, and notes.
- Browse plans in calendar mode or upcoming-list mode.
- Capture gift ideas globally and per friend, including notes and links.
- Get local reminders for birthdays, meetings/events, long time no see, and post-meeting notes.
- Use deep links from notifications directly to the relevant friend or event.
- Use the app in German and English.

## Screenshots

| Friends | Calendar | Gift Ideas |
|---|---|---|
| ![Friends list and relationship overview](docs/screenshots/ios/screenshot_1.png) | ![Upcoming calendar entries and planning](docs/screenshots/ios/screenshot_2.png) | ![Gift ideas with open and completed states](docs/screenshots/ios/screenshot_3.png) |

## Tech Stack

- `Swift` + `SwiftUI`
- `SwiftData` for persistence
- `UserNotifications` for local reminders
- `XCTest` for unit tests
- `Localizable.strings` + lightweight `L10n` helper for localization

## Architecture

The app follows a **feature-first SwiftUI architecture** with a clear separation of concerns:

- `Domain`: core models (`Friend`, `Meeting`, `GiftIdea`, `FriendEntry`) and localization helper
- `Features`: screen-level UI grouped by business feature (`Friends`, `Calendar`, `Gifts`, `Meetings`, `Settings`)
- `Services`: cross-cutting services such as notification scheduling/routing
- `UI`: reusable components and visual theme primitives
- `App`: app entry point and support utilities

Key decisions:

- Local-first data model with `SwiftData` (no backend dependency).
- Shared notification scheduler that rebuilds reminders from persisted models + global settings.
- Centralized global settings via `@AppStorage`.

## Installation / Setup

### Requirements

- macOS with **Xcode 26.2+**
- iOS Simulator or device with **iOS 26.2+**

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/frievoe97/friend-notes.git
   ```
2. Open the iOS project:
   ```bash
   cd friend-notes/apps/ios/Friend\ Notes
   open "Friend Notes.xcodeproj"
   ```
3. Select the **Friend Notes** scheme.
4. Select an iPhone simulator/device.
5. Build and run (`Cmd + R`).

### Run Unit Tests

- In Xcode: `Cmd + U`
- Test target: `Friend NotesTests`

## Project Structure

```text
friend-notes/
├─ apps/
│  └─ ios/
│     └─ Friend Notes/
│        ├─ Friend Notes.xcodeproj
│        ├─ Friend Notes/        # iOS app source
│        │  ├─ App/              # App entry + app-level support
│        │  ├─ Domain/           # Models + localization
│        │  ├─ Features/         # Feature modules (Friends/Calendar/Gifts/...)
│        │  ├─ Services/         # Notification and other services
│        │  └─ UI/               # Shared UI components + theme
│        └─ Friend NotesTests/   # Unit tests
├─ assets/
│  └─ design/                    # Logo/icon source files and exports
├─ docs/
│  └─ screenshots/
│     └─ ios/                    # App screenshots used in docs
├─ README.md
└─ LICENSE
```

## Usage

1. Create friends in the **Friends** tab.
2. Add profile context (tags, birthday, notes, interests).
3. Schedule meetings/events via **Calendar** or from a friend profile.
4. Track gift ideas in **Gifts** and assign them to friends.
5. Configure reminder behavior in **Settings**.

## Configuration

- No API keys or external services are required.
- Notifications require user permission at runtime.
- Global notification behavior is configured in app settings.
- Global friend tags are managed centrally in settings and reused across profiles.

## Roadmap

- [ ] iCloud sync / cross-device sync
- [ ] Data export and backup options
- [ ] Home Screen widgets for upcoming reminders
- [ ] More filtering and analytics for relationship history

## Contribution

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Keep changes focused and consistent with the existing folder structure.
4. Add or update tests for logic changes.
5. Open a pull request with a clear description and screenshots if UI changed.

## License

This project is licensed under the terms of the [LICENSE](./LICENSE) file.

## Author / Contact

- Friedrich Voelkers
- GitHub: [@frievoe97](https://github.com/frievoe97)
