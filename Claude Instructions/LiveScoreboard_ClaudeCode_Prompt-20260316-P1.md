# Live Scoreboard for macOS — Claude Code Implementation Prompt

## Project Overview

You are working on a **macOS SwiftUI app** called **Live Scoreboard** — a broadcast-quality live scoreboard for graphics operators at corporate events. The app currently pulls data from Google Sheets and displays a branded leaderboard. Your job is to implement a series of bug fixes, architecture improvements, and new features following the phased plan below.

---

## CMUX Agent Strategy

Use **CMUX to deploy agents** for parallelizable work within each phase. However, **phases must be completed sequentially** — do not begin Phase 2 until Phase 1 is fully implemented and tested.

Within a phase, identify tasks that can safely run in parallel (e.g., fixing the UUID bug and the timer race condition touch different parts of the codebase). Spin up CMUX agents for those parallel tracks, then converge and test before moving on.

**CMUX guidelines:**
- Deploy agents for independent, non-conflicting tasks within the same phase
- Each agent should build and test its own changes before merging
- After all agents in a phase complete, do a **full build + integration test** before starting the next phase
- If a task depends on another task's output (e.g., animations depend on UUID stability), do NOT parallelize — run sequentially

---

## Testing Protocol

**After every individual task:**
1. Build the project (`xcodebuild` or `swift build` as appropriate)
2. Confirm zero compiler errors and zero warnings related to the change
3. If the change is testable in isolation, run or describe a manual verification step

**After every phase:**
1. Full clean build
2. Run any existing unit tests
3. Manual smoke test checklist (provided per phase below)
4. Document any regressions or side effects before proceeding

---

## Phase 1: Foundation

> **Goal:** Fix critical bugs and stabilize the core before adding features. These are prerequisites for everything that follows.

### Task 1.1 — Fix PlayerData UUID Stability
**Priority: CRITICAL — blocks animated rank changes and causes UI bugs**

- Currently, every `fetchData()` call creates new `PlayerData` objects with fresh UUIDs
- SwiftUI's `ForEach` loses track of row identity, destroying and recreating all rows on every refresh
- **Fix:** Change the `id` property to be derived from the team name (or another stable identifier from the data source), not a random UUID
- Make `PlayerData` conform to `Identifiable` using the team name as the stable ID
- Ensure `Hashable`/`Equatable` conformance is based on the stable identifier

**Test:** After a data refresh, confirm in the debug console (or via a counter) that existing rows are being updated in place, not destroyed and recreated.

---

### Task 1.2 — Fix Timer Race Condition
**Priority: CRITICAL — causes flickering and stale data**

- The countdown timer fires every 1 second, but `fetchData()` is async
- If a fetch takes longer than the refresh interval, multiple concurrent fetches stack up
- **Fix:** Add a `isFetchInProgress` boolean guard. If a fetch is already running, skip the new one.
- Consider using a `Task` with cancellation instead of overlapping fire-and-forget calls

**Test:** Add a temporary print/log statement showing fetch start/end. Confirm fetches never overlap even with a very short refresh interval (e.g., 1 second).

---

### Task 1.3 — Fix Settings Save Frequency
**Priority: Medium — performance issue**

- `saveToUserDefaults()` is called after every network fetch (every 5 seconds by default)
- **Fix:** Only call `saveToUserDefaults()` when the user actually changes a setting value
- Use a `didSet` observer on settings properties, or debounce saves

**Test:** Add a temporary log to the save function. Confirm it only fires when you change a setting in the UI, NOT on every data refresh cycle.

---

### Task 1.4 — Move Logo Image Data Out of UserDefaults
**Priority: Medium — startup performance**

- Logo image data (potentially several MB) is currently stored in UserDefaults (a plist loaded entirely into memory at launch)
- **Fix:** Store logo images as files in `~/Library/Application Support/LiveScoreboard/`
- UserDefaults should only store the file path/reference, not the raw data
- Create the directory if it doesn't exist on first launch
- Handle migration: if image data exists in UserDefaults on launch, move it to the file system and remove from UserDefaults

**Test:** Set a logo, quit and relaunch the app. Confirm the logo persists and UserDefaults plist size stays small.

---

### Task 1.5 — Add Keyboard Shortcuts and Menu Bar
**Priority: High — usability for broadcast operators**

- Add standard macOS menu bar with File/Edit/View/Window/Help menus
- Implement keyboard shortcuts:
  - `Cmd+,` → Open Settings
  - `Cmd+R` → Force Refresh Data
  - `Cmd+Shift+P` → Toggle Show Mode (placeholder for Phase 2 — just print to console for now)
  - `Escape` → Exit Show Mode (placeholder)
  - `Cmd+Q` → Quit
- Use SwiftUI `.commands {}` modifier on the app or scene

**Test:** Launch the app and verify all keyboard shortcuts trigger the correct action. Verify the menu bar appears with the correct items.

---

### Task 1.6 — Move Settings Panel to Sidebar/Inspector
**Priority: High — operators need to see changes live**

- Currently the admin panel is a modal sheet that covers the scoreboard
- **Fix:** Convert to a sidebar/inspector panel that sits beside the scoreboard
- The operator should be able to see the scoreboard update in real-time as they adjust settings
- Use `NavigationSplitView` or a custom sidebar approach
- The sidebar should be toggleable (show/hide)

**Test:** Open settings, change a color or font value, and confirm the scoreboard preview updates live without dismissing any modal.

---

### Task 1.7 — Add Local Scoring Interface
**Priority: HIGH — this is the #1 feature request**

This is the most impactful new feature. It enables fully offline operation.

**Data source toggle:**
- Add a three-way selector at the top level: `Google Sheets` / `Local Manual` / `CSV File Import`
- The scoreboard display remains identical regardless of source — only the data pipeline changes
- Implement a `ScoreboardDataProvider` protocol with separate implementations for each source

**Local Scoring Controller view (new dedicated view, not crammed into admin panel):**
- Round configuration panel (set up before the show):
  - Number of rounds
  - Point value per correct answer for each round
  - Bonus point value per round
  - Number of teams + team names
- Scoring controller layout (used during the show):
  - List of teams with `+` / `-` buttons per round
  - Per-round point values applied to the `+`/`-` buttons
  - Bonus points column per team per round with its own `+`/`-`
  - Manual override: click any score cell to type a custom value
  - Totals auto-calculate from rounds + bonus
  - Rankings auto-sort by total

**Push/Live toggle:**
- A prominent toggle: **"Live Update"** / **"Manual Push"**
- **Manual Push mode:** Scores are edited in a staging area. A large **"Push to Scoreboard"** button sends staged scores to the display. Prevents audience from seeing typos/partial updates.
- **Live Update mode:** Every change immediately reflects on the scoreboard
- Visual indicator when staged changes are pending (yellow dot or "Unsaved changes" badge)

**Data persistence:**
- Local scores auto-save to `~/Documents/LiveScoreboard/` after every edit
- If the app crashes, scores are recoverable on relaunch

**Keyboard shortcuts for speed:**
- Number keys `1` through `0` mapped to teams 1–10
- `+`/`-` to adjust the selected team's score
- This allows scoring without looking away from the show

**Test:** 
- Create a 4-team, 3-round game with different point values per round
- Score several rounds using both +/- buttons and keyboard shortcuts
- Switch between Manual Push and Live Update — confirm staging behavior
- Force-quit the app, relaunch, confirm scores persisted
- Switch data source to Google Sheets and back — confirm no data loss

---

### Phase 1 Smoke Test Checklist
After all Phase 1 tasks are complete:
- [ ] Clean build with zero errors
- [ ] App launches without delay (logo data not in UserDefaults)
- [ ] Data refreshes without row flickering (UUID stable)
- [ ] No overlapping fetch requests (timer race fixed)
- [ ] Settings only save on user interaction
- [ ] All keyboard shortcuts work
- [ ] Menu bar present and functional
- [ ] Settings sidebar visible alongside scoreboard
- [ ] Local scoring: full game can be scored offline
- [ ] Local scoring: data persists through app restart
- [ ] Switching between data sources works cleanly

---

## Phase 2: Presentation

> **Goal:** Make the app work as a real broadcast output tool with external display support.

### Task 2.1 — Implement Show Mode / External Display Output
**Priority: HIGH**

- Create two window types using SwiftUI multi-window support:
  1. **Operator Window** (primary display): Scoring controller, admin settings, and a small preview thumbnail of the scoreboard
  2. **Output Window** (external display): ONLY the scoreboard at the configured resolution. No chrome, no title bar, no controls. Borderless fullscreen.
- **Show Mode activation:**
  - Toolbar button + `Cmd+Shift+P` hotkey
  - App detects connected displays and lets operator choose which screen gets the output window
  - Output window goes fullscreen borderless on the selected display
  - Operator window stays on the primary screen
- **Operator window in Show Mode** should include:
  - If Local Scoring: the full scoring controller
  - If Google Sheets: status indicator showing connection health
  - A confidence monitor (mini preview of what's on the output display)
  - Transport controls: **"Go to Black"** (fade out scoreboard) and **"Show Scoreboard"** (fade in)

**Test:**
- Connect an external display (or simulate one)
- Enter Show Mode, confirm output window appears fullscreen on the external display
- Confirm operator window stays interactive on the primary display
- Test "Go to Black" and "Show Scoreboard" transitions
- Exit Show Mode with `Escape`, confirm output window closes

---

### Task 2.2 — Custom Pixel Size for Scoreboard
**Priority: Medium**

- Add width/height fields to the System settings tab (default: 1920×1080)
- Output window sizes to exactly those pixel dimensions
- The scoreboard view should scale to any resolution since it uses relative sizing
- Add presets: 1920×1080 (HD), 3840×2160 (4K), 1280×720 (720p), Custom
- Derive aspect ratio from the entered resolution (don't lock to 16:9)

**Test:** Set resolution to 1280×720, enter Show Mode, confirm output window is exactly that size. Repeat with 3840×2160 and a non-16:9 ratio like 1920×1200.

---

### Task 2.3 — Add Reset to Defaults
**Priority: Low**

- Add a "Reset All Settings" button in the System tab
- Confirmation dialog before executing
- Clears all UserDefaults, removes saved logos, resets to factory state

**Test:** Customize everything heavily, hit reset, confirm the app returns to default state.

---

### Phase 2 Smoke Test Checklist
- [ ] Clean build
- [ ] Show Mode activates and deactivates cleanly
- [ ] Output window appears borderless fullscreen on the correct display
- [ ] Confidence monitor in operator window matches output
- [ ] Go to Black / Show Scoreboard transitions work
- [ ] Custom resolution presets work correctly
- [ ] Non-16:9 aspect ratios display correctly
- [ ] Reset to defaults works without crashing
- [ ] All Phase 1 features still work (regression check)

---

## Phase 3: Animation & Polish

> **Goal:** Make it look and feel broadcast-grade.

### Task 3.1 — Animated Rank Changes
**Priority: High — this is what makes it feel professional**

- **Prerequisite:** Task 1.1 (UUID stability) MUST be complete. If team identity isn't stable, animations will break.
- Use SwiftUI `.animation()` + `.matchedGeometryEffect()` for smooth row position transitions
- When rankings change: rows smoothly slide up/down to their new position (~0.4–0.6 second duration)
- Brief highlight/glow effect on rows that moved

**Test:** In Local Scoring mode, change scores so rankings shift. Confirm rows animate smoothly to new positions rather than jumping.

---

### Task 3.2 — Score Change Animations
**Priority: Medium**

- When a score value updates:
  - Number briefly scales up then returns to normal size
  - Color flash: green for increase, red for decrease, then returns to the configured color
- Keep animations subtle — this is broadcast output, not a video game

**Test:** Increment and decrement a team's score. Confirm the number pulses and flashes the correct color.

---

### Task 3.3 — Entrance Animations
**Priority: Low**

- When the scoreboard first appears (or when activating Show Mode), rows cascade in from the side with a staggered delay
- Each row slides in ~0.1 seconds after the previous one
- This is a common broadcast graphic reveal technique

**Test:** Enter Show Mode. Confirm rows cascade in rather than appearing all at once.

---

### Task 3.4 — Color Presets / Themes
**Priority: Medium**

- Add a few built-in color themes: Dark, Light, Broadcast Blue, Corporate Neutral
- Ability to save the current custom color configuration as a named theme
- Quick-switch between saved themes (useful when switching between clients at multi-day events)

**Test:** Switch between built-in themes, confirm all scoreboard elements update. Save a custom theme, switch away, switch back — confirm it restores correctly.

---

### Phase 3 Smoke Test Checklist
- [ ] Clean build
- [ ] Rank change animations are smooth and correctly track team identity
- [ ] Score change animations (scale + color flash) work for both increases and decreases
- [ ] Entrance animations play on Show Mode activation
- [ ] Color presets switch cleanly
- [ ] Custom themes save and restore correctly
- [ ] All Phase 1 + 2 features still work (regression check)
- [ ] Animations don't cause performance issues (check for dropped frames)

---

## Phase 4: Advanced / Stretch Goals

> **Goal:** Professional-grade features for broadcast integration. Only tackle these after Phases 1–3 are solid.

### Task 4.1 — NDI/Syphon Output
- Output the scoreboard as an NDI or Syphon source for pickup by OBS, vMix, Wirecast, or video switchers
- This is a significant integration effort — research available Swift libraries for NDI/Syphon

### Task 4.2 — CSV File Import Data Source
- Third data source option alongside Google Sheets and Local Manual
- Drag-and-drop or file picker for a `.csv` file
- Re-read on a configurable timer or manual refresh button
- Works with Numbers/Excel CSV exports

### Task 4.3 — Logging System
- Log to `~/Library/Logs/LiveScoreboard/`
- Timestamped entries for: network errors, parse failures, settings changes, Show Mode events, data source switches
- Log rotation (don't let files grow unbounded)

### Task 4.4 — Architecture: Split AppSettings
- Current settings object has 60+ properties on one class
- Split into focused models:
  - `DataSourceSettings` (sheet ID, refresh interval, data source mode)
  - `AppearanceSettings` (colors, fonts, row styles)
  - `LayoutSettings` (num rounds, num teams, resolution, vertical height)
  - `BrandingSettings` (title, logos, footer)
- This prevents unrelated setting changes from triggering unnecessary re-renders

### Task 4.5 — Performance: Isolate Timer Redraws
- The countdown timer updates every second, currently causing the entire scoreboard to re-render
- Extract the countdown into its own isolated view so only the countdown text redraws

### Task 4.6 — Performance: Cache Logo Images
- `NSImage(data:)` is currently called inside the view body (decompressing image data on every render pass)
- Cache decoded images in `@State` or a precomputed property

### Task 4.7 — Performance: Remove Nested GeometryReaders
- `ScoreboardView` has a `GeometryReader`, and each `LeaderboardRowView` also has one
- Calculate row dimensions once in the parent and pass them down as parameters

---

## General Guidelines

- **SwiftUI first** — Use native SwiftUI APIs wherever possible. Avoid UIKit bridging unless absolutely necessary.
- **macOS conventions** — Respect standard macOS UX patterns (menu bar, keyboard shortcuts, window management, `Cmd+,` for settings).
- **Offline-first** — The app must work fully offline in Local Scoring mode. Network features should degrade gracefully.
- **Crash resilience** — Auto-save frequently. The operator should never lose the show.
- **No external dependencies unless necessary** — Keep the dependency footprint minimal. This is a native macOS app.
- **Comment your code** — Especially around the data provider protocol, animation logic, and multi-window management. Other developers at the company need to be able to maintain this.

---

## File & Directory Conventions

- **App data:** `~/Library/Application Support/LiveScoreboard/` (logos, themes, settings cache)
- **Show data:** `~/Documents/LiveScoreboard/` (local score files, CSV imports)
- **Logs:** `~/Library/Logs/LiveScoreboard/`

---

## Summary of CMUX Parallelization Opportunities

| Phase | Parallel Tracks | Sequential Dependencies |
|-------|----------------|------------------------|
| **Phase 1** | Tasks 1.1 + 1.2 + 1.3 can run in parallel (different code areas). Task 1.4 can parallel with 1.5. | Task 1.6 (sidebar) should come before 1.7 (local scoring UI needs the new layout). Task 1.7 depends on the data provider protocol. |
| **Phase 2** | Task 2.2 + 2.3 can run in parallel. | Task 2.1 (Show Mode) must complete first — 2.2 depends on the output window existing. |
| **Phase 3** | Task 3.2 + 3.4 can run in parallel. | Task 3.1 depends on Phase 1's UUID fix. Task 3.3 depends on 3.1's animation system. |
| **Phase 4** | Most tasks are independent and can be parallelized freely. | 4.4 (split settings) should ideally precede 4.5–4.7 (performance) for cleaner architecture. |
