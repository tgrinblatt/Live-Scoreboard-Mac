# Live Scoreboard — Typography Rework v2 (Claude Code)

## What's Changing

The Design panel typography controls need to be reorganized around five visual groupings on the scoreboard. Each grouping gets one font weight and one color — when you change the weight or color for a group, it applies to everything in that group.

---

## The Five Groupings

These match the colored boxes in the reference screenshot:

| Group | What It Covers | Example Content |
|-------|---------------|-----------------|
| **Header** | The entire header row | RK, TEAM, R1, R2, R3, R4, TOTAL |
| **Ranking** | The rank number column on every row | 01, 02, 03, 04, 05 |
| **Team Names** | The team name column on every row | OnStar, Sales Ops, CCA, GM Rewards, DRP |
| **Round Scores** | All round score values across all rows and all rounds | 60, 0, 0, 0, 30, 0, 0, 0, etc. |
| **Total Points** | The total column on every row | 60, 30, 20, 0, 0 |

These are the ONLY five text groups. There is no split between "header rank" and "row rank" — rank is one group. Round scores are one group covering every round column and every row.

---

## New Design Panel Layout

### Typography section

Font Family picker stays at the top. Remove the global Weight/Style list.

```
Typography
─────────────────────────────
Font Family
┌──────────────────────────┐
│ Chevy Sans            ▾  │
└──────────────────────────┘
```

### Text Groups section (replaces the current Header Styling + Row Text sections)

Combine the old "Header Styling" and "Row Text" sections into a single "Text Groups" section. Each group gets a font weight dropdown, a color picker, and a size slider — all on one line or a compact block.

```
Text Groups
─────────────────────────────

Header
[Semi Bold    ▾]   🎨   ━━━━━●━━━  200%

Ranking
[Bold         ▾]   🎨   ━━━━━●━━━  385%

Team Names
[Regular      ▾]   🎨   ━━━━━●━━━  389%

Round Scores
[Light        ▾]   🎨   ━━━━━●━━━  385%

Total Points
[Bold         ▾]   🎨   ━━━━━●━━━  401%
```

Each row has:
1. **Font weight dropdown** — shows all weights available in the current font family
2. **Color picker** — single color for the entire group
3. **Size slider** — percentage-based, single size for the entire group

That's it. Five groups, three controls each. Clean and simple.

---

## Implementation

### Step 1 — Update the Settings Model

**File:** `AppSettings.swift`

Replace the existing per-element header/row properties with five group-based property sets:

```swift
// Header group (the entire header row)
@Published var headerFontWeight: String = "semibold"
@Published var headerColor: Color = .white
@Published var headerFontSize: Double = 200  // percentage

// Ranking group (rank numbers column)
@Published var rankingFontWeight: String = "bold"
@Published var rankingColor: Color = .white
@Published var rankingFontSize: Double = 385

// Team Names group (team name column)
@Published var teamNamesFontWeight: String = "regular"
@Published var teamNamesColor: Color = .white
@Published var teamNamesFontSize: Double = 389

// Round Scores group (all round score values)
@Published var roundScoresFontWeight: String = "regular"
@Published var roundScoresColor: Color = .white
@Published var roundScoresFontSize: Double = 385

// Total Points group (total column)
@Published var totalPointsFontWeight: String = "bold"
@Published var totalPointsColor: Color = .yellow
@Published var totalPointsFontSize: Double = 401
```

Remove the old split properties (headerRankColor, headerNameColor, rowRankColor, rowNameColor, etc.) and migrate them. For backward compatibility, if old properties exist in saved data, map them to the new groups:
- Old `headerRankColor`, `headerNameColor`, `headerRoundColor`, `headerTotalColor` → all collapse into `headerColor` (use whatever the old headerRankColor was, or just default)
- Old `rowRankFontSize` → `rankingFontSize`
- Old `rowNameFontSize` → `teamNamesFontSize`
- Old `rowRoundFontSize` → `roundScoresFontSize`
- Old `rowTotalFontSize` → `totalPointsFontSize`

Add encode/decode for all new properties with fallback defaults.

### Step 2 — Build the Reusable Group Control

Create a reusable view component for each text group's controls:

```swift
struct TextGroupControl: View {
    let label: String
    @Binding var fontWeight: String
    @Binding var color: Color
    @Binding var fontSize: Double
    let availableWeights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)

            HStack {
                // Weight dropdown
                Picker("", selection: $fontWeight) {
                    ForEach(availableWeights, id: \.self) { weight in
                        Text(weight.capitalized).tag(weight)
                    }
                }
                .frame(width: 140)

                // Color picker
                ColorPicker("", selection: $color)
                    .labelsHidden()

                // Size slider
                Slider(value: $fontSize, in: 50...600)
                Text("\(Int(fontSize))%")
                    .monospacedDigit()
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }
}
```

### Step 3 — Rebuild the Admin Panel Design Tab

**File:** `AdminPanelView.swift` (or wherever the Design tab lives)

Remove the old "Header Styling" section. Remove the old "Row Text" section. Replace both with a single "Text Groups" section using five `TextGroupControl` instances:

```
Color Themes        ← stays as-is
Background          ← stays as-is
Typography          ← Font Family dropdown only, remove Weight/Style list
Text Groups         ← NEW: Header, Ranking, Team Names, Round Scores, Total Points
Row Design          ← stays as-is (Shape, Fill Mode, Opacity, Row Gap)
Global Colors       ← stays as-is
```

Populate `availableWeights` by querying the selected font family:
```swift
let members = NSFontManager.shared.availableMembers(ofFontFamily: selectedFontFamily)
```

When the font family changes, reset all five weight selections to "Regular" (or nearest available).

### Step 4 — Apply Groups in the Scoreboard View

**Files:** `ScoreboardView.swift`, `LeaderboardRowView.swift`

Map each text element on the scoreboard to its group:

**Header row** (the bar with RK, TEAM, R1, R2, R3, R4, TOTAL):
- ALL text in this row uses `headerFontWeight`, `headerColor`, `headerFontSize`
- This is one style for the entire header — no per-column differentiation within the header

**Each leaderboard row:**
- Rank number (01, 02, etc.) → `rankingFontWeight`, `rankingColor`, `rankingFontSize`
- Team name (OnStar, etc.) → `teamNamesFontWeight`, `teamNamesColor`, `teamNamesFontSize`
- Every round score cell (R1 value, R2 value, R3 value, R4 value) → `roundScoresFontWeight`, `roundScoresColor`, `roundScoresFontSize`
- Total value → `totalPointsFontWeight`, `totalPointsColor`, `totalPointsFontSize`

### Step 5 — Theme Integration

Update the theme save/load system to include the five group properties. Built-in themes (Broadcast Blue, Dark, Light, Corporate Neutral) should each define appropriate weights:

| Theme | Header | Ranking | Team Names | Round Scores | Total Points |
|-------|--------|---------|------------|-------------|-------------|
| Broadcast Blue | Semi Bold | Bold | Regular | Regular | Bold |
| Dark | Bold | Bold | Regular | Light | Bold |
| Light | Medium | Semi Bold | Regular | Regular | Semi Bold |
| Corporate Neutral | Medium | Medium | Regular | Regular | Medium |

Old saved custom themes without weight data should load with defaults (bold for ranking/total, regular for everything else).

---

## Test Checklist

- [ ] The old "Header Styling" and "Row Text" sections are gone from the Design panel
- [ ] A new "Text Groups" section shows five groups: Header, Ranking, Team Names, Round Scores, Total Points
- [ ] Each group has a weight dropdown, color picker, and size slider
- [ ] Changing **Header** weight/color/size affects the entire header row (RK, TEAM, R1, R2, R3, R4, TOTAL labels) uniformly
- [ ] Changing **Ranking** weight/color/size affects only the rank numbers (01, 02, 03...) on every row
- [ ] Changing **Team Names** weight/color/size affects only the team name text on every row
- [ ] Changing **Round Scores** weight/color/size affects ALL round score values across ALL rounds and ALL rows
- [ ] Changing **Total Points** weight/color/size affects only the total column values on every row
- [ ] Weight dropdowns show only weights available for the selected font family
- [ ] Switching font family resets all weights to "Regular"
- [ ] All five groups are independent — changing one does not affect the others
- [ ] Settings persist after quit and relaunch
- [ ] Built-in themes apply correct per-group weights
- [ ] Saving a custom theme captures all five group settings
- [ ] Loading old saved settings (pre-rework) doesn't crash — falls back to defaults
- [ ] Preview and output window both reflect the per-group styling correctly
