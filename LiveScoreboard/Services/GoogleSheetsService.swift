import Foundation

class GoogleSheetsService {

    enum SheetError: LocalizedError {
        case invalidURL
        case privateSheet
        case networkError(String)
        case noData
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Google Sheets URL or ID"
            case .privateSheet: return "Sheet appears to be private. Make sure it's shared as 'Anyone with the link'"
            case .networkError(let msg): return "Network error: \(msg)"
            case .noData: return "No entries found in sheet"
            case .parseError(let msg): return "Parse error: \(msg)"
            }
        }
    }

    /// Convert various Google Sheets URL formats to a CSV export URL
    static func buildCSVURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var sheetId: String?
        var gid: String = "0"

        // Format 1: Published 2PACX links
        if trimmed.contains("2PACX-") {
            // Already a published URL, use directly
            return URL(string: trimmed)
        }

        // Format 2: Standard share/edit URLs
        if let range = trimmed.range(of: "/spreadsheets/d/") {
            let afterD = trimmed[range.upperBound...]
            if let slashIndex = afterD.firstIndex(of: "/") {
                sheetId = String(afterD[afterD.startIndex..<slashIndex])
            } else {
                sheetId = String(afterD)
            }
            // Extract gid if present
            if let gidRange = trimmed.range(of: "gid=") {
                let afterGid = trimmed[gidRange.upperBound...]
                if let ampIndex = afterGid.firstIndex(of: "&") {
                    gid = String(afterGid[afterGid.startIndex..<ampIndex])
                } else {
                    gid = String(afterGid).trimmingCharacters(in: .init(charactersIn: "#/"))
                }
            }
        }

        // Format 3: Raw ID (at least 20 chars, alphanumeric + dashes/underscores)
        if sheetId == nil && trimmed.count >= 20 {
            let idPattern = trimmed.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression)
            if idPattern != nil {
                sheetId = trimmed
            }
        }

        guard let id = sheetId else { return nil }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let urlString = "https://docs.google.com/spreadsheets/d/\(id)/export?format=csv&gid=\(gid)&cb=\(timestamp)"
        return URL(string: urlString)
    }

    /// Fetch and parse leaderboard data from a Google Sheet
    static func fetchData(sheetInput: String, numRounds: Int) async throws -> [PlayerData] {
        guard let url = buildCSVURL(from: sheetInput) else {
            throw SheetError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 403 || httpResponse.statusCode == 401 {
                throw SheetError.privateSheet
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw SheetError.networkError("HTTP \(httpResponse.statusCode)")
            }
        }

        guard let csvString = String(data: data, encoding: .utf8) else {
            throw SheetError.parseError("Could not decode response as text")
        }

        // Check if we got HTML back (private sheet redirect)
        if csvString.contains("<!DOCTYPE html>") || csvString.contains("<html") {
            throw SheetError.privateSheet
        }

        return parseCSV(csvString, numRounds: numRounds)
    }

    /// Parse CSV string into PlayerData array
    static func parseCSV(_ csv: String, numRounds: Int) -> [PlayerData] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { return [] }

        let headers = parseCSVRow(lines[0]).map { $0.uppercased().trimmingCharacters(in: .whitespaces) }

        // Find column indices
        let nameIndex = headers.firstIndex(where: { ["NAME", "TEAM", "PLAYER"].contains($0) }) ?? 0
        let totalIndex = headers.firstIndex(where: { $0 == "TOTAL" })

        // Find round columns
        var roundIndices: [Int] = []
        for i in 1...min(numRounds, 10) {
            if let idx = headers.firstIndex(where: { $0 == "R\(i)" || $0 == "ROUND \(i)" || $0 == "ROUND\(i)" }) {
                roundIndices.append(idx)
            }
        }

        // If no explicit round columns found, try to use columns after name
        if roundIndices.isEmpty {
            let startCol = nameIndex + 1
            let endCol = totalIndex ?? headers.count
            for i in startCol..<min(startCol + numRounds, endCol) {
                if i < headers.count {
                    roundIndices.append(i)
                }
            }
        }

        var players: [PlayerData] = []

        for i in 1..<lines.count {
            let cells = parseCSVRow(lines[i])
            guard cells.count > nameIndex else { continue }

            let name = cells[nameIndex].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }

            var rounds: [Double?] = []
            for idx in roundIndices {
                if idx < cells.count {
                    let val = cells[idx].trimmingCharacters(in: .whitespaces)
                    rounds.append(Double(val.filter { $0.isNumber || $0 == "." || $0 == "-" }))
                } else {
                    rounds.append(nil)
                }
            }

            // Pad rounds to numRounds
            while rounds.count < numRounds {
                rounds.append(nil)
            }

            let total: Double
            if let ti = totalIndex, ti < cells.count {
                let val = cells[ti].trimmingCharacters(in: .whitespaces)
                total = Double(val.filter { $0.isNumber || $0 == "." || $0 == "-" }) ?? rounds.compactMap { $0 }.reduce(0, +)
            } else {
                total = rounds.compactMap { $0 }.reduce(0, +)
            }

            players.append(PlayerData(rank: 0, name: name, rounds: rounds, total: total))
        }

        // Sort by total descending and assign ranks
        players.sort { $0.total > $1.total }
        for i in 0..<players.count {
            players[i].rank = i + 1
        }

        return players
    }

    /// Parse a single CSV row, respecting quoted fields
    static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)

        return fields.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
}
