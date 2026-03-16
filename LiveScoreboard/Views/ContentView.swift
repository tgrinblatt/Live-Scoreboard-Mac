import SwiftUI

/// Main operator window: toolbar + optional settings sidebar + scoreboard/scoring content.
struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var showModeState: ShowModeState
    @Environment(\.openWindow) private var openWindow

    // MARK: - Data state
    @State private var displayPlayers: [PlayerData] = []
    @State private var stagedPlayers: [PlayerData] = []
    @State private var isLoading = false
    @State private var lastUpdated: Date? = nil
    @State private var countdown: Int = 0
    @State private var errorMessage: String? = nil
    @State private var hasPendingChanges = false

    // MARK: - UI state
    @State private var showSettings = false

    // MARK: - Timer & fetch guard
    @State private var timer: Timer? = nil
    @State private var isFetchInProgress = false

    // MARK: - Local scoring
    @StateObject private var localGame = LocalGameState.load() ?? LocalGameState()

    var body: some View {
        HSplitView {
            // Settings sidebar (toggleable)
            if showSettings {
                ScrollView {
                    AdminPanelView(onRefresh: { Task { await fetchData() } })
                        .environmentObject(settings)
                }
                .frame(minWidth: 340, idealWidth: 380, maxWidth: 450)
                .background(Color(nsColor: .windowBackgroundColor))
            }

            // Main content area
            VStack(spacing: 0) {
                toolbarView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Show mode transport controls
                if showModeState.isActive {
                    showModeBar
                    Divider()
                }

                // Content based on data source mode
                switch settings.dataSourceMode {
                case .googleSheets, .csvFile:
                    ScoreboardView(
                        players: Array(displayPlayers.prefix(settings.numTeams)),
                        isLoading: isLoading,
                        lastUpdated: lastUpdated,
                        countdown: countdown,
                        errorMessage: errorMessage
                    )
                    .environmentObject(settings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .localManual:
                    HSplitView {
                        LocalScoringView(
                            localGame: localGame,
                            onScoresChanged: { handleLocalScoreChange() },
                            onPush: { pushLocalScores() }
                        )
                        .environmentObject(settings)
                        .frame(minWidth: 380, idealWidth: 420)

                        ScoreboardView(
                            players: Array(displayPlayers.prefix(settings.numTeams)),
                            isLoading: false,
                            lastUpdated: lastUpdated,
                            countdown: 0,
                            errorMessage: nil
                        )
                        .environmentObject(settings)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                statusBar
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .onAppear {
            startAutoRefresh()
            if settings.dataSourceMode == .localManual {
                handleLocalScoreChange()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: settings.refreshInterval) { _, _ in
            startAutoRefresh()
        }
        .onChange(of: settings.sheetId) { _, _ in
            if settings.dataSourceMode == .googleSheets {
                Task { await fetchData() }
            }
        }
        .onChange(of: settings.numRounds) { _, newVal in
            if settings.dataSourceMode == .googleSheets {
                Task { await fetchData() }
            } else if settings.dataSourceMode == .localManual {
                localGame.setNumRounds(newVal)
                handleLocalScoreChange()
            }
        }
        .onChange(of: settings.dataSourceMode) { _, newMode in
            timer?.invalidate()
            displayPlayers = []
            errorMessage = nil
            if newMode == .googleSheets {
                startAutoRefresh()
                Task { await fetchData() }
            } else if newMode == .localManual {
                handleLocalScoreChange()
            }
        }
        // Sync display players to the show mode output window
        .onChange(of: displayPlayers) { _, newPlayers in
            showModeState.players = newPlayers
        }
        .onChange(of: isLoading) { _, val in showModeState.isLoading = val }
        .onChange(of: lastUpdated) { _, val in showModeState.lastUpdated = val }
        .onChange(of: countdown) { _, val in showModeState.countdown = val }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSettings)) { _ in
            withAnimation { showSettings.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshData)) { _ in
            Task { await fetchData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleShowMode)) { _ in
            toggleShowMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleBlack)) { _ in
            if showModeState.isActive {
                showModeState.isBlacked.toggle()
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation { showSettings.toggle() } }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14))
            }
            .buttonStyle(.bordered)
            .help("Toggle Settings (Cmd+Option+S)")

            Divider().frame(height: 20)

            Picker("Source", selection: $settings.dataSourceMode) {
                ForEach(AppSettings.DataSourceMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 340)

            Spacer()

            // Push mode toggle (local scoring only)
            if settings.dataSourceMode == .localManual {
                HStack(spacing: 6) {
                    if hasPendingChanges && settings.pushMode {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                    }
                    Toggle(isOn: Binding(
                        get: { !settings.pushMode },
                        set: { settings.pushMode = !$0 }
                    )) {
                        Text(settings.pushMode ? "Manual Push" : "Live Update")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                if settings.pushMode {
                    Button(action: { pushLocalScores() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Push")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasPendingChanges)
                }

                Divider().frame(height: 20)
            }

            if settings.dataSourceMode == .googleSheets {
                Button(action: { Task { await fetchData() } }) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .help("Refresh Data (Cmd+R)")
                .disabled(isLoading)
            }

            // Show Mode button
            Button(action: { toggleShowMode() }) {
                HStack(spacing: 4) {
                    Image(systemName: showModeState.isActive ? "rectangle.on.rectangle.fill" : "rectangle.on.rectangle")
                        .font(.system(size: 13))
                    if showModeState.isActive {
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
            .buttonStyle(.bordered)
            .help("Show Mode (Cmd+Shift+P)")
        }
    }

    // MARK: - Show Mode Bar

    private var showModeBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(showModeState.isBlacked ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                Text(showModeState.isBlacked ? "OUTPUT: BLACK" : "OUTPUT: LIVE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(showModeState.isBlacked ? .red : .green)
            }

            Spacer()

            Button(action: { showModeState.isBlacked = true }) {
                Text("Go to Black")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .disabled(showModeState.isBlacked)

            Button(action: { showModeState.isBlacked = false }) {
                Text("Show Scoreboard")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .disabled(!showModeState.isBlacked)

            Divider().frame(height: 20)

            Button(action: { toggleShowMode() }) {
                Text("Exit Show Mode")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text(settings.dataSourceMode.displayName)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            if settings.dataSourceMode == .googleSheets {
                Divider().frame(height: 12)
                if let lastUpdated {
                    Text("Last: \(formatTime(lastUpdated))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Text("Next: \(countdown)s")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if let error = errorMessage {
                Divider().frame(height: 12)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange).font(.system(size: 10))
                Text(error)
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }

            Spacer()

            if settings.dataSourceMode == .localManual && hasPendingChanges && settings.pushMode {
                Text("Pending changes")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
            }

            if showModeState.isActive {
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text("SHOW MODE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }

            Text("\(displayPlayers.count) teams")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Show Mode

    private func toggleShowMode() {
        if showModeState.isActive {
            // Exit show mode
            showModeState.isActive = false
            showModeState.isBlacked = false
        } else {
            // Enter show mode — sync current data and open output window
            showModeState.players = displayPlayers
            showModeState.isLoading = isLoading
            showModeState.lastUpdated = lastUpdated
            showModeState.countdown = countdown
            showModeState.isBlacked = false
            showModeState.isActive = true
            openWindow(id: "output")
        }
    }

    // MARK: - Data Fetching (Google Sheets)

    private func fetchData() async {
        guard settings.dataSourceMode == .googleSheets else { return }
        guard !settings.sheetId.isEmpty else {
            displayPlayers = []
            errorMessage = nil
            return
        }
        guard !isFetchInProgress else { return }
        isFetchInProgress = true
        isLoading = true
        errorMessage = nil

        do {
            let result = try await GoogleSheetsService.fetchData(
                sheetInput: settings.sheetId,
                numRounds: settings.numRounds
            )
            displayPlayers = result
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        isFetchInProgress = false
        countdown = Int(settings.refreshInterval)
    }

    private func startAutoRefresh() {
        timer?.invalidate()
        guard settings.dataSourceMode == .googleSheets else { return }
        countdown = Int(settings.refreshInterval)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                countdown = Int(settings.refreshInterval)
                Task { await fetchData() }
            }
        }
    }

    // MARK: - Local Scoring

    private func handleLocalScoreChange() {
        let players = localGame.toPlayerData(numRounds: settings.numRounds)
        if settings.pushMode {
            stagedPlayers = players
            hasPendingChanges = (stagedPlayers != displayPlayers)
        } else {
            displayPlayers = players
            lastUpdated = Date()
            hasPendingChanges = false
        }
    }

    private func pushLocalScores() {
        displayPlayers = stagedPlayers
        lastUpdated = Date()
        hasPendingChanges = false
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
