# KIT305 - Assignment 4 - Cross Platform App (Flutter)

## Author Information
- **Name**: Joshua Crisford
- **Student ID**: 574082
- **Unit**: KIT305 - Mobile Application Development
- **Assignment**: Assignment 4 - Cross Platform App

---

## Overview

This project is a Flutter-based cross-platform application designed to track and manage Australian Football League (AFL) statistics. It allows users to create teams and players, track in-game AFL actions, compare performance, and review match history. The app uses Firebase Firestore for cloud data persistence and Dart for all application logic.

Key features include:
- Team and player management (including profile images)
- Live match tracking with quarter management and stat recording
- Match history view with quarter-based breakdowns
- Player and team comparisons with visual highlighting
- JSON and text export of match history

Tested on both Android emulators and physical Android devices.

---

## Testing Instructions

To test this application, use the following environment:

- **Platform**: Android (primary target)
- **Flutter Version**: 3.22 or higher
- **Test Device**: Samsung Galaxy S25 Plus
- **OS Version**: Android 13
- **Screen Size**: 6.7 inches (1440 x 3120 pixels) recommended
- **Firebase Setup**: Linked via `google-services.json`

### Pre-Filled Data

To ease testing and marking:
- Six teams with real-world inspired names and eight players each are preloaded.
- Two matches are included with stat actions logically distributed across all four quarters.
- Player images are not preloaded but image selection functionality is enabled.

### How to Test

1. **Team Management**
    - Tap **Team Management** on the home screen.
    - Add, rename, or delete teams. Tap a team to manage its players.
    - Within a team, add players with name, number, and (optional) photo.

2. **Create Match**
    - Tap **Create Match**, select two different teams.
    - Press **Start Match** to begin.

3. **Track Match**
    - Each quarter is 20 minutes (simulated with countdown timer).
    - Select player and action, stats are recorded live to Firestore.
    - After Q4, the match ends automatically.

4. **Recording Actions**:
    - On the Match Tracking screen, tap **Start Game** to begin Quarter 1.
    - Select a team and player, then use the action buttons to log stats (Kick, Handball, Goal, etc.).
    - The timer runs for 20 minutes per quarter (auto-stops), and scores are updated in real-time.

5. **Viewing Match History**:
    - Tap **Match History** from the Home screen.
    - Select a match from the list to view:
        - Team and player stats (by quarter or full match).
        - A full list of player actions.
        - Options to export the data as plain text or JSON.

---

## Features and Implementation Details

### Player and Team Management
- `TeamManagementScreen` and `PlayerManagementScreen` allow CRUD operations for teams and players.
- Players are assigned to teams using `teamId`.
- Images selected via gallery or camera are stored locally using `path_provider`, and their URI saved in Firestore.

### Match Tracking
- `MatchTrackingScreen` handles quarter timing, action selection, and stat logging.
- Uses segmented buttons for team selection, dropdowns for player choice, and buttons for actions (Kick, Mark, Tackle, etc.)
- Actions are saved to:
  - `matchData/{matchId}/matchActions`
  - `matchData/{matchId}/players/{playerName}`
  - `matchData/{matchId}/players/{playerName}/actions`

### Match History & Comparisons
- `MatchHistoryScreen` shows full match data and breakdown by quarters.
- MVP and total team scores shown, with match sharing supported via platform share dialog.
- `PlayerStatsScreen` and `TeamStatsScreen` allow comparisons with per-quarter filtering and highlight better performers.

### Firestore Data Structure
- `teamData/` → contains teams (`name`, `createdAt`)
- `players/` → contains players (`name`, `number`, `teamId`, stats, `imageUri`)
- `matchData/` → contains match info and nested:
  - `matchActions/`
  - `players/` → each player’s stat summary and `actions/`

### MVP System (Custom Feature)
MVP is calculated using a weighted formula:
- Goals: 6 pts
- Behinds: 1 pt
- Kicks + Handballs (Disposals): 1 pt each
- Marks: 1 pt
- Tackles: 2 pts

The MVP is determined automatically and displayed at the end of each match within an alert dialog. It is also shown in the `player_stats_screen.dart`, where users can review the MVP and compare it to other players’ stats.

---

## Artificial Intelligence Disclosure

### Windows Copilot
Used extensively for:
- Debugging Firebase schema issues
- Fixing async timing bugs in action recording
- Reviewing and formatting this README
- Implementing reusable code snippets (timer logic, MVP logic, etc.)
- Guiding proper model conversions for JSON compatibility
- Generating fake players and teams for testing
- General debugging help

### GitHub Copilot
- Used for function completion and suggestions during Dart file development
- Assisted with widget tree generation and logic structures in screens like `MatchTrackingScreen`, `MatchHistoryScreen`
- General debugging help

---

## References
### Tutorials
- The cross-platform development tutorials and lecture content were referenced during the development of this project to reinforce understanding of key concepts.

### Code Snippets
The code wasn’t copied verbatim from these sources, but they played an important role in shaping how features were implemented.

- **Countdown Timer in Flutter**  
  Implemented to manage live countdowns for match quarters in `MatchTrackingScreen`.  
  https://stackoverflow.com/questions/54610121/flutter-countdown-timer

- **Displaying AlertDialog with Buttons**  
  Used for confirming actions like ending a match or deleting a player, utilizing Flutter's `AlertDialog` widget.  
  https://stackoverflow.com/questions/53844052/how-to-make-an-alertdialog-in-flutter

- **Disabling DropdownButton Items**  
  Implemented logic to prevent selecting the same player in both dropdowns during comparisons by disabling selected options.  
  https://stackoverflow.com/questions/49693131/control-disable-a-dropdown-button-in-flutter

- **Using `share_plus` to Export Data**  
  Enabled sharing of match stats and action logs in plain text or JSON format.  
  https://pub.dev/packages/share_plus

- **`ImagePicker` for Selecting Player Photos**  
  Used in `PlayerManagementScreen` to let users choose images from gallery or camera.  
  https://pub.dev/packages/image_picker

- **Storing and Loading Files Using `path_provider`**  
  Used to persist player images on device and reload them across sessions.  
  https://stackoverflow.com/questions/71798042/flutter-how-do-i-write-a-file-to-local-directory-with-path-provider

- **Reading and Writing Nested Subcollections in Firestore**  
  Guided how match actions were stored inside match documents, under subcollections like `matchActions` and `players`.  
  https://firebase.flutter.dev/docs/firestore/usage/

- **Flutter Segmented Buttons for Team Switching**  
  Used to toggle between Team A and Team B in comparison views.  
  https://api.flutter.dev/flutter/material/SegmentedButton-class.html

### General Sources
These resources were used to better understand Flutter development, Firestore integration, and effective use of key libraries. They were essential in implementing features like state management, file handling, and dynamic UI elements.

- **Flutter Documentation**  
  Official guide for widgets, layout, navigation, and state management used across the app.  
  https://docs.flutter.dev

- **Dart Language Tour**  
  Helped with language-specific features like null safety, asynchronous programming, and collections.  
  https://dart.dev/guides/language/language-tour

- **Firebase Firestore Flutter Documentation**  
  Provided information on Firestore integration, document/subcollection structure, and CRUD operations.  
  https://firebase.flutter.dev/docs/firestore/overview/

- **State Management in Flutter with setState and StatefulWidget**  
  Guided the state logic across screens like `MatchTrackingScreen`, especially around quarter updates and player selection.  
  https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple

- **path_provider – Flutter Plugin**  
  Used for determining the local file paths where player images are saved.  
  https://pub.dev/packages/path_provider

- **image_picker – Flutter Plugin**  
  Used to allow users to select player images from gallery or camera.  
  https://pub.dev/packages/image_picker

- **share_plus – Flutter Plugin**  
  Enabled exporting match stats and action logs via the native share sheet.  
  https://pub.dev/packages/share_plus

- **SegmentedButton – Flutter Widget**  
  Used to toggle between teams or players in comparison views.  
  https://api.flutter.dev/flutter/material/SegmentedButton-class.html

- **File I/O in Dart**  
  Assisted with reading and writing image files to local storage for player photo persistence.  
  https://dart.dev/tutorials/server/file-io

---

### Third-Party Packages Used

The following Flutter plugins were used in this project to extend the app’s functionality. All packages were sourced from [pub.dev](https://pub.dev):

| Package Name      | Purpose                                                                 |
|-------------------|-------------------------------------------------------------------------|
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | Used to interact with Firestore for storing and retrieving all match, team, player, and action data. |
| [`firebase_core`](https://pub.dev/packages/firebase_core)     | Required to initialize Firebase in your Flutter app.                    |
| [`image_picker`](https://pub.dev/packages/image_picker)       | Used to let users select player profile photos from camera or gallery.  |
| [`path_provider`](https://pub.dev/packages/path_provider)     | Used to store and retrieve image files locally on the device.           |
| [`share_plus`](https://pub.dev/packages/share_plus)           | Used to export match stats and logs via the native share dialog.        |

---

## Files and Screens Overview

### Dart Models

- **`PlayerModel`**  
  Represents individual players. Contains the player's name, number, team ID (`teamId`), action counts (kick, mark, tackle, etc.), and an `imageUri` pointing to a locally stored photo.  
  **Relationships:**  
  - Linked to a team via `teamId` (from `TeamModel`)  
  - Referenced in matches under the `matchData/{matchId}/players` subcollection  
  - Each player document may have a nested `actions` subcollection for per-action history

- **`TeamModel`**  
  Stores metadata for a team, including its `name` and the `createdAt` timestamp.  
  **Relationships:**  
  - Teams are referenced by matches (`teamA`, `teamB`)  
  - Used to group players logically via `teamId`  
  - Managed through the `teamData` collection

- **`MatchModel`**  
  Represents a match in progress or completed. Tracks team matchups (`teamA`, `teamB`), current quarter, start and finish timestamps, and match status (`in_progress` or `finished`).  
  **Relationships:**  
  - Contains subcollections for `players` (with summary stats) and `matchActions` (global list of actions)  
  - Actions and player stats are scoped within the match context

- **`ActionModel`**  
  Represents a single in-game event (e.g., a kick or tackle), capturing action type, timestamp, quarter, team, and player.  
  **Relationships:**  
  - Logged globally in the `matchData/{matchId}/matchActions` subcollection  
  - Also saved inside each relevant player document in the `actions` subcollection

### UI Screens

- **`MainMenuScreen`**  
  Acts as the entry point for the app. Provides navigation buttons to manage teams, start a new match, and view match history.

- **`TeamManagementScreen`**  
  Allows users to create, rename, or delete teams. Each team shows a count of its players. Swiping allows editing or removal.

- **`PlayerManagementScreen`**  
  Displays and manages players within a selected team. Players can be added, edited, deleted, or have images assigned.  
  **Note:** Player photos are stored locally and their paths are saved via the `imageUri` in `PlayerModel`.

- **`CreateMatchScreen`**  
  Provides a setup UI to select two teams (Team A and Team B) and begin a new match. Ensures teams are distinct and have players.

- **`MatchTrackingScreen`**  
  Core gameplay interface for recording in-game actions.  
  Includes:  
  - Action buttons (Kick, Handball, Mark, etc.)  
  - A segmented team/player selector  
  - Real-time match and quarter timers  
  - Quarter-end and match-finish logic

- **`MatchHistoryScreen`**  
  Shows past matches with summary information, score breakdowns, and a list of all actions. Includes buttons to navigate to player and team comparison views.  
  Supports sharing match data as raw text or JSON.

- **`PlayerStatsScreen`**  
  Enables a side-by-side comparison of two players. Highlights which player had more of each action type.  
  Also displays MVP (most valuable player) from the selected match based on stat totals.

- **`TeamStatsScreen`**  
  Compares both teams’ aggregate stats (disposals, marks, tackles, goals, behinds).  
  Displays AFL-style score comparison and supports quarter filtering using a segmented control.

### firestore_service.dart

This file acts as the primary interface between the Flutter application and Firebase Firestore. It contains all asynchronous methods required to:

- Create, read, update, and delete documents from the Firestore database.
- Handle team and player data under `teamData` and `players` collections respectively.
- Manage match documents in the `matchData` collection, including:
  - Adding match-level metadata (e.g. start time, status).
  - Adding actions to the nested `matchActions` subcollection.
  - Updating per-player stats under `matchData/{matchId}/players/{playerName}`.
  - Storing individual player actions under `matchData/{matchId}/players/{playerName}/actions`.

It plays a central role in abstracting Firestore operations away from the UI, ensuring the screens remain clean and focused on state/display logic. This structure allows for consistent, reusable backend interactions across the app's screens like `TeamManagementScreen`, `MatchTrackingScreen`, and `PlayerStatsScreen`.

---

## Notes

- This app was developed using **Android Studio** on Windows.
- Images are stored locally and linked via URI.
- All match and player data is uploaded to Firebase Firestore.
- Actions are recorded in three places to support different analytics views.
- Quarters auto-complete after 20 mins unless manually ended.
- The app is designed for phones but can scale to tablets with flexible layout widgets all be it unreliably.
- GitHub Desktop was used for version control during development.
