# Live Scoreboard for macOS

A native macOS app for displaying and managing live scoreboards at competitive events — trivia nights, game shows, corporate competitions, and more.

**Status: Beta (v0.2)**

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![License](https://img.shields.io/badge/license-private-lightgrey)

## What It Does

Live Scoreboard gives you a broadcast-quality leaderboard that you can control from your Mac and present fullscreen on an external display. Score teams locally or pull data from Google Sheets.

## Features

- **Local Scoring** — Add teams, configure per-round point values and bonuses, score with +/- buttons
- **Google Sheets** — Connect a published Google Sheet as a live data source with auto-refresh
- **Presentation Mode** — Keynote-style fullscreen output on any connected display (menu bar and dock hidden)
- **Display Picker** — Choose which monitor to present on when multiple displays are connected
- **Push / Live Toggle** — Stage score changes before pushing to the board, or update live in real-time
- **Full Design Customization** — Fonts, colors, row shapes (pill, rounded, angled, notched), gradients, logos, and more
- **5 Text Groups** — Independent font weight, color, and size for Header, Ranking, Team Names, Round Scores, and Total Points
- **3 Row Layout Modes** — Full Row, Split Rank, No Rank Background
- **Color Themes** — 4 built-in themes + save/load custom themes
- **Startup Wizard** — Guided game setup on launch with session resume support
- **Go to Black** — Fade the output to black without closing the presentation
- **Animated Rankings** — Rows animate when team positions change
- **Keyboard Shortcuts** — Cmd+R (refresh), Cmd+Shift+P (present), Cmd+Shift+B (blackout), Cmd+, (settings)

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ to build from source
- No external dependencies

## Build & Run

1. Clone the repo
2. Open `LiveScoreboard.xcodeproj` in Xcode
3. Build and run (Cmd+R)

That's it — no packages to install, no configuration needed.

## Quick Start

1. Launch the app — the startup screen offers **New Session** or **Resume Previous**
2. Set up your event: name the game, configure rounds and point values, add teams
3. Click **Start Game** — the scoreboard populates immediately
4. Open the settings sidebar to customize the look
5. Click the presentation button (or Cmd+Shift+P) to go fullscreen on an external display
6. Score the game using the +/- buttons in the scoring controller

## Known Limitations (Beta)

- CSV file import is not yet implemented
- No undo for score changes
- Background image mode is not yet functional
- Single game session at a time

## Feedback

This is a beta release. If you find bugs or have feature requests, please open an issue.
