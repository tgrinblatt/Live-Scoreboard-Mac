# Claude Review 1 — Live Scoreboard for macOS

## Context

This app is a broadcast-quality live scoreboard for a graphics operator working live events. It needs to be rock-solid, work offline, be heavily customizable for client branding, and be simple enough that anyone in the company can pick it up and use it. Below is my analysis of the current state of the app, how I'd approach each wishlist item, and additional improvements I'd recommend.

---

## Part 1: Wishlist Feasibility & Implementation Plan

### 1. Local Scoring Interface (Offline Mode)

**Verdict: Fully feasible and highly recommended.**

This is the single most impactful feature for a live event operator. Wi-Fi at venues is notoriously unreliable.

**How I'd build it:**

- **New data source mode** — Add a three-way toggle at the top level: `Google Sheets`, `Local Manual`, and `CSV File Import`. The scoreboard view stays identical regardless of source — only the data pipeline changes.

- **Local Scoring Controller** — A dedicated view (not crammed into the admin panel) with:
  - A list of teams with + / - buttons per round
  - **Per-round point values**: A settings area at the top where you set "Round 1 = 10 pts, Round 2 = 25 pts, Round 3 = 50 pts" etc. The +/- buttons then add/subtract that round's point value.
  - **Bonus points**: Each team gets a separate bonus column with its own +/- that you can set independently per round. These get added to the total.
  - **Manual override**: Ability to click on any score cell and type a custom value directly (for corrections).
  - Totals auto-calculate from rounds + bonus.
  - Rankings auto-sort by total.

- **Push/Live toggle** — This is a great idea. I'd implement it as:
  - A prominent toggle switch labeled **"Live Update"** / **"Manual Push"** at the top of the scoring controller.
  - In **Manual Push** mode: scores are edited in a staging area. A large, obvious **"Push to Scoreboard"** button sends the staged scores to the display. This prevents the audience from seeing mid-entry typos or partial updates.
  - In **Live Update** mode: every change immediately reflects on the scoreboard (useful for fast-paced rounds).
  - Visual indicator on the scoring controller showing whether staged changes are pending (e.g., a yellow dot or "Unsaved changes" badge).

- **Data persistence** — Local scores save to a file in `~/Documents/LiveScoreboard/` so if the app crashes, you don't lose the show. Auto-save after every edit.

- **CSV File Import** as a third option — drag-and-drop or file picker for a local `.csv` file, re-read on a timer or manual refresh. Works great with Numbers/Excel exports without needing Sheets.

### 2. Custom Scoring Interface Details

**Verdict: Fully feasible. This is essentially item #1's controller with the specific scoring rules.**

**Additional details on implementation:**

- **Round configuration panel**: Before the show starts, you'd set up:
  - Number of rounds
  - Point value per correct answer for each round
  - Bonus point value per round (can differ from base points)
  - Number of teams + team names

- **Scoring controller layout** (what you'd see during the show):
  ```
  ┌─────────────────────────────────────────────────────────┐
  │  [Live Update ○ / ● Manual Push]     [PUSH TO BOARD]   │
  │                                                          │
  │  Round: [1] [2] [3] [4]   ← tab between rounds          │
  │  Points per answer: 10    Bonus: 25                      │
  │                                                          │
  │  Team Alpha     [+] [-]  Score: 30   Bonus: [+][-] 25   │
  │  Team Beta      [+] [-]  Score: 20   Bonus: [+][-]  0   │
  │  Team Gamma     [+] [-]  Score: 40   Bonus: [+][-] 25   │
  │  ...                                                     │
  └─────────────────────────────────────────────────────────┘
  ```

- **Keyboard shortcuts for speed**: During a live show, clicking buttons is slow. I'd add keyboard bindings — e.g., `1` through `0` mapped to teams 1-10, then `+`/`-` to adjust. This way you can score without looking away from the show.

### 3. Presentation Mode / External Display

**Verdict: Fully feasible. This is the feature that makes it a real broadcast tool.**

**How I'd build it:**

- **macOS window management** — SwiftUI supports multiple windows natively. I'd create two window types:
  1. **Operator Window** (main display): Contains the scoring controller, admin settings, and a small preview of the scoreboard.
  2. **Output Window** (external display): Contains ONLY the scoreboard at the configured resolution. No chrome, no title bar, no controls.

- **Show Mode activation**:
  - A toolbar button or `Cmd+Shift+P` to enter "Show Mode"
  - The app detects connected displays and lets you choose which screen gets the output window
  - The output window goes fullscreen on the selected display with `NSWindow.StyleMask` set to borderless
  - The operator window stays on your primary screen

- **Operator window in Show Mode** would contain:
  - If using Local Scoring: the full scoring controller
  - If using Google Sheets: an embedded `WKWebView` showing the live Google Sheet (so you can edit scores right from the app)
  - A mini preview thumbnail of what's on the output display
  - A "confidence monitor" — small replica of the output so you always know what the audience sees
  - Transport controls: "Go to Black" (fade out scoreboard), "Show Scoreboard" (fade in), useful for transitioning

- **NDI/Syphon output** (stretch goal): For professional broadcast workflows, outputting the scoreboard as an NDI or Syphon source would let it be picked up by OBS, vMix, Wirecast, or any video switcher directly. This would be a significant addition but would make the app extremely valuable for broadcast work.

### 4. Custom Pixel Size for Scoreboard

**Verdict: Trivial to implement.**

**How I'd build it:**

- Add width/height fields to the System tab (default 1920x1080).
- The output window gets sized to exactly those pixel dimensions.
- The scoreboard view already uses relative sizing (percentages of container), so it will scale to any resolution.
- Add common presets: 1920x1080 (HD), 3840x2160 (4K), 1280x720 (720p), and custom.
- The aspect ratio is currently locked at 16:9. I'd make it derive from the custom resolution instead, so if someone enters 1920x1200 (16:10) or 1024x768 (4:3), it adapts.

### 5. Animated Rank Changes

**Verdict: Feasible and would look great.**

**How I'd build it:**

- **Stable identity** — The current code creates a new UUID for each player on every data refresh, which means SwiftUI can't track which row belongs to which team. I'd switch to using the team name as the stable identifier.

- **SwiftUI `.animation` + `.matchedGeometryEffect`** — When rankings change:
  - Rows smoothly slide up or down to their new position
  - A brief highlight/glow effect on rows that moved
  - The transition would take ~0.4-0.6 seconds (fast enough to feel snappy, slow enough to be visible)

- **Score change animation** — When a score updates:
  - The number briefly scales up or flashes
  - Color flash (green for increase, red for decrease) before returning to normal
  - This gives the audience a visual cue about what changed

- **Optional entrance animation** — When the scoreboard first appears or when switching to Show Mode, rows could cascade in from the side (staggered, like a reveal). This is common in broadcast graphics.

---

## Part 2: Code Review — Issues & Improvements

### Critical Bugs to Fix

1. **PlayerData UUID instability** — Every time scores refresh from Google Sheets, all player objects get new UUIDs. This means SwiftUI's `ForEach` can't track row identity, causing all rows to be destroyed and recreated on every refresh. This will also completely break animated rank changes. Fix: use a stable ID based on team name.

2. **Timer race condition** — The countdown timer fires every 1 second, but `fetchData()` is async. If a fetch takes longer than the refresh interval, multiple concurrent fetches stack up. This could cause flickering or stale data overwriting fresh data. Fix: add a fetch-in-progress guard.

3. **Settings saved on every data fetch** — `saveToUserDefaults()` is called after every network request (every 5 seconds by default). It should only save when the user changes a setting. This is wasteful and could cause lag on slower machines.

4. **Logo image data stored in UserDefaults** — UserDefaults is backed by a plist file that gets loaded entirely into memory on launch. Storing image data here bloats startup time and memory. Images should go to `~/Library/Application Support/LiveScoreboard/`.

### UI/UX Improvements

5. **No keyboard shortcuts** — A broadcast tool needs fast, reliable access. At minimum:
   - `Cmd+,` → Settings
   - `Cmd+R` → Refresh data
   - `Cmd+Shift+P` → Show Mode (item #3)
   - `Escape` → Exit Show Mode

6. **Settings panel blocks the scoreboard** — Currently the admin panel is a modal sheet that covers the scoreboard. You can't see your changes live. I'd switch to either:
   - A **sidebar/inspector** that sits beside the scoreboard
   - Or a **separate window** that floats over the scoreboard with transparency

7. **Controls only visible on hover** — First-time users won't know the gear icon exists. I'd add a proper macOS **toolbar** with buttons for Settings, Refresh, and Show Mode. The hover behavior can remain as an alternative in Show Mode where you want the UI hidden.

8. **No menu bar** — The app has no File/Edit/View/Window menus. macOS users expect `Cmd+,` for settings, `Cmd+Q` to quit, `Cmd+N` for new, etc. SwiftUI makes this straightforward with `.commands {}`.

9. **No reset to defaults** — If someone over-customizes and wants to start fresh, there's no way back without deleting the app's preferences. Add a "Reset All Settings" button in the System tab.

10. **No color presets/themes** — For branding, it would be helpful to have a few built-in color themes (Dark, Light, Broadcast Blue, etc.) as starting points, plus the ability to save custom themes. This speeds up setup when switching between clients.

### Architecture Improvements

11. **Split AppSettings into smaller models** — The current settings object has 60+ properties all on one class. Changes to a background color trigger re-renders on the font picker. I'd split into:
    - `DataSourceSettings` (sheet ID, refresh interval, data source mode)
    - `AppearanceSettings` (colors, fonts, row styles)
    - `LayoutSettings` (num rounds, num teams, resolution, vertical height)
    - `BrandingSettings` (title, logos, footer)

12. **Add a proper data layer** — Right now the view directly calls the network service. With three data sources (Sheets, Local, CSV), there should be a `ScoreboardDataProvider` protocol with implementations for each source. The view just asks for data and doesn't care where it comes from.

13. **Add logging** — When things go wrong at a live event, you need to know why. A simple log to `~/Library/Logs/LiveScoreboard/` with timestamped network errors, parse failures, and settings changes would be invaluable for debugging.

### Performance Improvements

14. **Countdown timer causes full view redraws** — The countdown updates every second, which currently causes the entire scoreboard to re-render. This should be extracted into its own tiny view so only the countdown text redraws.

15. **Logo images decoded on every render** — `NSImage(data:)` is called inside the view body, meaning logo images are decompressed from PNG/JPEG data on every render pass. These should be cached in a `@State` or precomputed property.

16. **Nested GeometryReaders** — ScoreboardView has a GeometryReader, and each LeaderboardRowView also has one. This is expensive. The row dimensions should be calculated once in the parent and passed down as parameters.

---

## Part 3: Recommended Implementation Order

Given that this is a live event tool, I'd prioritize stability and offline capability first, then presentation features, then polish.

### Phase 1: Foundation (do first)
1. Fix PlayerData UUID stability (required for everything else)
2. Fix timer race condition
3. Fix settings save frequency
4. Add keyboard shortcuts and menu bar
5. Move settings panel to sidebar/inspector (non-blocking)
6. Add Local Scoring Interface (wishlist #1 + #2)

### Phase 2: Presentation
7. Implement Show Mode / External Display (wishlist #3)
8. Custom pixel size (wishlist #4)
9. Add operator window with scoring controller + preview

### Phase 3: Animation & Polish
10. Animated rank changes (wishlist #5)
11. Score change animations
12. Entrance animations
13. Color presets/themes
14. "Go to Black" / fade transitions

### Phase 4: Advanced (stretch goals)
15. NDI/Syphon output for broadcast integration
16. CSV file import as data source
17. Embedded Google Sheets web view in operator window
18. Logging system
19. App icon and about box

---

## Summary

Every item on the wishlist is feasible with native macOS/SwiftUI. The local scoring interface and presentation mode are the two highest-impact features — they transform this from "a nice display app" into "a real broadcast tool I can rely on at shows." The animated rankings will make it feel polished and broadcast-grade.

The current codebase is solid and well-structured but has a few bugs that need fixing before adding features (especially the UUID stability issue and timer race condition). The architecture changes I'm recommending (splitting settings, data provider protocol) will make the feature additions cleaner and prevent the codebase from getting tangled as it grows.

This has the potential to be a genuinely useful tool for your work. Let me know which items you want to tackle first.
