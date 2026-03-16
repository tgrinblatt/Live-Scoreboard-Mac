import Foundation

/// Represents a single team/player entry on the scoreboard.
/// Uses team name as stable ID so SwiftUI can track rows across data refreshes.
struct PlayerData: Identifiable, Equatable {
    /// Stable identifier derived from team name (lowercased, trimmed)
    var id: String
    var rank: Int
    var name: String
    var rounds: [Double?]
    var total: Double
    var bonus: Double

    init(name: String, rank: Int = 0, rounds: [Double?] = [], total: Double = 0, bonus: Double = 0) {
        self.id = name.lowercased().trimmingCharacters(in: .whitespaces)
        self.rank = rank
        self.name = name
        self.rounds = rounds
        self.total = total
        self.bonus = bonus
    }
}
