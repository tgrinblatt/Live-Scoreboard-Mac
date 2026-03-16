import Foundation
import Combine

/// Manages the state of a locally-scored game (teams, scores, round configs).
/// Persists automatically to the app's Application Support directory.
class LocalGameState: ObservableObject, Codable {
    @Published var teams: [Team] = []
    @Published var roundConfigs: [RoundConfig] = []
    @Published var currentRound: Int = 0

    struct Team: Identifiable, Codable, Equatable {
        var name: String
        var roundScores: [Double]
        var roundBonuses: [Double]

        var id: String { name.lowercased().trimmingCharacters(in: .whitespaces) }

        var total: Double {
            roundScores.reduce(0, +) + roundBonuses.reduce(0, +)
        }

        mutating func ensureRounds(_ count: Int) {
            while roundScores.count < count { roundScores.append(0) }
            while roundBonuses.count < count { roundBonuses.append(0) }
        }

        init(name: String, numRounds: Int = 4) {
            self.name = name
            self.roundScores = Array(repeating: 0, count: numRounds)
            self.roundBonuses = Array(repeating: 0, count: numRounds)
        }
    }

    struct RoundConfig: Codable, Equatable {
        var pointsPerAnswer: Double = 10
        var bonusPoints: Double = 25
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case teams, roundConfigs, currentRound
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        teams = (try? c.decode([Team].self, forKey: .teams)) ?? []
        roundConfigs = (try? c.decode([RoundConfig].self, forKey: .roundConfigs)) ?? []
        currentRound = (try? c.decode(Int.self, forKey: .currentRound)) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(teams, forKey: .teams)
        try c.encode(roundConfigs, forKey: .roundConfigs)
        try c.encode(currentRound, forKey: .currentRound)
    }

    // MARK: - Setup

    func setupGame(teamNames: [String], numRounds: Int) {
        roundConfigs = (0..<numRounds).map { _ in RoundConfig() }
        teams = teamNames.map { Team(name: $0, numRounds: numRounds) }
        currentRound = 0
        save()
    }

    func addTeam(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let numRounds = roundConfigs.count
        teams.append(Team(name: name, numRounds: max(numRounds, 1)))
        save()
    }

    func removeTeam(at index: Int) {
        guard teams.indices.contains(index) else { return }
        teams.remove(at: index)
        save()
    }

    func setNumRounds(_ count: Int) {
        let clamped = max(1, min(count, 10))
        while roundConfigs.count < clamped { roundConfigs.append(RoundConfig()) }
        if roundConfigs.count > clamped { roundConfigs = Array(roundConfigs.prefix(clamped)) }
        for i in 0..<teams.count {
            teams[i].ensureRounds(clamped)
        }
        if currentRound >= clamped { currentRound = clamped - 1 }
        save()
    }

    // MARK: - Scoring

    /// Add one "answer" worth of points to a team for the current round
    func addPoints(teamIndex: Int) {
        guard teams.indices.contains(teamIndex),
              roundConfigs.indices.contains(currentRound) else { return }
        teams[teamIndex].roundScores[currentRound] += roundConfigs[currentRound].pointsPerAnswer
        save()
    }

    /// Subtract one "answer" worth of points from a team for the current round
    func subtractPoints(teamIndex: Int) {
        guard teams.indices.contains(teamIndex),
              roundConfigs.indices.contains(currentRound) else { return }
        teams[teamIndex].roundScores[currentRound] -= roundConfigs[currentRound].pointsPerAnswer
        save()
    }

    /// Add bonus points to a team for the current round
    func addBonus(teamIndex: Int) {
        guard teams.indices.contains(teamIndex),
              roundConfigs.indices.contains(currentRound) else { return }
        teams[teamIndex].roundBonuses[currentRound] += roundConfigs[currentRound].bonusPoints
        save()
    }

    /// Subtract bonus points from a team for the current round
    func subtractBonus(teamIndex: Int) {
        guard teams.indices.contains(teamIndex),
              roundConfigs.indices.contains(currentRound) else { return }
        teams[teamIndex].roundBonuses[currentRound] -= roundConfigs[currentRound].bonusPoints
        save()
    }

    /// Set an exact score value for a team in a specific round
    func setScore(teamIndex: Int, round: Int, value: Double) {
        guard teams.indices.contains(teamIndex),
              teams[teamIndex].roundScores.indices.contains(round) else { return }
        teams[teamIndex].roundScores[round] = value
        save()
    }

    /// Set an exact bonus value for a team in a specific round
    func setBonus(teamIndex: Int, round: Int, value: Double) {
        guard teams.indices.contains(teamIndex),
              teams[teamIndex].roundBonuses.indices.contains(round) else { return }
        teams[teamIndex].roundBonuses[round] = value
        save()
    }

    // MARK: - Convert to PlayerData

    func toPlayerData(numRounds: Int) -> [PlayerData] {
        var players = teams.map { team -> PlayerData in
            let rounds: [Double?] = (0..<numRounds).map { i in
                if i < team.roundScores.count {
                    let score = team.roundScores[i]
                    let bonus = i < team.roundBonuses.count ? team.roundBonuses[i] : 0
                    return score + bonus
                }
                return nil
            }
            let totalBonus = team.roundBonuses.reduce(0, +)
            return PlayerData(
                name: team.name,
                rounds: rounds,
                total: team.total,
                bonus: totalBonus
            )
        }
        players.sort { $0.total > $1.total }
        for i in 0..<players.count {
            players[i].rank = i + 1
        }
        return players
    }

    // MARK: - Persistence

    private static var saveURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LiveScoreboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("local-game.json")
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.saveURL)
    }

    static func load() -> LocalGameState? {
        guard let data = try? Data(contentsOf: saveURL),
              let state = try? JSONDecoder().decode(LocalGameState.self, from: data) else {
            return nil
        }
        return state
    }

    func reset() {
        teams = []
        roundConfigs = []
        currentRound = 0
        try? FileManager.default.removeItem(at: Self.saveURL)
    }
}
