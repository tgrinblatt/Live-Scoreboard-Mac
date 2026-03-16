import AppKit
import UniformTypeIdentifiers

class SettingsManager {

    /// Export settings to a JSON file using save panel
    static func exportSettings(_ settings: AppSettings) {
        let panel = NSSavePanel()
        panel.title = "Export Scoreboard Configuration"
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "scoreboard-config.json"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(settings)
                try data.write(to: url)
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    /// Import settings from a JSON file using open panel
    static func importSettings(into settings: AppSettings) {
        let panel = NSOpenPanel()
        panel.title = "Import Scoreboard Configuration"
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try Data(contentsOf: url)
                let loaded = try JSONDecoder().decode(AppSettings.self, from: data)
                DispatchQueue.main.async {
                    applySettings(from: loaded, to: settings)
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Import Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    /// Copy all properties from one settings object to another
    static func applySettings(from source: AppSettings, to target: AppSettings) {
        target.dataSourceMode = source.dataSourceMode
        target.sheetId = source.sheetId
        target.pushMode = source.pushMode
        target.title = source.title
        target.titleColor = source.titleColor
        target.titleSize = source.titleSize
        target.showTitleBar = source.showTitleBar
        target.backgroundMode = source.backgroundMode
        target.backgroundColor = source.backgroundColor
        target.backgroundGradientStart = source.backgroundGradientStart
        target.backgroundGradientEnd = source.backgroundGradientEnd
        target.showLeftLogo = source.showLeftLogo
        target.leftImagePadding = source.leftImagePadding
        target.showRightLogo = source.showRightLogo
        target.rightImagePadding = source.rightImagePadding
        target.showFooterText = source.showFooterText
        target.footerText = source.footerText
        target.showSyncStatus = source.showSyncStatus
        target.syncStatusStyle = source.syncStatusStyle
        target.refreshInterval = source.refreshInterval
        target.primaryColor = source.primaryColor
        target.secondaryColor = source.secondaryColor
        target.accentColor = source.accentColor
        target.textColor = source.textColor
        target.fontFamily = source.fontFamily
        target.fontMemberPostScript = source.fontMemberPostScript
        target.headerRankColor = source.headerRankColor
        target.headerNameColor = source.headerNameColor
        target.headerRoundColor = source.headerRoundColor
        target.headerTotalColor = source.headerTotalColor
        target.headerFontSize = source.headerFontSize
        target.rowMode = source.rowMode
        target.rowColor = source.rowColor
        target.rowGradientStart = source.rowGradientStart
        target.rowGradientEnd = source.rowGradientEnd
        target.rowOpacity = source.rowOpacity
        target.rowShape = source.rowShape
        target.rowGap = source.rowGap
        target.rowRankColor = source.rowRankColor
        target.rowRankFontSize = source.rowRankFontSize
        target.rowNameColor = source.rowNameColor
        target.rowNameFontSize = source.rowNameFontSize
        target.rowRoundColor = source.rowRoundColor
        target.rowRoundFontSize = source.rowRoundFontSize
        target.rowTotalColor = source.rowTotalColor
        target.rowTotalFontSize = source.rowTotalFontSize
        target.numRounds = source.numRounds
        target.numTeams = source.numTeams
        target.scoreboardVerticalHeight = source.scoreboardVerticalHeight
        target.outputWidth = source.outputWidth
        target.outputHeight = source.outputHeight
    }

    /// Pick an image file and save it as a logo
    static func pickLogo(side: AppSettings.LogoSide, completion: @escaping (Bool) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Choose Logo Image"
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let data = try? Data(contentsOf: url) else {
                completion(false)
                return
            }
            AppSettings.saveLogoFile(data, side: side)
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
}
