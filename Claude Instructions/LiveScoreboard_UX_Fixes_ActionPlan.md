# Live Scoreboard for macOS — UX Fixes Action Plan (Claude Code)

## Overview

This plan addresses usability issues found during hands-on testing. Every change here is about making the app intuitive for a first-time operator under the time pressure of a live event. These fixes assume the Phase 1 foundation work from the previous action plan is already complete (stable UUIDs, data provider protocol, local scoring interface, sidebar settings).

---

## CMUX Agent Strategy

Use **CMUX to deploy agents** for parallelizable work. Tasks are grouped into waves — complete each wave before starting the next.

**Wave 1** contains three small, independent fixes that touch different files and can run as parallel agents. **Wave 2** is a single medium-complexity task. **Wave 3** contains two tightly coupled features that should be built together by a single agent (or two closely coordinated agents).

---

## Testing Protocol

**After every task:**
1. Build the project — zero compiler errors
2. Run the specific verification steps listed under each task
3. Confirm no regressions in existing functionality

**After every wave:**
1. Full clean build
2. Smoke test checklist (provided per wave)
3. Test the full operator workflow end-to-end: launch → setup → score → output → quit → relaunch

---

## Wave 1: Quick Wins (Parallel)

> Three small, isolated changes that touch different areas of the codebase. Deploy as three CMUX agents simultaneously.

### Task 1 — Default to Local/Manual Mode

**Files:** `AppSettings.swift`
**Effort:** Tiny — a few line changes

**Changes:**

1. Reorder the `DataSourceMode` enum so `localManual` is the first case:
```swift
enum DataSourceMode: String, Codable, CaseIterable {
    case localManual = "local-manual"
    case googleSheets = "google-sheets"
    case csvFile = "csv-file"
}
```
This changes the order in `CaseIterable` iteration, which drives the segmented picker in ContentView. Local Manual will now appear first.

2. Change the default value for `dataSourceMode`:
```swift
@Published var dataSourceMode: DataSourceMode = .localManual
```

3. Change the decoder fallback to match:
```swift
dataSourceMode = (try? c.decode(DataSourceMode.self, forKey: .dataSourceMode)) ?? .localManual
```

**Test:**
- Delete the app's saved preferences (remove the UserDefaults plist)
- Launch the app fresh
- Confirm it opens in Local Manual mode, not Google Sheets
- Confirm the segmented picker shows Local Manual first (leftmost)
- Confirm existing users who saved Google Sheets as their mode still load into Google Sheets (backward compat)

---

### Task 2 — Move Sync Status Off the Broadcast Output

**Files:** `ScoreboardView.swift`, `ContentView.swift`, `OutputWindowView.swift`, `AdminPanelView.swift`
**Effort:** Small

**Changes:**

1. Add a `showSyncOverlay` parameter to `ScoreboardView`:
```swift
struct ScoreboardView: View {
    // ... existing params
    var showSyncOverlay: Bool = true
```

2. In the footer section of `ScoreboardView`, conditionally render the sync status:
```swift
if settings.showSyncStatus && showSyncOverlay {
    syncStatusView
}
```

3. Pass the parameter in each context:
   - `ContentView.swift` (operator preview): `ScoreboardView(..., showSyncOverlay: true)` — or just use the default
   - `OutputWindowView.swift` (broadcast output): `ScoreboardView(..., showSyncOverlay: false)`

4. In local/manual mode, hide the sync status entirely (there's nothing to sync). The existing status bar in `ContentView` already shows the data source mode — that's sufficient.

5. In `AdminPanelView.swift`, hide or disable the sync status settings when the data source is local/manual. Add a note like "Sync status is only available in Google Sheets mode."

**Test:**
- Set data source to Google Sheets
- Open the output window / Show Mode
- Confirm the sync status indicator appears in the operator preview but NOT on the output window
- Switch to Local Manual mode
- Confirm no sync status appears anywhere
- Confirm the sync settings are hidden/disabled in the admin panel when in Local Manual mode

---

### Task 3 — Enable Native Fullscreen for Output Window

**Files:** `LiveScoreboardApp.swift`, `OutputWindowView.swift`
**Effort:** Small

**Changes:**

1. In `LiveScoreboardApp.swift` (around lines 64–81), modify the output window configuration:
   - Remove `.windowStyle(.hiddenTitleBar)` — replace with `.windowStyle(.automatic)` so the title bar (and green fullscreen button) appears
   - Change `.windowResizability(.contentSize)` to `.windowResizability(.automatic)` so the window can be freely resized and go fullscreen
   - Set the window title to `"Scoreboard Output"` — visible in the title bar and in Mission Control

2. In `OutputWindowView.swift`, add Escape key handling:
```swift
.onExitCommand {
    showModeState.isActive = false
}
```
Or use `.onKeyPress(.escape)` if more control is needed. The handler should exit fullscreen or close the output window, communicating back to `ShowModeState`.

3. The title bar will auto-hide in native macOS fullscreen mode — this is exactly the desired behavior. The operator gets the green button to enter fullscreen and Escape to exit, which is the standard macOS pattern everyone already knows.

**Test:**
- Open the output window
- Confirm it has a title bar with the green fullscreen button
- Click the green button — confirm the window goes native fullscreen (title bar hides)
- Press Escape — confirm the window exits fullscreen
- Check Mission Control — confirm the window is labeled "Scoreboard Output"
- Confirm the scoreboard content renders correctly in both windowed and fullscreen states

---

### Wave 1 Smoke Test Checklist
- [ ] Clean build, zero errors
- [ ] App defaults to Local Manual on fresh install
- [ ] Data source picker shows Local Manual first
- [ ] Existing saved preferences still load correctly
- [ ] Sync status visible to operator only, hidden from output
- [ ] Sync settings hidden in admin panel during Local Manual mode
- [ ] Output window has native fullscreen support (green button + Escape)
- [ ] Output window shows "Scoreboard Output" in title bar and Mission Control

---

## Wave 2: Preview Scaling

> Single task, medium complexity. One CMUX agent.

### Task 4 — Fix Scoreboard Preview Scaling

**Files:** `ContentView.swift` (primary), possibly a new wrapper view
**Effort:** Medium

**Problem:** The preview uses `.aspectRatio(outputAspectRatio, contentMode: .fit)` which causes the scoreboard to render at the container's size with aspect ratio constraints. This makes fonts, spacing, and proportions look different from the actual output. A broadcast preview monitor shows the exact output, just smaller — we need to replicate that.

**Solution — Render at full resolution, then scale down:**

The key idea: render the `ScoreboardView` at the actual output resolution (e.g., 1920×1080), then apply a uniform `scaleEffect` to shrink it into the available preview space.

```swift
// Wrap the preview ScoreboardView in ContentView:
GeometryReader { geo in
    let scaleX = geo.size.width / CGFloat(settings.outputWidth)
    let scaleY = geo.size.height / CGFloat(settings.outputHeight)
    let previewScale = min(scaleX, scaleY)

    ScoreboardView(...)
        .frame(width: CGFloat(settings.outputWidth),
               height: CGFloat(settings.outputHeight))
        .scaleEffect(previewScale)
        .frame(width: geo.size.width, height: geo.size.height)
}
```

**Apply this approach in every preview context:**
- Local Manual mode: the preview pane next to the scoring controller
- Google Sheets mode: the confidence monitor / preview area
- Any other context where ScoreboardView is shown as a preview

**Add a visual label:**
- Small "PREVIEW" text in the corner of the preview area (outside the scaled scoreboard, in the surrounding chrome) so operators know this is a miniature replica

**Test:**
- Set output resolution to 1920×1080
- Open the preview alongside the scoring controller
- Compare the preview against the actual output window — fonts, spacing, row heights, and overall proportions should be pixel-identical (just smaller)
- Resize the main window — confirm the preview scales smoothly without distortion
- Change output resolution to 3840×2160 — confirm the preview still matches
- Change to a non-16:9 resolution like 1920×1200 — confirm the preview adapts correctly and shows the right aspect ratio

---

### Wave 2 Smoke Test Checklist
- [ ] Clean build
- [ ] Preview exactly matches output at 1920×1080
- [ ] Preview exactly matches output at 3840×2160
- [ ] Preview exactly matches output at non-16:9 resolutions
- [ ] Preview scales smoothly when the window is resized
- [ ] "PREVIEW" label visible in the preview area
- [ ] Both Local Manual and Google Sheets mode previews use the new scaling
- [ ] All Wave 1 features still work (regression check)

---

## Wave 3: Startup Flow & Setup Wizard

> Two tightly coupled features. Build together — the startup screen's "New Session" button launches the wizard, so they share navigation state. Use a single CMUX agent, or two agents working on a shared branch with frequent syncs.

### Task 5 — Startup Screen with Session Management

**New file:** `Views/StartupView.swift`
**Modified files:** `ContentView.swift`, `LocalGameState.swift`, `LiveScoreboardApp.swift`
**Effort:** Medium-Large

**Startup screen layout:**

Three options presented as large, clear cards:

1. **New Session** — "Start a fresh game setup"
   - Launches the Game Setup Wizard (Task 6)
   - After the wizard completes, transitions to the main operator view

2. **Resume Previous Session** — Only shown if a saved session exists
   - Shows session name, round/team count, and last saved timestamp
   - Example: `"Corporate Trivia Night" — 4 rounds, 8 teams — Last saved: Mar 16, 2:30 PM`
   - Loads the saved game state and goes directly to the scoring controller

3. **Load From File** — "Import a saved game file"
   - Opens a macOS file picker
   - Loads the selected game file and transitions to the scoring controller

**State management:**
- Add startup state tracking — show `StartupView` when the app launches, show the main operator UI after a choice is made
- Use `@State private var hasCompletedStartup: Bool = false` in `ContentView` or manage at the `App` level
- On every launch, show the startup screen (do NOT auto-resume)
- Add a user preference: "Always resume previous session" that skips the startup screen for operators who want that workflow

**Session metadata:**
- When saving game state, also write a small metadata sidecar:
```json
{
    "name": "Corporate Trivia Night",
    "numRounds": 4,
    "numTeams": 8,
    "lastSaved": "2026-03-16T14:30:00Z"
}
```
- Save to `~/Documents/LiveScoreboard/session_meta.json`
- The startup screen reads this metadata to display the session summary without loading the full game state
- Ensure backward compatibility: if no metadata file exists but a game state file does, show "Resume Previous Session" with a generic description like "Saved session found"

**Test:**
- Launch the app fresh (no saved state) — confirm only "New Session" and "Load From File" appear (no "Resume" option)
- Create a game, score some rounds, quit the app
- Relaunch — confirm "Resume Previous Session" appears with the correct session name, round count, team count, and timestamp
- Click Resume — confirm the game loads with all scores intact
- Quit and relaunch again — confirm the startup screen appears again (not auto-resumed)
- Enable "Always resume previous session" preference — confirm the app skips startup and goes straight to the scoring controller
- Test "Load From File" with a saved game export

---

### Task 6 — Game Setup Wizard

**New file:** `Views/GameSetupWizard.swift`
**Modified files:** `LocalScoringView.swift`, `ContentView.swift`
**Effort:** Medium-Large

**Wizard steps:**

**Step 1: Event Info**
- Event/game name field (optional, used for save file naming and startup screen display)
- Number of rounds: visual stepper, range 1–10
- Helper text: "How many scoring rounds will this event have?"

**Step 2: Round Configuration**
- Table/list showing each round with two fields:
  - Points per correct answer (default 10)
  - Bonus points available (default 25)
- "Apply to All" button — sets all rounds to the same values as Round 1. This is the common case and saves time.
- Allow editing individual rounds for events with escalating point values

**Step 3: Teams**
- Two input methods:
  - Individual entry: text field + "Add" button
  - Bulk paste: large text area where you paste team names one per line
- Live count displayed: "8 teams added"
- Drag-to-reorder support
- Delete button per team (with confirmation if game has started)
- Minimum 2 teams required to proceed

**Step 4: Confirm & Start**
- Full summary of the game setup:
  - Event name
  - Number of rounds with their point values
  - List of all teams
- "Start Game" button — creates the game state and transitions to the scoring controller
- "Back" button on every step to return to the previous step without losing data

**Navigation and integration:**
- The wizard is presented when:
  - User clicks "New Session" on the startup screen
  - User clicks "New Game" from the scoring controller toolbar
  - App detects no saved game on absolute first launch (no saved state, no metadata)
- Remove the current `gameSetupSheet` modal from `LocalScoringView.swift`
- Keep a simplified "Edit Game" option accessible from the scoring controller for mid-game adjustments (add/remove a team, tweak round config) — this should NOT be the full wizard, just quick-edit fields

**Data flow:**
- The wizard produces a complete game configuration object
- This config is passed to `LocalGameState` to initialize a new game
- The previous session's data is NOT overwritten until "Start Game" is confirmed — if the user cancels the wizard, the old session remains intact

**Test:**
- Click "New Session" from startup screen — confirm wizard appears at Step 1
- Fill in all steps, click Start Game — confirm the scoring controller opens with the correct number of rounds, point values, and teams
- Click Back on Step 3 — confirm Step 2 still has the values you entered
- Close the wizard without completing it — confirm the previous session is not affected
- Start a game, then click "New Game" from the scoring controller — confirm the wizard appears and completing it replaces the old game
- Test bulk paste: copy 10 team names from a text file, paste into the teams step — confirm all 10 appear
- Test the "Apply to All" button: change Round 1 to 50 points, click Apply to All, confirm all rounds update
- Test with edge cases: 1 round, 2 teams (minimum) and 10 rounds, 20+ teams

---

### Wave 3 Smoke Test Checklist
- [ ] Clean build
- [ ] Startup screen appears on every launch
- [ ] "Resume Previous Session" only appears when a saved session exists
- [ ] Session metadata displays correct name, rounds, teams, and timestamp
- [ ] Resume loads the complete game state with all scores
- [ ] "Always resume" preference works and can be toggled back
- [ ] Setup wizard walks through all 4 steps cleanly
- [ ] Back navigation preserves entered data
- [ ] Canceling the wizard does not affect the existing session
- [ ] Bulk team paste works (one name per line)
- [ ] "Apply to All" sets all rounds to Round 1's values
- [ ] Starting a new game from the scoring controller replaces the old session
- [ ] "Edit Game" in the scoring controller allows mid-game adjustments without the full wizard
- [ ] All Wave 1 + Wave 2 features still work (regression check)

---

## CMUX Parallelization Summary

| Wave | Agents | Tasks | Dependencies |
|------|--------|-------|-------------|
| **Wave 1** | 3 parallel agents | Task 1 (default mode), Task 2 (sync status), Task 3 (fullscreen) | None — all touch different files |
| **Wave 2** | 1 agent | Task 4 (preview scaling) | Depends on output window existing (Wave 1 Task 3 should be done) |
| **Wave 3** | 1 agent (or 2 tightly coordinated) | Task 5 (startup screen) + Task 6 (setup wizard) | Tightly coupled — startup screen launches the wizard. Build together. |

---

## Important Notes

- **Backward compatibility:** All changes must preserve existing saved settings and game state files. If the data format changes, handle migration gracefully (detect old format, convert on load).
- **The preview scaling fix (Task 4) is the single most impactful visual improvement.** It immediately makes the app feel trustworthy for operators. Prioritize getting this right.
- **The setup wizard (Task 6) replaces the existing gameSetupSheet.** Make sure to fully remove the old flow after the wizard is working — don't leave two ways to set up a game.
- **"Don't show on startup" preference** should default to OFF. The startup screen is a safety net against accidentally overwriting a live event. Only experienced operators who understand the risk should disable it.
