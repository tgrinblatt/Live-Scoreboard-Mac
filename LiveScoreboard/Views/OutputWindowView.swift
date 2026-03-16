import SwiftUI

/// The clean output window for Show Mode.
/// Displays ONLY the scoreboard — no chrome, no controls.
/// Intended to go fullscreen on an external display.
struct OutputWindowView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var players: [PlayerData]
    @Binding var isLoading: Bool
    @Binding var lastUpdated: Date?
    @Binding var countdown: Int
    @Binding var isBlacked: Bool

    var body: some View {
        ZStack {
            Color.black

            if !isBlacked {
                ScoreboardView(
                    players: Array(players.prefix(settings.numTeams)),
                    isLoading: isLoading,
                    lastUpdated: lastUpdated,
                    countdown: countdown,
                    errorMessage: nil
                )
                .environmentObject(settings)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isBlacked)
        .ignoresSafeArea()
    }
}
