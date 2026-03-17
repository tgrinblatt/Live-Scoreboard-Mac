# Claude Review 2 — UX Fixes & Improvements

Based on hands-on analysis of the app's current behavior. These changes address usability issues found during testing, focused on making the app feel intuitive for a first-time operator.

---

## 1. Redesign the Game Setup Flow

**Problem:** The current setup is buried behind a small gear icon in the scoring controller. Adding teams requires a modal sheet with two disconnected steps (rounds, then teams). On app reload, it's unclear whether the previous game loaded or not. There's no guided flow.

**Solution — Replace with a Step-by-Step Setup Wizard:**

Create a new `GameSetupWizard` view that replaces the current sheet-based setup. It should be a multi-step guided flow:

**Step 1: Event Info**
- Event/game name (optional, used for save file naming)
- Number of rounds (1-10, with a visual stepper)
- Clear explanation: "How many scoring rounds will this event have?"

**Step 2: Round Configuration**
- For each round, set:
  - Points per correct answer (default 10)
  - Bonus points available (default 25)
- Show all rounds in a clean table/list
- Allow "Apply to All" button for when all rounds have the same values

**Step 3: Teams**
- Large text area or list for entering team names
- Support pasting multiple names (one per line) for fast bulk entry
- Show a live count: "8 teams added"
- Allow reordering via drag

**Step 4: Confirm & Start**
- Summary of the game setup
- "Start Game" button that transitions to the scoring controller

**Implementation:**
- New file: `Views/GameSetupWizard.swift`
- The wizard should be presented when:
  - User clicks "New Session" on the startup screen (see item 6)
  - User clicks "New Game" from the scoring controller
  - The app detects no saved game on first launch
- Remove the current `gameSetupSheet` from `LocalScoringView.swift`
- Keep a simplified "Edit Game" option in the scoring controller for mid-game adjustments (add/remove a team, change round config)

**Why this matters:** At a live event, setup happens once under time pressure. The wizard ensures nothing is missed and the operator can see everything at a glance before going live.

---

## 2. Fix Scoreboard Preview Scaling

**Problem:** In local/manual mode, the scoreboard preview sits inside an HSplitView next to the scoring controller. The `ScoreboardView` uses `.aspectRatio(outputAspectRatio, contentMode: .fit)` which causes it to letterbox/pillarbox in the available space, making it look nothing like what the actual output shows. Font sizes, spacing, and proportions all appear different.

**Solution — True Scaled Preview:**

The preview should render the scoreboard at the full output resolution internally, then scale the entire thing down to fit the available space. This is how broadcast preview monitors work — they show the exact output, just smaller.

**Implementation approach:**
```swift
// In ContentView, wrap the preview ScoreboardView:
ScoreboardView(...)
    .frame(width: CGFloat(settings.outputWidth),
           height: CGFloat(settings.outputHeight))
    .scaleEffect(previewScale)  // calculated to fit container
    .frame(width: containerWidth, height: containerHeight)
```

Where `previewScale` is:
```swift
let scaleX = containerWidth / CGFloat(settings.outputWidth)
let scaleY = containerHeight / CGFloat(settings.outputHeight)
let previewScale = min(scaleX, scaleY)
```

This renders the scoreboard at exactly 1920x1080 (or whatever the output resolution is), then uniformly scales it down to fit the preview area. Every pixel, font size, and spacing will match the output exactly.

**File changes:**
- `ContentView.swift`: Wrap the ScoreboardView in local manual mode with a GeometryReader that calculates the scale factor
- The same approach should be used for the confidence monitor preview in the Google Sheets mode
- Add a "Preview" label in the corner so operators know this is a scaled replica

**Why this matters:** The operator needs to trust that what they see in the preview is exactly what the audience sees. If fonts look bigger or spacing looks off in the preview, they'll make bad adjustments.

---

## 3. Enable Native Fullscreen for Output Window

**Problem:** The output window uses `.windowStyle(.hiddenTitleBar)` and `.windowResizability(.contentSize)`, which removes the green fullscreen button and prevents native macOS fullscreen. There's also no Escape key handler to exit.

**Solution:**

**For the output window in LiveScoreboardApp.swift:**
- Remove `.windowStyle(.hiddenTitleBar)` — or replace with `.windowStyle(.automatic)` so the title bar (and green fullscreen button) appears
- Change `.windowResizability(.contentSize)` to `.windowResizability(.automatic)` so the window can be freely resized and go fullscreen
- The title bar will auto-hide in native fullscreen mode, which is exactly the behavior wanted

**For Escape key handling in OutputWindowView.swift:**
- Add an `.onExitCommand` modifier (SwiftUI's built-in Escape handler):
```swift
.onExitCommand {
    // Exit fullscreen or close the output window
    showModeState.isActive = false
}
```
- Alternatively, use `.onKeyPress(.escape)` for more control

**For the window title:**
- Set the window title to something like "Scoreboard Output" — it will be visible in the title bar when not fullscreen, and hidden when in fullscreen mode
- This also helps the operator identify the window in Mission Control

**File changes:**
- `LiveScoreboardApp.swift`: Lines 64-81 — modify window configuration
- `OutputWindowView.swift`: Add escape key handler and communicate back to ShowModeState

**Why this matters:** At a live event, the operator needs to quickly fullscreen the output on the projector/display and just as quickly exit if something goes wrong. The native macOS fullscreen flow (green button to enter, Escape to exit) is what every Mac user already knows.

---

## 4. Move Sync Status Off the Scoreboard

**Problem:** The sync status indicator (time, heartbeat countdown, connection dot) renders in the scoreboard's footer area. This means it appears on the broadcast output — visible to the audience. It should only be visible to the operator.

**Solution:**

**Add a `showSyncOverlay` parameter to ScoreboardView:**
```swift
struct ScoreboardView: View {
    // ... existing params
    var showSyncOverlay: Bool = true  // default true for operator, false for output
```

In the footer section, conditionally render:
```swift
if settings.showSyncStatus && showSyncOverlay {
    syncStatusView
}
```

**Pass the parameter differently in each context:**
- `ContentView.swift` (operator preview): `ScoreboardView(..., showSyncOverlay: true)`
- `OutputWindowView.swift` (broadcast output): `ScoreboardView(..., showSyncOverlay: false)`

**For local/manual mode:**
- Don't show the sync status at all (there's nothing to sync)
- The status bar at the bottom of ContentView already shows the data source mode
- The sync status settings in the admin panel should be hidden when in local/manual mode, or clearly labeled "Google Sheets Only"

**Move the operator-relevant status info to the status bar:**
- The existing status bar in ContentView already shows "Last: HH:MM:SS" and "Next: Xs" for Google Sheets mode
- This is the right place for sync info — it's on the operator's UI, not the broadcast

**File changes:**
- `ScoreboardView.swift`: Add `showSyncOverlay` parameter, conditionally render
- `ContentView.swift`: Pass `showSyncOverlay: true` (or just leave default)
- `OutputWindowView.swift`: Pass `showSyncOverlay: false`
- `AdminPanelView.swift`: Hide sync status settings when in local/manual mode

---

## 5. Make Local/Manual the Default Data Source

**Problem:** The app defaults to Google Sheets mode, which shows "Source Disconnected" on first launch. Since the primary use case is local scoring at events, local/manual should be the default.

**Solution:**

In `AppSettings.swift`, change two lines:

```swift
// Line 9: Change initial default
@Published var dataSourceMode: DataSourceMode = .localManual

// Line 158: Change decoder fallback
dataSourceMode = (try? c.decode(DataSourceMode.self, forKey: .dataSourceMode)) ?? .localManual
```

**Additionally, reorder the data source picker in ContentView.swift:**
- Current order: Google Sheets | Local Manual | CSV File
- New order: Local Manual | Google Sheets | CSV File
- This puts the primary mode first, matching the mental model

**Reorder the enum cases in AppSettings.swift:**
```swift
enum DataSourceMode: String, Codable, CaseIterable {
    case localManual = "local-manual"
    case googleSheets = "google-sheets"
    case csvFile = "csv-file"
}
```

This changes the order in `CaseIterable` iteration, which is used by the segmented picker.

**File changes:**
- `AppSettings.swift`: Default value + enum case ordering
- No changes needed in ContentView since it iterates `allCases`

---

## 6. Add Startup Screen with Session Management

**Problem:** The app silently loads whatever state it had before, or shows an empty state with no guidance. The operator doesn't know if they're working with yesterday's data or a fresh session.

**Solution — Create a Startup/Welcome Screen:**

New file: `Views/StartupView.swift`

The startup screen appears when the app launches and shows:

```
┌──────────────────────────────────────────┐
│                                          │
│         Live Scoreboard                  │
│                                          │
│   ┌──────────────────────────────────┐   │
│   │                                  │   │
│   │  ▶  New Session                  │   │
│   │     Start a fresh game setup     │   │
│   │                                  │   │
│   └──────────────────────────────────┘   │
│                                          │
│   ┌──────────────────────────────────┐   │
│   │                                  │   │
│   │  ↻  Resume Previous Session     │   │
│   │     "Corporate Trivia Night"     │   │
│   │     4 rounds, 8 teams            │   │
│   │     Last saved: Mar 16, 2:30 PM  │   │
│   │                                  │   │
│   └──────────────────────────────────┘   │
│                                          │
│   ┌──────────────────────────────────┐   │
│   │                                  │   │
│   │  📄 Load From File              │   │
│   │     Import a saved game file     │   │
│   │                                  │   │
│   └──────────────────────────────────┘   │
│                                          │
└──────────────────────────────────────────┘
```

**Behavior:**
- **New Session**: Opens the Game Setup Wizard (from item 1), then transitions to the main operator view
- **Resume Previous**: Loads the saved game state and goes directly to the scoring controller. Only shown if a save file exists.
- **Load From File**: Opens a file picker to load an exported game file

**State management:**
- Add `@State private var hasCompletedStartup: Bool = false` to ContentView (or a parent view)
- Show StartupView when `!hasCompletedStartup`
- Show the main operator UI when `hasCompletedStartup`
- The startup screen should NOT appear if the user explicitly chose "Resume" — on next launch, show the startup screen again

**Session metadata:**
- Save a small metadata file alongside the game state:
  ```json
  {
    "name": "Corporate Trivia Night",
    "numRounds": 4,
    "numTeams": 8,
    "lastSaved": "2026-03-16T14:30:00Z"
  }
  ```
- This lets the startup screen show a meaningful summary without loading the full game state

**File changes:**
- New file: `Views/StartupView.swift`
- New file: `Views/GameSetupWizard.swift` (from item 1)
- `ContentView.swift`: Add startup state management
- `LocalGameState.swift`: Add metadata save/load, add session name field
- `LiveScoreboardApp.swift`: May need to manage startup state at app level

**Why this matters:** At a multi-day event, the operator opens the app in the morning and needs to immediately know: "Am I continuing yesterday's game or starting fresh?" This prevents the dangerous scenario of accidentally overwriting an in-progress event.

---

## Implementation Order

These changes are interconnected. Recommended order:

1. **Item 5** (default to local/manual) — One-line change, do first
2. **Item 4** (move sync status) — Small, isolated change
3. **Item 3** (fullscreen output) — Small, isolated change
4. **Item 2** (preview scaling) — Medium change, improves daily usability
5. **Item 6** (startup screen) — New view, depends on understanding the flow
6. **Item 1** (setup wizard) — Largest change, builds on the startup screen

Items 1 and 6 are tightly coupled — the startup screen's "New Session" button should launch the setup wizard. Build them together.

---

## Notes

- All changes should preserve backward compatibility with existing saved settings and game state
- The startup screen should be skippable via a "Don't show on startup" preference (for operators who always resume)
- The setup wizard should allow going back to previous steps without losing entered data
- The preview scaling solution (item 2) is the most impactful visual fix — it will immediately make the app feel more professional and trustworthy for operators
