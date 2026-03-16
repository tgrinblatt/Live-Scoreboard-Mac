import SwiftUI

/// Shared state for the output window — allows the operator window
/// and output window to share the same player data and control state.
class ShowModeState: ObservableObject {
    @Published var isActive = false
    @Published var isBlacked = false
    @Published var players: [PlayerData] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date? = nil
    @Published var countdown: Int = 0
}

@main
struct LiveScoreboardApp: App {
    @StateObject private var settings = AppSettings.loadFromUserDefaults()
    @StateObject private var showModeState = ShowModeState()

    var body: some Scene {
        // Operator window
        WindowGroup {
            ContentView(showModeState: showModeState)
                .environmentObject(settings)
                .environmentObject(showModeState)
        }
        .defaultSize(width: 1400, height: 800)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .toggleSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Divider()
                Button("Refresh Data") {
                    NotificationCenter.default.post(name: .refreshData, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Toggle Show Mode") {
                    NotificationCenter.default.post(name: .toggleShowMode, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Go to Black") {
                    NotificationCenter.default.post(name: .toggleBlack, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .toolbar) {
                Button("Toggle Settings Sidebar") {
                    NotificationCenter.default.post(name: .toggleSettings, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }

        // Output window — opened when Show Mode activates
        Window("Scoreboard Output", id: "output") {
            OutputWindowView(
                players: $showModeState.players,
                isLoading: $showModeState.isLoading,
                lastUpdated: $showModeState.lastUpdated,
                countdown: $showModeState.countdown,
                isBlacked: $showModeState.isBlacked
            )
            .environmentObject(settings)
            .environmentObject(showModeState)
        }
        .defaultSize(
            width: CGFloat(settings.outputWidth),
            height: CGFloat(settings.outputHeight)
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let toggleSettings = Notification.Name("toggleSettings")
    static let refreshData = Notification.Name("refreshData")
    static let toggleShowMode = Notification.Name("toggleShowMode")
    static let toggleBlack = Notification.Name("toggleBlack")
}
