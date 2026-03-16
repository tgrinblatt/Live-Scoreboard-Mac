import SwiftUI
import Combine

class AppSettings: ObservableObject, Codable {
    // MARK: - Google Sheets Connection
    @Published var sheetId: String = ""
    @Published var title: String = "SCOREBOARD"

    // MARK: - Background
    @Published var backgroundMode: BackgroundMode = .gradient
    @Published var backgroundColor: CodableColor = CodableColor(.blue)
    @Published var backgroundGradientStart: CodableColor = CodableColor(hex: "#0062ff")
    @Published var backgroundGradientEnd: CodableColor = CodableColor(hex: "#00a2ff")

    // MARK: - Logos
    @Published var showLeftLogo: Bool = false
    @Published var leftLogoData: Data? = nil
    @Published var leftImagePadding: Double = 10
    @Published var showRightLogo: Bool = false
    @Published var rightLogoData: Data? = nil
    @Published var rightImagePadding: Double = 10

    // MARK: - Footer
    @Published var showFooterText: Bool = true
    @Published var footerText: String = "GLOBAL BROADCAST FEED // LIVE DATA SYNCHRONIZED"
    @Published var showSyncStatus: Bool = true
    @Published var syncStatusStyle: SyncStatusStyle = .broadcast

    // MARK: - Sync
    @Published var refreshInterval: Double = 5

    // MARK: - Global Colors
    @Published var titleColor: CodableColor = CodableColor(.white)
    @Published var titleSize: Double = 3.0
    @Published var showTitleBar: Bool = true
    @Published var primaryColor: CodableColor = CodableColor(hex: "#001533")
    @Published var secondaryColor: CodableColor = CodableColor(hex: "#1e293b")
    @Published var accentColor: CodableColor = CodableColor(hex: "#334155")
    @Published var textColor: CodableColor = CodableColor(.white)

    // MARK: - Typography
    @Published var fontFamily: String = "SF Pro"
    /// The PostScript name of the specific font member (e.g. "SFPro-Bold", "Helvetica-LightOblique")
    @Published var fontMemberPostScript: String = ""

    // MARK: - Header Colors
    @Published var headerRankColor: CodableColor = CodableColor(hex: "#94a3b8")
    @Published var headerNameColor: CodableColor = CodableColor(hex: "#94a3b8")
    @Published var headerRoundColor: CodableColor = CodableColor(hex: "#94a3b8")
    @Published var headerTotalColor: CodableColor = CodableColor(hex: "#94a3b8")
    @Published var headerFontSize: Double = 65

    // MARK: - Row Design
    @Published var rowMode: RowColorMode = .color
    @Published var rowColor: CodableColor = CodableColor(hex: "#1e293b")
    @Published var rowGradientStart: CodableColor = CodableColor(hex: "#1e293b")
    @Published var rowGradientEnd: CodableColor = CodableColor(hex: "#334155")
    @Published var rowOpacity: Double = 0.6
    @Published var rowShape: RowShape = .notched
    @Published var rowGap: Double = 4

    // MARK: - Row Text
    @Published var rowRankColor: CodableColor = CodableColor(.white)
    @Published var rowRankFontSize: Double = 125
    @Published var rowNameColor: CodableColor = CodableColor(.white)
    @Published var rowNameFontSize: Double = 125
    @Published var rowRoundColor: CodableColor = CodableColor(.white)
    @Published var rowRoundFontSize: Double = 125
    @Published var rowTotalColor: CodableColor = CodableColor(.white)
    @Published var rowTotalFontSize: Double = 125

    // MARK: - Layout
    @Published var numRounds: Int = 4
    @Published var numTeams: Int = 10
    @Published var scoreboardVerticalHeight: Double = 80

    // MARK: - Enums
    enum BackgroundMode: String, Codable, CaseIterable {
        case color, gradient, image
    }

    enum SyncStatusStyle: String, Codable, CaseIterable {
        case broadcast, compact, textOnly = "text-only", micro
    }

    enum RowColorMode: String, Codable, CaseIterable {
        case color, gradient
    }

    enum RowShape: String, Codable, CaseIterable {
        case rectangle, rounded, pill, angled, notched
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case sheetId, title
        case backgroundMode, backgroundColor, backgroundGradientStart, backgroundGradientEnd
        case showLeftLogo, leftLogoData, leftImagePadding
        case showRightLogo, rightLogoData, rightImagePadding
        case showFooterText, footerText, showSyncStatus, syncStatusStyle
        case refreshInterval
        case titleColor, titleSize, showTitleBar
        case primaryColor, secondaryColor, accentColor, textColor
        case fontFamily, fontMemberPostScript
        case headerRankColor, headerNameColor, headerRoundColor, headerTotalColor, headerFontSize
        case rowMode, rowColor, rowGradientStart, rowGradientEnd, rowOpacity, rowShape, rowGap
        case rowRankColor, rowRankFontSize, rowNameColor, rowNameFontSize
        case rowRoundColor, rowRoundFontSize, rowTotalColor, rowTotalFontSize
        case numRounds, numTeams, scoreboardVerticalHeight
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sheetId = (try? c.decode(String.self, forKey: .sheetId)) ?? ""
        title = (try? c.decode(String.self, forKey: .title)) ?? "SCOREBOARD"
        backgroundMode = (try? c.decode(BackgroundMode.self, forKey: .backgroundMode)) ?? .gradient
        backgroundColor = (try? c.decode(CodableColor.self, forKey: .backgroundColor)) ?? CodableColor(.blue)
        backgroundGradientStart = (try? c.decode(CodableColor.self, forKey: .backgroundGradientStart)) ?? CodableColor(hex: "#0062ff")
        backgroundGradientEnd = (try? c.decode(CodableColor.self, forKey: .backgroundGradientEnd)) ?? CodableColor(hex: "#00a2ff")
        showLeftLogo = (try? c.decode(Bool.self, forKey: .showLeftLogo)) ?? false
        leftLogoData = try? c.decode(Data.self, forKey: .leftLogoData)
        leftImagePadding = (try? c.decode(Double.self, forKey: .leftImagePadding)) ?? 10
        showRightLogo = (try? c.decode(Bool.self, forKey: .showRightLogo)) ?? false
        rightLogoData = try? c.decode(Data.self, forKey: .rightLogoData)
        rightImagePadding = (try? c.decode(Double.self, forKey: .rightImagePadding)) ?? 10
        showFooterText = (try? c.decode(Bool.self, forKey: .showFooterText)) ?? true
        footerText = (try? c.decode(String.self, forKey: .footerText)) ?? "GLOBAL BROADCAST FEED // LIVE DATA SYNCHRONIZED"
        showSyncStatus = (try? c.decode(Bool.self, forKey: .showSyncStatus)) ?? true
        syncStatusStyle = (try? c.decode(SyncStatusStyle.self, forKey: .syncStatusStyle)) ?? .broadcast
        refreshInterval = (try? c.decode(Double.self, forKey: .refreshInterval)) ?? 5
        titleColor = (try? c.decode(CodableColor.self, forKey: .titleColor)) ?? CodableColor(.white)
        titleSize = (try? c.decode(Double.self, forKey: .titleSize)) ?? 3.0
        showTitleBar = (try? c.decode(Bool.self, forKey: .showTitleBar)) ?? true
        primaryColor = (try? c.decode(CodableColor.self, forKey: .primaryColor)) ?? CodableColor(hex: "#001533")
        secondaryColor = (try? c.decode(CodableColor.self, forKey: .secondaryColor)) ?? CodableColor(hex: "#1e293b")
        accentColor = (try? c.decode(CodableColor.self, forKey: .accentColor)) ?? CodableColor(hex: "#334155")
        textColor = (try? c.decode(CodableColor.self, forKey: .textColor)) ?? CodableColor(.white)
        fontFamily = (try? c.decode(String.self, forKey: .fontFamily)) ?? "SF Pro"
        fontMemberPostScript = (try? c.decode(String.self, forKey: .fontMemberPostScript)) ?? ""
        headerRankColor = (try? c.decode(CodableColor.self, forKey: .headerRankColor)) ?? CodableColor(hex: "#94a3b8")
        headerNameColor = (try? c.decode(CodableColor.self, forKey: .headerNameColor)) ?? CodableColor(hex: "#94a3b8")
        headerRoundColor = (try? c.decode(CodableColor.self, forKey: .headerRoundColor)) ?? CodableColor(hex: "#94a3b8")
        headerTotalColor = (try? c.decode(CodableColor.self, forKey: .headerTotalColor)) ?? CodableColor(hex: "#94a3b8")
        headerFontSize = (try? c.decode(Double.self, forKey: .headerFontSize)) ?? 65
        rowMode = (try? c.decode(RowColorMode.self, forKey: .rowMode)) ?? .color
        rowColor = (try? c.decode(CodableColor.self, forKey: .rowColor)) ?? CodableColor(hex: "#1e293b")
        rowGradientStart = (try? c.decode(CodableColor.self, forKey: .rowGradientStart)) ?? CodableColor(hex: "#1e293b")
        rowGradientEnd = (try? c.decode(CodableColor.self, forKey: .rowGradientEnd)) ?? CodableColor(hex: "#334155")
        rowOpacity = (try? c.decode(Double.self, forKey: .rowOpacity)) ?? 0.6
        rowShape = (try? c.decode(RowShape.self, forKey: .rowShape)) ?? .notched
        rowGap = (try? c.decode(Double.self, forKey: .rowGap)) ?? 4
        rowRankColor = (try? c.decode(CodableColor.self, forKey: .rowRankColor)) ?? CodableColor(.white)
        rowRankFontSize = (try? c.decode(Double.self, forKey: .rowRankFontSize)) ?? 125
        rowNameColor = (try? c.decode(CodableColor.self, forKey: .rowNameColor)) ?? CodableColor(.white)
        rowNameFontSize = (try? c.decode(Double.self, forKey: .rowNameFontSize)) ?? 125
        rowRoundColor = (try? c.decode(CodableColor.self, forKey: .rowRoundColor)) ?? CodableColor(.white)
        rowRoundFontSize = (try? c.decode(Double.self, forKey: .rowRoundFontSize)) ?? 125
        rowTotalColor = (try? c.decode(CodableColor.self, forKey: .rowTotalColor)) ?? CodableColor(.white)
        rowTotalFontSize = (try? c.decode(Double.self, forKey: .rowTotalFontSize)) ?? 125
        numRounds = (try? c.decode(Int.self, forKey: .numRounds)) ?? 4
        numTeams = (try? c.decode(Int.self, forKey: .numTeams)) ?? 10
        scoreboardVerticalHeight = (try? c.decode(Double.self, forKey: .scoreboardVerticalHeight)) ?? 80
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(sheetId, forKey: .sheetId)
        try c.encode(title, forKey: .title)
        try c.encode(backgroundMode, forKey: .backgroundMode)
        try c.encode(backgroundColor, forKey: .backgroundColor)
        try c.encode(backgroundGradientStart, forKey: .backgroundGradientStart)
        try c.encode(backgroundGradientEnd, forKey: .backgroundGradientEnd)
        try c.encode(showLeftLogo, forKey: .showLeftLogo)
        try c.encodeIfPresent(leftLogoData, forKey: .leftLogoData)
        try c.encode(leftImagePadding, forKey: .leftImagePadding)
        try c.encode(showRightLogo, forKey: .showRightLogo)
        try c.encodeIfPresent(rightLogoData, forKey: .rightLogoData)
        try c.encode(rightImagePadding, forKey: .rightImagePadding)
        try c.encode(showFooterText, forKey: .showFooterText)
        try c.encode(footerText, forKey: .footerText)
        try c.encode(showSyncStatus, forKey: .showSyncStatus)
        try c.encode(syncStatusStyle, forKey: .syncStatusStyle)
        try c.encode(refreshInterval, forKey: .refreshInterval)
        try c.encode(titleColor, forKey: .titleColor)
        try c.encode(titleSize, forKey: .titleSize)
        try c.encode(showTitleBar, forKey: .showTitleBar)
        try c.encode(primaryColor, forKey: .primaryColor)
        try c.encode(secondaryColor, forKey: .secondaryColor)
        try c.encode(accentColor, forKey: .accentColor)
        try c.encode(textColor, forKey: .textColor)
        try c.encode(fontFamily, forKey: .fontFamily)
        try c.encode(fontMemberPostScript, forKey: .fontMemberPostScript)
        try c.encode(headerRankColor, forKey: .headerRankColor)
        try c.encode(headerNameColor, forKey: .headerNameColor)
        try c.encode(headerRoundColor, forKey: .headerRoundColor)
        try c.encode(headerTotalColor, forKey: .headerTotalColor)
        try c.encode(headerFontSize, forKey: .headerFontSize)
        try c.encode(rowMode, forKey: .rowMode)
        try c.encode(rowColor, forKey: .rowColor)
        try c.encode(rowGradientStart, forKey: .rowGradientStart)
        try c.encode(rowGradientEnd, forKey: .rowGradientEnd)
        try c.encode(rowOpacity, forKey: .rowOpacity)
        try c.encode(rowShape, forKey: .rowShape)
        try c.encode(rowGap, forKey: .rowGap)
        try c.encode(rowRankColor, forKey: .rowRankColor)
        try c.encode(rowRankFontSize, forKey: .rowRankFontSize)
        try c.encode(rowNameColor, forKey: .rowNameColor)
        try c.encode(rowNameFontSize, forKey: .rowNameFontSize)
        try c.encode(rowRoundColor, forKey: .rowRoundColor)
        try c.encode(rowRoundFontSize, forKey: .rowRoundFontSize)
        try c.encode(rowTotalColor, forKey: .rowTotalColor)
        try c.encode(rowTotalFontSize, forKey: .rowTotalFontSize)
        try c.encode(numRounds, forKey: .numRounds)
        try c.encode(numTeams, forKey: .numTeams)
        try c.encode(scoreboardVerticalHeight, forKey: .scoreboardVerticalHeight)
    }

    // MARK: - Font helpers

    /// The PostScript name to use for rendering — falls back to family name if no member selected
    var effectiveFontName: String {
        if fontMemberPostScript.isEmpty {
            return fontFamily
        }
        return fontMemberPostScript
    }

    var resolvedFont: Font {
        Font.custom(effectiveFontName, size: 14)
    }

    func scaledFont(baseSize: CGFloat, percentage: Double) -> Font {
        let size = baseSize * CGFloat(percentage) / 100.0
        return Font.custom(effectiveFontName, size: max(size, 1))
    }

    /// Returns all font family names installed on this Mac, sorted alphabetically
    static var availableFonts: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    /// A font member (weight/style variant) within a family
    struct FontMember: Identifiable {
        let id: String          // PostScript name (unique identifier)
        let displayName: String // Human-readable: "Bold Italic", "Light", etc.
        let weight: Int

        var postScriptName: String { id }
    }

    /// Returns all available members (weights/styles) for a given font family
    static func membersForFamily(_ family: String) -> [FontMember] {
        guard let members = NSFontManager.shared.availableMembers(ofFontFamily: family) else {
            return []
        }
        // Each member is [postScriptName, displayName, weight, traits]
        return members.compactMap { member -> FontMember? in
            guard member.count >= 3,
                  let psName = member[0] as? String,
                  let displayName = member[1] as? String,
                  let weight = member[2] as? Int else { return nil }
            return FontMember(
                id: psName,
                displayName: displayName,
                weight: weight
            )
        }
    }

    // MARK: - Persistence
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "LiveScoreboardSettings")
        }
    }

    static func loadFromUserDefaults() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "LiveScoreboardSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
}

// MARK: - CodableColor
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ nsColor: NSColor) {
        let c = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.red = Double(c.redComponent)
        self.green = Double(c.greenComponent)
        self.blue = Double(c.blueComponent)
        self.alpha = Double(c.alphaComponent)
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        self.red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        self.green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        self.blue = Double(rgbValue & 0x0000FF) / 255.0
        self.alpha = 1.0
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
