# Live Scoreboard — Game Setup Rework (Claude Code Task List)

## Context

The Game Setup Wizard currently has too many steps and the output window doesn't behave like a proper broadcast tool. This task list fixes three specific issues. Use CMUX agents where noted. Test after each task — build, verify, confirm no regressions.

---

## Task 1 — Combine Event Info + Round Configuration Into One Step

**Files:** `Views/GameSetupWizard.swift`
**CMUX:** Can run in parallel with Task 3

The current wizard has separate steps for event info (name, number of rounds) and round configuration (point values per round). These should be a single step. The operator sets up the event and configures rounds on one screen without clicking "Next" in between.

**Layout for the combined step:**

```
┌─────────────────────────────────────────────────────┐
│  GAME SETUP                                         │
│                                                     │
│  Event Name   [ Corporate Trivia Night         ]    │
│                                                     │
│  Rounds  [ - ]  4  [ + ]                            │
│                                                     │
│  ┌───────────┬──────────────────┬────────────────┐  │
│  │  Round    │  Points/Answer   │  Bonus Points  │  │
│  ├───────────┼──────────────────┼────────────────┤  │
│  │  Round 1  │  [10]            │  [25]          │  │
│  │  Round 2  │  [10]            │  [25]          │  │
│  │  Round 3  │  [10]            │  [25]          │  │
│  │  Round 4  │  [10]            │  [25]          │  │
│  └───────────┴──────────────────┴────────────────┘  │
│                                                     │
│  [ Apply Round 1 Values to All ]                    │
│                                                     │
│                                    [ Next: Teams ]  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Behavior:**
- When the round count changes via the stepper, rows in the table instantly add or remove to match
- "Apply Round 1 Values to All" copies Round 1's points and bonus values to every other round — this is the fast path for events where all rounds are scored the same
- Individual round values are still editable for events with escalating scoring (e.g., Round 1 = 10 pts, Final Round = 50 pts)
- Event name is optional — if left blank, the save file uses a timestamp-based name

**The wizard now has 3 steps total instead of 4:**
1. Event Info + Rounds (this task)
2. Teams
3. Confirm & Start

**Test:**
- Open the wizard — confirm event info and round config appear on a single screen
- Set 6 rounds — confirm 6 rows appear in the table
- Reduce to 3 rounds — confirm rows 4–6 disappear
- Set Round 1 to 50 pts / 100 bonus, click "Apply to All" — confirm all rounds update
- Edit Round 3 individually after applying to all — confirm only Round 3 changes
- Leave event name blank, proceed through the wizard — confirm it still works

---

## Task 2 — Auto-Populate Scoreboard After Setup

**Files:** `Views/GameSetupWizard.swift`, `LocalGameState.swift`, `ContentView.swift`, `ScoreboardView.swift`
**CMUX:** Run after Task 1 (depends on the wizard producing the final game config)

When the operator finishes the setup wizard and clicks "Start Game," the teams and round structure should immediately appear on the scoreboard output. The operator should not have to manually push anything — the board is live and populated the moment setup completes.

**What "auto-populate" means:**
- All team names appear on the scoreboard in the order they were entered during setup
- All scores start at 0
- The round columns (if the scoreboard layout shows per-round scores) reflect the number of rounds configured
- The scoreboard title updates to the event name (if one was entered)
- If the output window / Show Mode is already active, it updates immediately
- If the output window is not yet open, the preview in the operator window shows the populated board

**Implementation:**
- When the wizard's "Start Game" action fires, it should:
  1. Create the full `LocalGameState` with all teams, rounds, and zero scores
  2. Set this as the active game state
  3. The scoreboard view is already bound to this state — it should reactively display the new data with no additional "push" step
- Remove any manual "push to scoreboard" gate that exists between setup completion and initial board display
- The Push/Live toggle in the scoring controller is for *score changes during gameplay* — it should NOT gate the initial population of team names and round structure after setup

**Edge case — Manual Push mode:**
- If the operator has Manual Push mode enabled, the initial setup should still auto-populate immediately. Manual Push only applies to score changes made after the game is running, not to the initial board state.
- After the board is populated, subsequent score edits in Manual Push mode should stage as before and require the Push button.

**Test:**
- Complete the setup wizard with 6 teams and 4 rounds
- Confirm the scoreboard preview immediately shows all 6 team names with 0 scores — no extra button clicks required
- Open the output window — confirm it also shows the populated board
- Enable Manual Push mode, then start a new game via the wizard — confirm the board still auto-populates with teams and zeros
- In Manual Push mode, change a team's score — confirm THIS change stages and requires the Push button (the push gate applies to score edits, not initial setup)

---

## Task 3 — Native macOS Fullscreen for Output Window

**Files:** `LiveScoreboardApp.swift`, `OutputWindowView.swift`
**CMUX:** Can run in parallel with Task 1

The output window needs to work like Keynote's presentation mode or Safari's fullscreen — the content fills the entire screen, the menu bar and dock hide, and Escape exits. Right now the window uses `.hiddenTitleBar` and `.contentSize` resizability, which prevents native macOS fullscreen entirely.

**Changes to `LiveScoreboardApp.swift`:**
- Remove `.windowStyle(.hiddenTitleBar)`
- Replace with `.windowStyle(.automatic)` — this gives the window a standard title bar with the traffic light buttons (including the green fullscreen button)
- Change `.windowResizability(.contentSize)` to `.windowResizability(.automatic)` — this allows the window to be freely resized and to enter native fullscreen
- Set the window title to `"Scoreboard Output"` so the operator can identify it in Mission Control and the Dock

**How native macOS fullscreen works (and why this is the right approach):**
- The green traffic light button (or `Ctrl+Cmd+F`) enters fullscreen
- In fullscreen, macOS automatically hides the title bar, menu bar, and dock — the scoreboard content fills the entire screen edge to edge
- The title bar reappears when the cursor moves to the top of the screen (standard macOS behavior), letting the operator access the green button to exit
- Escape also exits fullscreen
- This is identical to how Keynote and Safari handle fullscreen — operators already know this interaction

**Changes to `OutputWindowView.swift`:**
- Add Escape key handling:
```swift
.onExitCommand {
    // Exit fullscreen or close the output window
    showModeState.isActive = false
}
```
- Make sure the scoreboard content fills the entire window frame — no internal padding or margins that would leave a visible border in fullscreen
- The background color of the window itself (not just the scoreboard view) should match the scoreboard's background color so there are no mismatched edges during transitions or at non-standard aspect ratios

**What NOT to do:**
- Do not build a custom fullscreen implementation — use the native macOS fullscreen system
- Do not hide the title bar permanently — the operator needs the traffic light buttons to control the window
- Do not use `NSWindow.StyleMask.borderless` — this breaks native fullscreen and removes window management

**Test:**
- Open the output window — confirm it has a standard title bar with red/yellow/green traffic light buttons
- Confirm the window title says "Scoreboard Output"
- Click the green fullscreen button — confirm the window goes fullscreen, title bar hides, scoreboard fills the entire screen
- Move the cursor to the top of the screen — confirm the title bar reappears
- Press Escape — confirm the window exits fullscreen
- Use `Ctrl+Cmd+F` — confirm this also toggles fullscreen
- Check Mission Control — confirm the window appears as "Scoreboard Output"
- In fullscreen, confirm there are no visible borders, padding, or color mismatches around the scoreboard edges
- Test with an external display: drag the output window to the external monitor, enter fullscreen on that display — confirm it works correctly

---

## Implementation Order & CMUX Plan

```
┌─────────────────────────────────────────────┐
│  CMUX Agent A          CMUX Agent B         │
│                                             │
│  Task 1: Combined      Task 3: Fullscreen   │
│  Setup Step            Output Window        │
│  (wizard rework)       (window config)      │
│       │                      │              │
│       ▼                      ▼              │
│  ┌─────────── SYNC ───────────┐             │
│  │  Build + verify both tasks │             │
│  └─────────────────────────────┘            │
│              │                              │
│              ▼                              │
│       Task 2: Auto-Populate                 │
│       (depends on Task 1's wizard output)   │
│              │                              │
│              ▼                              │
│       Final Integration Test                │
└─────────────────────────────────────────────┘
```

Tasks 1 and 3 touch completely different files — run them as parallel CMUX agents. Task 2 depends on Task 1's wizard producing a game config object, so it runs after Task 1 completes.

---

## Final Integration Test Checklist

Run through the full operator workflow end to end:

- [ ] Launch app → startup screen appears
- [ ] Click "New Session" → wizard opens at the combined Event Info + Rounds step
- [ ] Configure event name, 4 rounds with custom point values → advance to Teams
- [ ] Add 8 teams (mix of individual entry and bulk paste) → advance to Confirm
- [ ] Click "Start Game" → scoring controller appears AND scoreboard preview immediately shows all 8 teams with 0 scores (no manual push needed)
- [ ] Open the output window → confirm it also shows the populated board
- [ ] Click the green fullscreen button on the output window → confirm native fullscreen works
- [ ] Score a few rounds in the scoring controller → confirm scores update on the board
- [ ] Press Escape on the fullscreen output → confirm it exits fullscreen cleanly
- [ ] Quit the app, relaunch → confirm startup screen offers "Resume Previous Session" with correct metadata
- [ ] Resume → confirm all scores are intact
