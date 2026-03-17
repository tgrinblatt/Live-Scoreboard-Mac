import Foundation

/// A named theme that captures appearance settings for the 5 text groups + colors.
struct ColorTheme: Codable, Identifiable, Equatable {
    var id: String { name.lowercased() }
    var name: String
    // Background
    var backgroundColor: CodableColor
    var backgroundGradientStart: CodableColor
    var backgroundGradientEnd: CodableColor
    var backgroundMode: AppSettings.BackgroundMode
    // Global colors
    var primaryColor: CodableColor
    var secondaryColor: CodableColor
    var accentColor: CodableColor
    var textColor: CodableColor
    var titleColor: CodableColor
    // Row appearance
    var rowColor: CodableColor
    var rowGradientStart: CodableColor
    var rowGradientEnd: CodableColor
    var rowMode: AppSettings.RowColorMode
    var rowOpacity: Double
    // 5 text groups
    var headerFontWeight: String?
    var headerColor: CodableColor?
    var rankingFontWeight: String?
    var rankingColor: CodableColor?
    var teamNamesFontWeight: String?
    var teamNamesColor: CodableColor?
    var roundScoresFontWeight: String?
    var roundScoresColor: CodableColor?
    var totalPointsFontWeight: String?
    var totalPointsColor: CodableColor?

    func apply(to s: AppSettings) {
        s.backgroundColor = backgroundColor
        s.backgroundGradientStart = backgroundGradientStart
        s.backgroundGradientEnd = backgroundGradientEnd
        s.backgroundMode = backgroundMode
        s.primaryColor = primaryColor
        s.secondaryColor = secondaryColor
        s.accentColor = accentColor
        s.textColor = textColor
        s.titleColor = titleColor
        s.rowColor = rowColor
        s.rowGradientStart = rowGradientStart
        s.rowGradientEnd = rowGradientEnd
        s.rowMode = rowMode
        s.rowOpacity = rowOpacity
        if let v = headerFontWeight { s.headerFontWeight = v }
        if let v = headerColor { s.headerColor = v }
        if let v = rankingFontWeight { s.rankingFontWeight = v }
        if let v = rankingColor { s.rankingColor = v }
        if let v = teamNamesFontWeight { s.teamNamesFontWeight = v }
        if let v = teamNamesColor { s.teamNamesColor = v }
        if let v = roundScoresFontWeight { s.roundScoresFontWeight = v }
        if let v = roundScoresColor { s.roundScoresColor = v }
        if let v = totalPointsFontWeight { s.totalPointsFontWeight = v }
        if let v = totalPointsColor { s.totalPointsColor = v }
    }

    static func capture(from s: AppSettings, name: String) -> ColorTheme {
        ColorTheme(
            name: name,
            backgroundColor: s.backgroundColor,
            backgroundGradientStart: s.backgroundGradientStart,
            backgroundGradientEnd: s.backgroundGradientEnd,
            backgroundMode: s.backgroundMode,
            primaryColor: s.primaryColor,
            secondaryColor: s.secondaryColor,
            accentColor: s.accentColor,
            textColor: s.textColor,
            titleColor: s.titleColor,
            rowColor: s.rowColor,
            rowGradientStart: s.rowGradientStart,
            rowGradientEnd: s.rowGradientEnd,
            rowMode: s.rowMode,
            rowOpacity: s.rowOpacity,
            headerFontWeight: s.headerFontWeight,
            headerColor: s.headerColor,
            rankingFontWeight: s.rankingFontWeight,
            rankingColor: s.rankingColor,
            teamNamesFontWeight: s.teamNamesFontWeight,
            teamNamesColor: s.teamNamesColor,
            roundScoresFontWeight: s.roundScoresFontWeight,
            roundScoresColor: s.roundScoresColor,
            totalPointsFontWeight: s.totalPointsFontWeight,
            totalPointsColor: s.totalPointsColor
        )
    }

    // MARK: - Built-in themes

    static let builtIn: [ColorTheme] = [broadcastBlue, dark, light, corporateNeutral]

    static let broadcastBlue = ColorTheme(
        name: "Broadcast Blue",
        backgroundColor: CodableColor(hex: "#0062ff"),
        backgroundGradientStart: CodableColor(hex: "#0062ff"),
        backgroundGradientEnd: CodableColor(hex: "#00a2ff"),
        backgroundMode: .gradient,
        primaryColor: CodableColor(hex: "#001533"),
        secondaryColor: CodableColor(hex: "#1e293b"),
        accentColor: CodableColor(hex: "#334155"),
        textColor: CodableColor(.white),
        titleColor: CodableColor(.white),
        rowColor: CodableColor(hex: "#1e293b"),
        rowGradientStart: CodableColor(hex: "#1e293b"),
        rowGradientEnd: CodableColor(hex: "#334155"),
        rowMode: .color,
        rowOpacity: 0.6,
        headerFontWeight: "Semi Bold", headerColor: CodableColor(hex: "#94a3b8"),
        rankingFontWeight: "Bold", rankingColor: CodableColor(.white),
        teamNamesFontWeight: "Regular", teamNamesColor: CodableColor(.white),
        roundScoresFontWeight: "Regular", roundScoresColor: CodableColor(.white),
        totalPointsFontWeight: "Bold", totalPointsColor: CodableColor(.white)
    )

    static let dark = ColorTheme(
        name: "Dark",
        backgroundColor: CodableColor(hex: "#111111"),
        backgroundGradientStart: CodableColor(hex: "#111111"),
        backgroundGradientEnd: CodableColor(hex: "#1a1a2e"),
        backgroundMode: .gradient,
        primaryColor: CodableColor(hex: "#0a0a0a"),
        secondaryColor: CodableColor(hex: "#1a1a1a"),
        accentColor: CodableColor(hex: "#333333"),
        textColor: CodableColor(hex: "#e0e0e0"),
        titleColor: CodableColor(hex: "#ffffff"),
        rowColor: CodableColor(hex: "#1a1a1a"),
        rowGradientStart: CodableColor(hex: "#1a1a1a"),
        rowGradientEnd: CodableColor(hex: "#2a2a2a"),
        rowMode: .color,
        rowOpacity: 0.8,
        headerFontWeight: "Bold", headerColor: CodableColor(hex: "#666666"),
        rankingFontWeight: "Bold", rankingColor: CodableColor(hex: "#cccccc"),
        teamNamesFontWeight: "Regular", teamNamesColor: CodableColor(hex: "#ffffff"),
        roundScoresFontWeight: "Light", roundScoresColor: CodableColor(hex: "#cccccc"),
        totalPointsFontWeight: "Bold", totalPointsColor: CodableColor(hex: "#ffffff")
    )

    static let light = ColorTheme(
        name: "Light",
        backgroundColor: CodableColor(hex: "#f0f2f5"),
        backgroundGradientStart: CodableColor(hex: "#e8edf2"),
        backgroundGradientEnd: CodableColor(hex: "#f0f2f5"),
        backgroundMode: .gradient,
        primaryColor: CodableColor(hex: "#ffffff"),
        secondaryColor: CodableColor(hex: "#f5f5f5"),
        accentColor: CodableColor(hex: "#d0d0d0"),
        textColor: CodableColor(hex: "#1a1a1a"),
        titleColor: CodableColor(hex: "#111111"),
        rowColor: CodableColor(hex: "#ffffff"),
        rowGradientStart: CodableColor(hex: "#ffffff"),
        rowGradientEnd: CodableColor(hex: "#f5f5f5"),
        rowMode: .color,
        rowOpacity: 0.9,
        headerFontWeight: "Medium", headerColor: CodableColor(hex: "#666666"),
        rankingFontWeight: "Semi Bold", rankingColor: CodableColor(hex: "#333333"),
        teamNamesFontWeight: "Regular", teamNamesColor: CodableColor(hex: "#111111"),
        roundScoresFontWeight: "Regular", roundScoresColor: CodableColor(hex: "#333333"),
        totalPointsFontWeight: "Semi Bold", totalPointsColor: CodableColor(hex: "#111111")
    )

    static let corporateNeutral = ColorTheme(
        name: "Corporate Neutral",
        backgroundColor: CodableColor(hex: "#2c3e50"),
        backgroundGradientStart: CodableColor(hex: "#2c3e50"),
        backgroundGradientEnd: CodableColor(hex: "#34495e"),
        backgroundMode: .gradient,
        primaryColor: CodableColor(hex: "#1a252f"),
        secondaryColor: CodableColor(hex: "#2c3e50"),
        accentColor: CodableColor(hex: "#7f8c8d"),
        textColor: CodableColor(hex: "#ecf0f1"),
        titleColor: CodableColor(hex: "#ecf0f1"),
        rowColor: CodableColor(hex: "#34495e"),
        rowGradientStart: CodableColor(hex: "#34495e"),
        rowGradientEnd: CodableColor(hex: "#2c3e50"),
        rowMode: .color,
        rowOpacity: 0.7,
        headerFontWeight: "Medium", headerColor: CodableColor(hex: "#95a5a6"),
        rankingFontWeight: "Medium", rankingColor: CodableColor(hex: "#ecf0f1"),
        teamNamesFontWeight: "Regular", teamNamesColor: CodableColor(hex: "#ecf0f1"),
        roundScoresFontWeight: "Regular", roundScoresColor: CodableColor(hex: "#bdc3c7"),
        totalPointsFontWeight: "Medium", totalPointsColor: CodableColor(hex: "#ecf0f1")
    )

    // MARK: - Custom theme persistence

    private static var customThemesURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LiveScoreboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom-themes.json")
    }

    static func loadCustomThemes() -> [ColorTheme] {
        guard let data = try? Data(contentsOf: customThemesURL),
              let themes = try? JSONDecoder().decode([ColorTheme].self, from: data) else {
            return []
        }
        return themes
    }

    static func saveCustomThemes(_ themes: [ColorTheme]) {
        guard let data = try? JSONEncoder().encode(themes) else { return }
        try? data.write(to: customThemesURL)
    }
}
