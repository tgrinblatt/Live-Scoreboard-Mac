import SwiftUI

/// Multi-step wizard for setting up a new game session.
/// Steps: Event Info + Rounds → Teams → Confirm & Start
struct GameSetupWizard: View {
    @EnvironmentObject var settings: AppSettings
    var onComplete: (LocalGameState) -> Void
    var onCancel: () -> Void

    @State private var currentStep = 0
    @State private var eventName = ""
    @State private var numRounds = 4
    @State private var roundConfigs: [LocalGameState.RoundConfig] = Array(repeating: .init(), count: 4)
    @State private var teamNames: [String] = []
    @State private var newTeamName = ""
    @State private var bulkText = ""
    @State private var showBulkInput = false

    private let steps = ["Game Setup", "Teams", "Confirm"]

    var body: some View {
        VStack(spacing: 0) {
            wizardHeader
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch currentStep {
                    case 0: stepEventAndRounds
                    case 1: stepTeams
                    case 2: stepConfirm
                    default: EmptyView()
                    }
                }
                .padding(24)
            }

            Divider()
            wizardFooter
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 520, idealHeight: 600)
    }

    // MARK: - Header

    private var wizardHeader: some View {
        VStack(spacing: 12) {
            Text("New Game Setup")
                .font(.system(size: 16, weight: .semibold))

            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { i in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(i <= currentStep ? Color.accentColor : Color(nsColor: .separatorColor))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(i + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(i <= currentStep ? .white : .secondary)
                            )
                        Text(steps[i])
                            .font(.system(size: 11, weight: i == currentStep ? .semibold : .regular))
                            .foregroundColor(i == currentStep ? .primary : .secondary)
                    }
                    if i < steps.count - 1 {
                        Rectangle()
                            .fill(i < currentStep ? Color.accentColor : Color(nsColor: .separatorColor))
                            .frame(height: 1)
                            .frame(maxWidth: 40)
                    }
                }
            }
        }
        .padding(16)
    }

    // MARK: - Step 1: Event Info + Round Configuration (combined)

    private var stepEventAndRounds: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Event name
            VStack(alignment: .leading, spacing: 6) {
                Text("Event / Game Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. Corporate Trivia Night", text: $eventName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                Text("Optional — used for display and save file naming")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Number of rounds
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Rounds")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Stepper("\(numRounds)", value: $numRounds, in: 1...10)
                        .font(.system(size: 14))
                }
                .onChange(of: numRounds) { _, newVal in
                    syncRoundConfigs(to: newVal)
                }
            }

            // Round config table
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Round")
                        .frame(width: 70, alignment: .leading)
                    Text("Points / Answer")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Bonus Points")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)

                Divider()

                // Round rows
                ForEach(0..<roundConfigs.count, id: \.self) { i in
                    HStack {
                        Text("Round \(i + 1)")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 70, alignment: .leading)
                        TextField("", value: $roundConfigs[i].pointsPerAnswer, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                        TextField("", value: $roundConfigs[i].bonusPoints, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(i.isMultiple(of: 2) ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Apply to all button
            Button("Apply Round 1 Values to All") {
                guard let first = roundConfigs.first else { return }
                for i in 0..<roundConfigs.count {
                    roundConfigs[i] = first
                }
            }
            .controlSize(.small)
            .disabled(roundConfigs.count <= 1)
        }
    }

    // MARK: - Step 2: Teams

    private var stepTeams: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Teams")
                    .font(.headline)
                Spacer()
                Text("\(teamNames.count) teams added")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(teamNames.count >= 2 ? .green : .orange)
            }

            Picker("", selection: $showBulkInput) {
                Text("Add One by One").tag(false)
                Text("Bulk Paste").tag(true)
            }
            .pickerStyle(.segmented)

            if showBulkInput {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Paste team names (one per line):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $bulkText)
                        .font(.system(size: 13))
                        .frame(minHeight: 120)
                        .border(Color(nsColor: .separatorColor), width: 1)
                    Button("Add Teams from Text") {
                        let names = bulkText
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        for name in names {
                            if !teamNames.contains(where: { $0.lowercased() == name.lowercased() }) {
                                teamNames.append(name)
                            }
                        }
                        bulkText = ""
                        showBulkInput = false
                    }
                    .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                HStack {
                    TextField("Team name...", text: $newTeamName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTeam() }
                    Button("Add") { addTeam() }
                        .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if !teamNames.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(teamNames.enumerated()), id: \.offset) { index, name in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text(name)
                                .font(.system(size: 13))
                            Spacer()
                            Button(action: { teamNames.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(index.isMultiple(of: 2) ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                    }
                }
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }

            if teamNames.count < 2 {
                Text("Add at least 2 teams to continue.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Step 3: Confirm

    private var stepConfirm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review & Start")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                if !eventName.isEmpty {
                    HStack {
                        Text("Event:").font(.caption).foregroundColor(.secondary).frame(width: 70, alignment: .leading)
                        Text(eventName).font(.system(size: 13, weight: .medium))
                    }
                }

                HStack {
                    Text("Rounds:").font(.caption).foregroundColor(.secondary).frame(width: 70, alignment: .leading)
                    Text("\(numRounds)").font(.system(size: 13, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Point Values:").font(.caption).foregroundColor(.secondary)
                    ForEach(0..<roundConfigs.count, id: \.self) { i in
                        Text("  R\(i + 1): \(Int(roundConfigs[i].pointsPerAnswer)) pts/answer, \(Int(roundConfigs[i].bonusPoints)) bonus")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Teams (\(teamNames.count)):").font(.caption).foregroundColor(.secondary)
                    ForEach(Array(teamNames.enumerated()), id: \.offset) { i, name in
                        Text("  \(i + 1). \(name)")
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Text("The scoreboard will immediately display all teams with starting scores of 0.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Footer

    private var wizardFooter: some View {
        HStack {
            Button("Cancel") { onCancel() }
                .keyboardShortcut(.cancelAction)

            Spacer()

            if currentStep > 0 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
            }

            if currentStep < steps.count - 1 {
                Button("Next") {
                    withAnimation { currentStep += 1 }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canProceed)
            } else {
                Button("Start Game") {
                    startGame()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return numRounds >= 1
        case 1: return teamNames.count >= 2
        default: return true
        }
    }

    // MARK: - Helpers

    private func addTeam() {
        let name = newTeamName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if !teamNames.contains(where: { $0.lowercased() == name.lowercased() }) {
            teamNames.append(name)
        }
        newTeamName = ""
    }

    private func syncRoundConfigs(to count: Int) {
        while roundConfigs.count < count { roundConfigs.append(.init()) }
        if roundConfigs.count > count { roundConfigs = Array(roundConfigs.prefix(count)) }
    }

    private func startGame() {
        let game = LocalGameState()
        game.sessionName = eventName
        game.roundConfigs = roundConfigs
        game.teams = teamNames.map { LocalGameState.Team(name: $0, numRounds: numRounds) }
        game.currentRound = 0
        game.save()

        let meta = SessionMetadata(
            name: eventName,
            numRounds: numRounds,
            numTeams: teamNames.count,
            lastSaved: Date()
        )
        meta.save()

        settings.numRounds = numRounds
        settings.numTeams = teamNames.count
        settings.dataSourceMode = .localManual
        if !eventName.isEmpty {
            settings.title = eventName
        }

        onComplete(game)
    }
}
