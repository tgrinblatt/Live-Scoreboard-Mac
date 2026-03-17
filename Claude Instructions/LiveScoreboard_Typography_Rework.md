# Live Scoreboard — Design Panel Typography Rework (Claude Code)

## What's Changing

The current Design panel has a single Font Family picker and a single Weight/Style selector that applies globally. The new system keeps one font family picker at the top, but gives every text element its own independent font weight dropdown. This lets the operator make the rank number bold while keeping round scores light, or make headers italic while team names stay regular — all within the same font family.

---

## Current State (from the screenshots)

The Design tab currently has:

**Typography section:**
- Font Family dropdown (currently "Chevy Sans")
- A single Weight/Style list showing all available weights (Regular, Italic, Thin, Thin Italic, Extra Light, Extra Light Italic, etc.)
- This one selection applies everywhere

**Header Styling section:**
- Font Size slider (percentage-based)
- Color pickers for Rank, Name, Round, Total

**Row Text section:**
- Color picker + size slider for Rank
- Color picker + size slider for Name
- Color picker + size slider for Round
- Color picker + size slider for Total

---

## New Design

### Typography section — simplified

Keep only the Font Family dropdown. Remove the global Weight/Style list entirely. The font family is still a single global choice — you pick one typeface for the whole board.

```
Typography
─────────────────────────────
Font Family
┌──────────────────────────┐
│ Chevy Sans            ▾  │
└──────────────────────────┘
```

That's it for this section. Weight selection moves into each text group below.

### Header Styling section — add weight per element

Add a font weight dropdown to each header text element, right next to its existing color picker.

```
Header Styling
─────────────────────────────
Font Size  ━━━━━━━━━━●━━  200%

Rank    [Bold         ▾]  🎨
Name    [Semi Bold    ▾]  🎨
Round   [Regular      ▾]  🎨
Total   [Bold         ▾]  🎨
```

Each dropdown shows all available weights for the currently selected font family (Regular, Italic, Thin, Bold, Semi Bold, etc.). The color picker stays where it is.

### Row Text section — add weight per element

Same treatment. Add a font weight dropdown to each row text element alongside its existing color picker and size slider.

```
Row Text
─────────────────────────────
Rank
[Bold         ▾]  🎨  ━━━━●━━  385%

Name
[Regular      ▾]  🎨  ━━━━●━━  389%

Round
[Light        ▾]  🎨  ━━━━●━━  385%

Total
[Semi Bold    ▾]  🎨  ━━━━●━━  401%
```

### Scoreboard Title — add weight

If there's a scoreboard title/event name text element in the design settings, it should also get its own weight dropdown. If it doesn't exist yet, skip this.

---

## Implementation

### Step 1 — Update the Settings Model

**File:** `AppSettings.swift`

Add font weight properties for each text element. Use the system font weight names that map to SwiftUI's `Font.Weight` values:

```swift
// Header weights
@Published var headerRankFontWeight: String = "bold"
@Published var headerNameFontWeight: String = "semibold"
@Published var headerRoundFontWeight: String = "regular"
@Published var headerTotalFontWeight: String = "bold"

// Row text weights
@Published var rowRankFontWeight: String = "bold"
@Published var rowNameFontWeight: String = "regular"
@Published var rowRoundFontWeight: String = "regular"
@Published var rowTotalFontWeight: String = "semibold"
```

Store as strings that map to weight values. Add encode/decode support with sensible fallback defaults so existing users don't break.

Create a helper that converts the stored string to a usable font weight or font variant name:

```swift
static func fontWeight(from name: String) -> Font.Weight {
    switch name.lowercased() {
    case "thin": return .thin
    case "ultralight", "extra light": return .ultraLight
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold", "semi bold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .regular
    }
}
```

**Important — italic handling:** Some fonts have italic variants as separate font faces (e.g., "Chevy Sans Italic" vs "Chevy Sans"). If the selected font family has italic variants, include them in the weight dropdown as separate options (e.g., "Regular", "Italic", "Bold", "Bold Italic"). Use the actual font descriptor/variant name rather than just `Font.Weight` when the selection includes an italic variant.

### Step 2 — Build the Weight Dropdown Component

**New file or inline in the admin panel view**

Create a reusable weight picker component:

```swift
struct FontWeightPicker: View {
    let label: String
    @Binding var selectedWeight: String
    let availableWeights: [String]

    var body: some View {
        Picker(label, selection: $selectedWeight) {
            ForEach(availableWeights, id: \.self) { weight in
                Text(weight.capitalized).tag(weight)
            }
        }
    }
}
```

The `availableWeights` array should be dynamically populated based on the currently selected font family. When the font family changes, query the system for all available weights/styles of that family and update the list.

**Querying available weights for a font family (macOS):**

```swift
let fontFamily = "Chevy Sans"
let members = NSFontManager.shared.availableMembers(ofFontFamily: fontFamily)
// Returns array of [postscriptName, styleName, weight, traits]
// Use styleName for display ("Regular", "Bold", "Light Italic", etc.)
```

### Step 3 — Update the Admin Panel UI

**File:** `AdminPanelView.swift` (or wherever the Design tab is implemented)

1. **Typography section:** Remove the global Weight/Style list. Keep only the Font Family dropdown.

2. **Header Styling section:** For each element (Rank, Name, Round, Total), add a `FontWeightPicker` inline next to the color picker. Lay it out so the row reads naturally: label, weight dropdown, color picker — all on one line if space permits, or weight dropdown on its own line under the label if the sidebar is narrow.

3. **Row Text section:** Same treatment. For each element (Rank, Name, Round, Total), add a `FontWeightPicker` next to the existing color picker and size slider.

4. **When the font family changes**, reset all weight selections to "Regular" (or the closest available weight) to avoid referencing a weight that doesn't exist in the new font.

### Step 4 — Apply Weights in the Scoreboard View

**Files:** `ScoreboardView.swift`, `LeaderboardRowView.swift`, and any other views that render scoreboard text

Wherever text is rendered on the scoreboard, apply the element-specific weight instead of a single global weight:

- Header rank text → uses `headerRankFontWeight`
- Header name text → uses `headerNameFontWeight`
- Header round labels → uses `headerRoundFontWeight`
- Header total label → uses `headerTotalFontWeight`
- Row rank number → uses `rowRankFontWeight`
- Row team name → uses `rowNameFontWeight`
- Row round scores → uses `rowRoundFontWeight`
- Row total score → uses `rowTotalFontWeight`

Use the helper from Step 1 to convert the stored string to the appropriate font modifier. If the weight includes an italic variant, use the font descriptor approach rather than just `.fontWeight()`.

### Step 5 — Theme Integration

**File:** Wherever color themes/presets are saved and loaded

If the app has a theme/preset system (the screenshots show built-in themes like Broadcast Blue, Dark, Light, Corporate Neutral), include the per-element font weights in the theme data. When a theme is applied, it should set all the weight values along with the colors.

Update the "Save Current" theme feature to capture the current weight selections.

---

## Backward Compatibility

- Existing saved settings won't have the new weight properties. The decoder must fall back to sensible defaults (bold for rank/total, regular for name/round scores is a good starting point).
- Existing themes saved by users won't have weight data. When loading an old theme, apply the same defaults.
- The removed global Weight/Style setting should be ignored if found in old saved data — don't crash, just discard it.

---

## Test Checklist

- [ ] Font Family dropdown still works — changing the family updates the entire scoreboard
- [ ] Global Weight/Style list is gone from the Typography section
- [ ] Each header element (Rank, Name, Round, Total) has its own weight dropdown
- [ ] Each row text element (Rank, Name, Round, Total) has its own weight dropdown
- [ ] Weight dropdowns show only weights available for the current font family
- [ ] Changing font family resets all weights to "Regular"
- [ ] Setting header Rank to Bold and header Name to Light — confirm they render differently on the scoreboard
- [ ] Setting row Total to Heavy and row Round to Thin — confirm they render differently
- [ ] Italic variants appear in the dropdown and render correctly when selected
- [ ] Weights persist after quitting and relaunching the app
- [ ] Switching between built-in themes applies the correct weights
- [ ] Saving a custom theme captures the weight selections
- [ ] Loading an old theme (without weight data) applies sensible defaults without crashing
- [ ] The preview and output window both reflect the per-element weights correctly
