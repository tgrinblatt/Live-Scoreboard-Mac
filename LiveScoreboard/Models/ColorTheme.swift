import Foundation

/// A named color theme that captures the key appearance settings.
struct ColorTheme: Codable, Identifiable, Equatable {
    var id: String { name.lowercased() }
    var name: String
    var backgroundColor: CodableColor
    var backgroundGradientStart: CodableColor
    var backgroundGradientEnd: CodableColor
    var backgroundMode: AppSettings.BackgroundMode
    var primaryColor: CodableColor
    var secondaryColor: CodableColor
    var accentColor: CodableColor
    var textColor: CodableColor
    var titleColor: CodableColor
    var headerRankColor: CodableColor
    var headerNameColor: CodableColor
    var headerRoundColor: CodableColor
    var headerTotalColor: CodableColor
    var rowColor: CodableColor
    var rowGradientStart: CodableColor
    var rowGradientEnd: CodableColor
    var rowMode: AppSettings.RowColorMode
    var rowOpacity: Double
    var rowRankColor: CodableColor
    var rowNameColor: CodableColor
    var rowRoundColor: CodableColor
    var rowTotalColor: CodableColor

    /// Apply this theme to the given settings
    func apply(to settings: AppSettings) {
        settings.backgroundColor = backgroundColor
        settings.backgroundGradientStart = backgroundGradientStart
        settings.backgroundGradientEnd = backgroundGradientEnd
        settings.backgroundMode = backgroundMode
        settings.primaryColor = primaryColor
        settings.secondaryColor = secondaryColor
        settings.accentColor = accentColor
        settings.textColor = textColor
        settings.titleColor = titleColor
        settings.headerRankColor = headerRankColor
        settings.headerNameColor = headerNameColor
        settings.headerRoundColor = headerRoundColor
        settings.headerTotalColor = headerTotalColor
        settings.rowColor = rowColor
        settings.rowGradientStart = rowGradientStart
        settings.rowGradientEnd = rowGradientEnd
        settings.rowMode = rowMode
        settings.rowOpacity = rowOpacity
        settings.rowRankColor = rowRankColor
        settings.rowNameColor = rowNameColor
        settings.rowRoundColor = rowRoundColor
        settings.rowTotalColor = rowTotalColor
    }

    /// Capture current settings into a theme
    static func capture(from settings: AppSettings, name: String) -> ColorTheme {
        ColorTheme(
            name: name,
            backgroundColor: settings.backgroundColor,
            backgroundGradientStart: settings.backgroundGradientStart,
            backgroundGradientEnd: settings.backgroundGradientEnd,
            backgroundMode: settings.backgroundMode,
            primaryColor: settings.primaryColor,
            secondaryColor: settings.secondaryColor,
            accentColor: settings.accentColor,
            textColor: settings.textColor,
            titleColor: settings.titleColor,
            headerRankColor: settings.headerRankColor,
            headerNameColor: settings.headerNameColor,
            headerRoundColor: settings.headerRoundColor,
            headerTotalColor: settings.headerTotalColor,
            rowColor: settings.rowColor,
            rowGradientStart: settings.rowGradientStart,
            rowGradientEnd: settings.rowGradientEnd,
            rowMode: settings.rowMode,
            rowOpacity: settings.rowOpacity,
            rowRankColor: settings.rowRankColor,
            rowNameColor: settings.rowNameColor,
            rowRoundColor: settings.rowRoundColor,
            rowTotalColor: settings.rowTotalColor
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
        headerRankColor: CodableColor(hex: "#94a3b8"),
        headerNameColor: CodableColor(hex: "#94a3b8"),
        headerRoundColor: CodableColor(hex: "#94a3b8"),
        headerTotalColor: CodableColor(hex: "#94a3b8"),
        rowColor: CodableColor(hex: "#1e293b"),
        rowGradientStart: CodableColor(hex: "#1e293b"),
        rowGradientEnd: CodableColor(hex: "#334155"),
        rowMode: .color,
        rowOpacity: 0.6,
        rowRankColor: CodableColor(.white),
        rowNameColor: CodableColor(.white),
        rowRoundColor: CodableColor(.white),
        rowTotalColor: CodableColor(.white)
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
        headerRankColor: CodableColor(hex: "#666666"),
        headerNameColor: CodableColor(hex: "#666666"),
        headerRoundColor: CodableColor(hex: "#666666"),
        headerTotalColor: CodableColor(hex: "#666666"),
        rowColor: CodableColor(hex: "#1a1a1a"),
        rowGradientStart: CodableColor(hex: "#1a1a1a"),
        rowGradientEnd: CodableColor(hex: "#2a2a2a"),
        rowMode: .color,
        rowOpacity: 0.8,
        rowRankColor: CodableColor(hex: "#cccccc"),
        rowNameColor: CodableColor(hex: "#ffffff"),
        rowRoundColor: CodableColor(hex: "#cccccc"),
        rowTotalColor: CodableColor(hex: "#ffffff")
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
        headerRankColor: CodableColor(hex: "#666666"),
        headerNameColor: CodableColor(hex: "#666666"),
        headerRoundColor: CodableColor(hex: "#666666"),
        headerTotalColor: CodableColor(hex: "#666666"),
        rowColor: CodableColor(hex: "#ffffff"),
        rowGradientStart: CodableColor(hex: "#ffffff"),
        rowGradientEnd: CodableColor(hex: "#f5f5f5"),
        rowMode: .color,
        rowOpacity: 0.9,
        rowRankColor: CodableColor(hex: "#333333"),
        rowNameColor: CodableColor(hex: "#111111"),
        rowRoundColor: CodableColor(hex: "#333333"),
        rowTotalColor: CodableColor(hex: "#111111")
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
        headerRankColor: CodableColor(hex: "#95a5a6"),
        headerNameColor: CodableColor(hex: "#95a5a6"),
        headerRoundColor: CodableColor(hex: "#95a5a6"),
        headerTotalColor: CodableColor(hex: "#95a5a6"),
        rowColor: CodableColor(hex: "#34495e"),
        rowGradientStart: CodableColor(hex: "#34495e"),
        rowGradientEnd: CodableColor(hex: "#2c3e50"),
        rowMode: .color,
        rowOpacity: 0.7,
        rowRankColor: CodableColor(hex: "#ecf0f1"),
        rowNameColor: CodableColor(hex: "#ecf0f1"),
        rowRoundColor: CodableColor(hex: "#bdc3c7"),
        rowTotalColor: CodableColor(hex: "#ecf0f1")
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
