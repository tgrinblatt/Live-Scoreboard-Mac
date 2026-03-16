import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var players: [PlayerData] = []
    @State private var isLoading = false
    @State private var lastUpdated: Date? = nil
    @State private var countdown: Int = 0
    @State private var errorMessage: String? = nil
    @State private var showAdmin = false
    @State private var timerCancellable: Timer? = nil
    @State private var showControls = false

    var body: some View {
        ZStack {
            ScoreboardView(
                players: Array(players.prefix(settings.numTeams)),
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                countdown: countdown,
                errorMessage: errorMessage
            )
            .environmentObject(settings)

            // Floating controls (top-right)
            VStack {
                HStack {
                    Spacer()
                    if showControls {
                        HStack(spacing: 8) {
                            Button(action: { Task { await fetchData() } }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .help("Refresh Data")

                            Button(action: { showAdmin.toggle() }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .help("Settings")
                        }
                        .padding(12)
                        .transition(.opacity)
                    }
                }
                Spacer()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls = hovering
            }
        }
        .sheet(isPresented: $showAdmin) {
            AdminPanelView(onRefresh: { Task { await fetchData() } })
                .environmentObject(settings)
                .frame(minWidth: 520, minHeight: 600)
        }
        .onAppear {
            startAutoRefresh()
        }
        .onDisappear {
            timerCancellable?.invalidate()
        }
        .onChange(of: settings.refreshInterval) { _, _ in
            startAutoRefresh()
        }
        .onChange(of: settings.sheetId) { _, _ in
            Task { await fetchData() }
        }
        .onChange(of: settings.numRounds) { _, _ in
            Task { await fetchData() }
        }
    }

    private func fetchData() async {
        guard !settings.sheetId.isEmpty else {
            players = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await GoogleSheetsService.fetchData(
                sheetInput: settings.sheetId,
                numRounds: settings.numRounds
            )
            players = result
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        countdown = Int(settings.refreshInterval)
        settings.saveToUserDefaults()
    }

    private func startAutoRefresh() {
        timerCancellable?.invalidate()
        countdown = Int(settings.refreshInterval)

        timerCancellable = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                countdown = Int(settings.refreshInterval)
                Task { await fetchData() }
            }
        }
    }
}
