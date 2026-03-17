import SwiftUI
import UniformTypeIdentifiers

/// Main operator window: startup screen → wizard → operator interface.
struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var showModeState: ShowModeState

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
    @State private var appState: AppLaunchState = .startup
    @State private var showNewGameWizard = false
    @State private var showDisplayPicker = false

    enum AppLaunchState {
        case startup   // Show StartupView
        case active    // Show main operator UI
    }

    // MARK: - Timer & fetch guard
    @State private var timer: Timer? = nil
    @State private var isFetchInProgress = false

    // MARK: - Local scoring
    @StateObject private var localGame = LocalGameState.load() ?? LocalGameState()

    var body: some View {
        Group {
            switch appState {
            case .startup:
                StartupView(
                    onNewSession: {
                        showNewGameWizard = true
                    },
                    onResume: {
                        // localGame already loaded from disk via StateObject init
                        settings.dataSourceMode = .localManual
                        // Force-populate display immediately
                        let players = localGame.toPlayerData(numRounds: settings.numRounds)
                        displayPlayers = players
                        stagedPlayers = players
                        lastUpdated = Date()
                        hasPendingChanges = false
                        appState = .active
                    },
                    onLoadFile: {
                        loadGameFromFile()
                    }
                )
                .environmentObject(settings)
                .sheet(isPresented: $showNewGameWizard) {
                    GameSetupWizard(
                        onComplete: { newGame in
                            applyLoadedGame(newGame)
                            showNewGameWizard = false
                            appState = .active
                        },
                        onCancel: {
                            showNewGameWizard = false
                        }
                    )
                    .environmentObject(settings)
                }

            case .active:
                operatorView
            }
        }
        .onAppear {
            // Auto-resume if preference is set and a saved session exists
            if UserDefaults.standard.bool(forKey: "alwaysResume"),
               LocalGameState.load() != nil {
                settings.dataSourceMode = .localManual
                let players = localGame.toPlayerData(numRounds: settings.numRounds)
                displayPlayers = players
                stagedPlayers = players
                lastUpdated = Date()
                hasPendingChanges = false
                appState = .active
            }
        }
    }

    // MARK: - Main Operator View

    private var operatorView: some View {
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
                    scaledPreview(
                        ScoreboardView(
                            players: Array(displayPlayers.prefix(settings.numTeams)),
                            isLoading: isLoading,
                            lastUpdated: lastUpdated,
                            countdown: countdown,
                            errorMessage: errorMessage
                        )
                        .environmentObject(settings)
                    )

                case .localManual:
                    HSplitView {
                        LocalScoringView(
                            localGame: localGame,
                            onScoresChanged: { handleLocalScoreChange() },
                            onPush: { pushLocalScores() }
                        )
                        .environmentObject(settings)
                        .frame(minWidth: 380, idealWidth: 420)

                        scaledPreview(
                            ScoreboardView(
                                players: Array(displayPlayers.prefix(settings.numTeams)),
                                isLoading: false,
                                lastUpdated: lastUpdated,
                                countdown: 0,
                                errorMessage: nil
                            )
                            .environmentObject(settings)
                        )
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
        .sheet(isPresented: $showNewGameWizard) {
            GameSetupWizard(
                onComplete: { newGame in
                    applyLoadedGame(newGame)
                    showNewGameWizard = false
                },
                onCancel: {
                    showNewGameWizard = false
                }
            )
            .environmentObject(settings)
        }
        .sheet(isPresented: $showDisplayPicker) {
            DisplayPickerView(
                onSelect: { screen in
                    showDisplayPicker = false
                    startPresentation(on: screen)
                },
                onCancel: {
                    showDisplayPicker = false
                }
            )
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

            // New Game button
            if settings.dataSourceMode == .localManual {
                Button(action: { showNewGameWizard = true }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .help("New Game")
            }

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
            showModeState.presentationController.close()
            showModeState.isActive = false
            showModeState.isBlacked = false
        } else {
            if NSScreen.screens.count > 1 {
                // Multiple monitors — let the operator choose
                showDisplayPicker = true
            } else {
                // Single monitor — go directly
                startPresentation(on: NSScreen.main)
            }
        }
    }

    private func startPresentation(on screen: NSScreen?) {
        showModeState.players = displayPlayers
        showModeState.isLoading = isLoading
        showModeState.lastUpdated = lastUpdated
        showModeState.countdown = countdown
        showModeState.isBlacked = false
        showModeState.isActive = true

        let outputView = OutputWindowView(
            players: $showModeState.players,
            isLoading: $showModeState.isLoading,
            lastUpdated: $showModeState.lastUpdated,
            countdown: $showModeState.countdown,
            isBlacked: $showModeState.isBlacked
        )
        .environmentObject(settings)
        .environmentObject(showModeState)

        showModeState.presentationController.open(
            content: outputView,
            on: screen,
            onEscape: { [weak showModeState] in
                showModeState?.presentationController.close()
                showModeState?.isActive = false
                showModeState?.isBlacked = false
            }
        )
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

    // MARK: - Scaled Preview

    /// Renders the scoreboard at the full output resolution then scales it down
    /// to fit the available container space — pixel-accurate preview.
    private func scaledPreview<V: View>(_ content: V) -> some View {
        GeometryReader { geo in
            let outW = CGFloat(settings.outputWidth)
            let outH = CGFloat(settings.outputHeight)
            let scaleX = geo.size.width / outW
            let scaleY = geo.size.height / outH
            let scale = min(scaleX, scaleY)

            ZStack {
                Color(nsColor: .windowBackgroundColor)

                content
                    .frame(width: outW, height: outH)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)

                // Preview label
                VStack {
                    HStack {
                        Text("PREVIEW")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(3)
                            .padding(6)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Game Loading

    private func applyLoadedGame(_ game: LocalGameState) {
        // Replace the current local game state
        localGame.teams = game.teams
        localGame.roundConfigs = game.roundConfigs
        localGame.currentRound = game.currentRound
        localGame.sessionName = game.sessionName
        localGame.save()
        settings.dataSourceMode = .localManual
        settings.numRounds = game.roundConfigs.count
        settings.numTeams = game.teams.count
        // Force-populate the scoreboard immediately, bypassing push mode.
        // Push mode gates score *edits* during gameplay, not the initial board state.
        let players = localGame.toPlayerData(numRounds: settings.numRounds)
        displayPlayers = players
        stagedPlayers = players
        lastUpdated = Date()
        hasPendingChanges = false
    }

    private func loadGameFromFile() {
        let panel = NSOpenPanel()
        panel.title = "Load Game File"
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let data = try? Data(contentsOf: url),
                  let game = try? JSONDecoder().decode(LocalGameState.self, from: data) else { return }
            DispatchQueue.main.async {
                applyLoadedGame(game)
                appState = .active
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
