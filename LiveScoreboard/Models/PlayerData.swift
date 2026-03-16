import Foundation

struct PlayerData: Identifiable, Equatable {
    let id = UUID()
    var rank: Int
    var name: String
    var rounds: [Double?]
    var total: Double
}
