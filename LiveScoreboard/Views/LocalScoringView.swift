import SwiftUI

/// The scoring controller for local manual mode.
/// Shows round tabs, team scoring buttons, and game setup controls.
struct LocalScoringView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var localGame: LocalGameState
    var onScoresChanged: () -> Void
    var onPush: () -> Void

    @State private var isSettingUp = false
    @State private var newTeamName = ""
    @State private var editingCell: EditingCell? = nil
    @State private var editValue: String = ""
    @State private var selectedTeamIndex: Int? = nil
    @State private var showClearConfirm = false

    struct EditingCell: Equatable {
        let teamIndex: Int
        let type: CellType
        enum CellType: Equatable { case score(round: Int), bonus(round: Int) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Scoring Controller")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if !localGame.teams.isEmpty {
                    if showClearConfirm {
                        HStack(spacing: 4) {
                            Text("Clear all scores?")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                            Button("Yes, Clear") {
                                clearAllScores()
                                showClearConfirm = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .controlSize(.small)
                            Button("Cancel") {
                                showClearConfirm = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        Button(action: { showClearConfirm = true }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .help("Clear All Scores")
                    }
                }
                Button(action: { isSettingUp.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .help("Game Setup")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if localGame.teams.isEmpty {
                emptyState
            } else {
                // Round selector tabs
                roundTabs
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                // Round config for current round
                if localGame.roundConfigs.indices.contains(localGame.currentRound) {
                    roundConfigBar
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }

                Divider().padding(.top, 8)

                // Team scoring list
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(localGame.teams.enumerated()), id: \.element.id) { index, team in
                            teamScoringRow(index: index, team: team)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .sheet(isPresented: $isSettingUp) {
            gameSetupSheet
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "gamecontroller")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No Game Set Up")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Configure teams and rounds to start scoring")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Set Up Game") { isSettingUp = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Round Tabs

    private var roundTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(0..<localGame.roundConfigs.count, id: \.self) { i in
                    Button(action: {
                        localGame.currentRound = i
                    }) {
                        Text("R\(i + 1)")
                            .font(.system(size: 11, weight: localGame.currentRound == i ? .bold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(localGame.currentRound == i ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundColor(localGame.currentRound == i ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Round Config Bar

    private var roundConfigBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("Pts/Answer:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("", value: $localGame.roundConfigs[localGame.currentRound].pointsPerAnswer, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 55)
                    .font(.system(size: 11))
            }
            HStack(spacing: 4) {
                Text("Bonus:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("", value: $localGame.roundConfigs[localGame.currentRound].bonusPoints, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 55)
                    .font(.system(size: 11))
            }
            Spacer()
        }
    }

    // MARK: - Team Scoring Row

    private func teamScoringRow(index: Int, team: LocalGameState.Team) -> some View {
        let round = localGame.currentRound
        let score = round < team.roundScores.count ? team.roundScores[round] : 0
        let bonus = round < team.roundBonuses.count ? team.roundBonuses[round] : 0

        return HStack(spacing: 8) {
            // Team name + total
            VStack(alignment: .leading, spacing: 1) {
                Text(team.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("Total: \(formatScore(team.total))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 90, alignment: .leading)

            Spacer()

            // Score controls
            VStack(spacing: 1) {
                Text("Score")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                HStack(spacing: 3) {
                    Button(action: {
                        localGame.subtractPoints(teamIndex: index)
                        onScoresChanged()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)

                    // Editable score cell
                    if editingCell == EditingCell(teamIndex: index, type: .score(round: round)) {
                        TextField("", text: $editValue, onCommit: {
                            if let val = Double(editValue) {
                                localGame.setScore(teamIndex: index, round: round, value: val)
                                onScoresChanged()
                            }
                            editingCell = nil
                        })
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .font(.system(size: 11, design: .monospaced))
                    } else {
                        Text(formatScore(score))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .frame(width: 50)
                            .padding(.vertical, 3)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(4)
                            .onTapGesture {
                                editValue = formatScore(score)
                                editingCell = EditingCell(teamIndex: index, type: .score(round: round))
                            }
                    }

                    Button(action: {
                        localGame.addPoints(teamIndex: index)
                        onScoresChanged()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Bonus controls
            VStack(spacing: 1) {
                Text("Bonus")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                HStack(spacing: 3) {
                    Button(action: {
                        localGame.subtractBonus(teamIndex: index)
                        onScoresChanged()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)

                    if editingCell == EditingCell(teamIndex: index, type: .bonus(round: round)) {
                        TextField("", text: $editValue, onCommit: {
                            if let val = Double(editValue) {
                                localGame.setBonus(teamIndex: index, round: round, value: val)
                                onScoresChanged()
                            }
                            editingCell = nil
                        })
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .font(.system(size: 11, design: .monospaced))
                    } else {
                        Text(formatScore(bonus))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .frame(width: 50)
                            .padding(.vertical, 3)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(4)
                            .onTapGesture {
                                editValue = formatScore(bonus)
                                editingCell = EditingCell(teamIndex: index, type: .bonus(round: round))
                            }
                    }

                    Button(action: {
                        localGame.addBonus(teamIndex: index)
                        onScoresChanged()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            selectedTeamIndex == index
                ? Color.accentColor.opacity(0.1)
                : (index.isMultiple(of: 2) ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture { selectedTeamIndex = index }
    }

    // MARK: - Game Setup Sheet

    private var gameSetupSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Game Setup")
                    .font(.headline)
                Spacer()
                Button("Done") { isSettingUp = false }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Rounds
                    SettingsSection(title: "Rounds") {
                        HStack {
                            Text("Number of Rounds")
                            Stepper("\(localGame.roundConfigs.count)", onIncrement: {
                                localGame.setNumRounds(localGame.roundConfigs.count + 1)
                                settings.numRounds = localGame.roundConfigs.count
                                onScoresChanged()
                            }, onDecrement: {
                                localGame.setNumRounds(max(1, localGame.roundConfigs.count - 1))
                                settings.numRounds = localGame.roundConfigs.count
                                onScoresChanged()
                            })
                        }

                        ForEach(0..<localGame.roundConfigs.count, id: \.self) { i in
                            HStack {
                                Text("Round \(i + 1):")
                                    .font(.caption)
                                    .frame(width: 60, alignment: .leading)
                                Text("Pts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("", value: $localGame.roundConfigs[i].pointsPerAnswer, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                Text("Bonus")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("", value: $localGame.roundConfigs[i].bonusPoints, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                        }
                    }

                    // Teams
                    SettingsSection(title: "Teams (\(localGame.teams.count))") {
                        ForEach(Array(localGame.teams.enumerated()), id: \.element.id) { index, team in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text(team.name)
                                    .font(.system(size: 13))
                                Spacer()
                                Button(action: {
                                    localGame.removeTeam(at: index)
                                    onScoresChanged()
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("Add team name...", text: $newTeamName)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    addTeam()
                                }
                            Button("Add") { addTeam() }
                                .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    // Danger zone
                    SettingsSection(title: "Reset") {
                        Button("Clear All Scores") {
                            let names = localGame.teams.map { $0.name }
                            let rounds = localGame.roundConfigs.count
                            localGame.setupGame(teamNames: names, numRounds: rounds)
                            onScoresChanged()
                        }
                        .foregroundColor(.orange)

                        Button("Reset Entire Game") {
                            localGame.reset()
                            onScoresChanged()
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 440, minHeight: 500)
    }

    // MARK: - Helpers

    private func addTeam() {
        let name = newTeamName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if localGame.roundConfigs.isEmpty {
            localGame.setNumRounds(settings.numRounds)
        }
        localGame.addTeam(name: name)
        newTeamName = ""
        onScoresChanged()
    }

    private func clearAllScores() {
        let names = localGame.teams.map { $0.name }
        let rounds = localGame.roundConfigs.count
        let configs = localGame.roundConfigs
        localGame.setupGame(teamNames: names, numRounds: rounds)
        localGame.roundConfigs = configs // preserve point values
        localGame.save()
        onScoresChanged()
    }

    private func formatScore(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
