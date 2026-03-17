import SwiftUI

/// Settings panel — designed to live in a sidebar alongside the scoreboard.
/// No modal wrapper; embedded directly in an HSplitView by ContentView.
struct AdminPanelView: View {
    @EnvironmentObject var settings: AppSettings
    var onRefresh: () -> Void

    @State private var selectedTab = 0
    @State private var leftLogoImage: NSImage? = AppSettings.loadLogoImage(side: .left)
    @State private var rightLogoImage: NSImage? = AppSettings.loadLogoImage(side: .right)
    @State private var customThemes: [ColorTheme] = ColorTheme.loadCustomThemes()
    @State private var newThemeName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Content").tag(0)
                Text("Design").tag(1)
                Text("System").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0: contentTab
                    case 1: designTab
                    case 2: systemTab
                    default: EmptyView()
                    }
                }
                .padding(12)
            }
        }
    }

    // MARK: - Content Tab

    private var contentTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Data Source
            if settings.dataSourceMode == .googleSheets {
                SettingsSection(title: "Google Sheets") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sheet Link or ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("Paste Google Sheets URL or ID...", text: $settings.sheetId)
                                .textFieldStyle(.roundedBorder)
                            Button(action: onRefresh) {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
            }

            // Title
            SettingsSection(title: "Title") {
                TextField("Scoreboard Title", text: $settings.title)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Text("Size")
                    Slider(value: $settings.titleSize, in: 1...12, step: 0.5)
                    Text(String(format: "%.1f", settings.titleSize))
                        .monospacedDigit()
                        .frame(width: 30)
                }
                ColorSettingRow(label: "Title Color", color: $settings.titleColor)
                Toggle("Show Title Bar", isOn: $settings.showTitleBar)
            }

            // Logos
            SettingsSection(title: "Logos") {
                VStack(alignment: .leading, spacing: 8) {
                    // Left logo
                    Toggle("Left Logo", isOn: $settings.showLeftLogo)
                    if settings.showLeftLogo {
                        HStack {
                            if let img = leftLogoImage {
                                Image(nsImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(4)
                            }
                            Button("Choose...") {
                                SettingsManager.pickLogo(side: .left) { success in
                                    if success {
                                        leftLogoImage = AppSettings.loadLogoImage(side: .left)
                                    }
                                }
                            }
                            if leftLogoImage != nil {
                                Button("Remove") {
                                    AppSettings.removeLogoFile(side: .left)
                                    leftLogoImage = nil
                                }
                                .foregroundColor(.red)
                            }
                        }
                        HStack {
                            Text("Padding")
                                .font(.caption)
                            Slider(value: $settings.leftImagePadding, in: 0...50)
                        }
                    }

                    Divider()

                    // Right logo
                    Toggle("Right Logo", isOn: $settings.showRightLogo)
                    if settings.showRightLogo {
                        HStack {
                            if let img = rightLogoImage {
                                Image(nsImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(4)
                            }
                            Button("Choose...") {
                                SettingsManager.pickLogo(side: .right) { success in
                                    if success {
                                        rightLogoImage = AppSettings.loadLogoImage(side: .right)
                                    }
                                }
                            }
                            if rightLogoImage != nil {
                                Button("Remove") {
                                    AppSettings.removeLogoFile(side: .right)
                                    rightLogoImage = nil
                                }
                                .foregroundColor(.red)
                            }
                        }
                        HStack {
                            Text("Padding")
                                .font(.caption)
                            Slider(value: $settings.rightImagePadding, in: 0...50)
                        }
                    }
                }
            }

            // Footer
            SettingsSection(title: "Footer") {
                Toggle("Show Footer Text", isOn: $settings.showFooterText)
                if settings.showFooterText {
                    TextField("Footer Text", text: $settings.footerText)
                        .textFieldStyle(.roundedBorder)
                }
                if settings.dataSourceMode == .googleSheets {
                    Toggle("Show Sync Status", isOn: $settings.showSyncStatus)
                    if settings.showSyncStatus {
                        Picker("Style", selection: $settings.syncStatusStyle) {
                            Text("Broadcast").tag(AppSettings.SyncStatusStyle.broadcast)
                            Text("Compact").tag(AppSettings.SyncStatusStyle.compact)
                            Text("Text Only").tag(AppSettings.SyncStatusStyle.textOnly)
                            Text("Micro").tag(AppSettings.SyncStatusStyle.micro)
                        }
                    }
                } else {
                    Text("Sync status is only available in Google Sheets mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Layout
            SettingsSection(title: "Layout") {
                HStack {
                    Text("Rounds")
                    Stepper("\(settings.numRounds)", value: $settings.numRounds, in: 1...10)
                }
                HStack {
                    Text("Teams Shown")
                    Stepper("\(settings.numTeams)", value: $settings.numTeams, in: 1...20)
                }
                HStack {
                    Text("Vertical Height %")
                    Slider(value: $settings.scoreboardVerticalHeight, in: 40...100, step: 5)
                    Text("\(Int(settings.scoreboardVerticalHeight))%")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
        }
    }

    // MARK: - Design Tab

    private var designTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Color Themes
            SettingsSection(title: "Color Themes") {
                Text("Built-in").font(.caption).foregroundColor(.secondary)
                HStack(spacing: 6) {
                    ForEach(ColorTheme.builtIn) { theme in
                        Button(action: { theme.apply(to: settings) }) {
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [theme.backgroundGradientStart.color, theme.backgroundGradientEnd.color],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 36, height: 24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                                    )
                                Text(theme.name)
                                    .font(.system(size: 8))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !customThemes.isEmpty {
                    Text("Custom").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        ForEach(customThemes) { theme in
                            Button(action: { theme.apply(to: settings) }) {
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(
                                            colors: [theme.backgroundGradientStart.color, theme.backgroundGradientEnd.color],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 36, height: 24)
                                    Text(theme.name)
                                        .font(.system(size: 8))
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete") {
                                    customThemes.removeAll { $0.id == theme.id }
                                    ColorTheme.saveCustomThemes(customThemes)
                                }
                            }
                        }
                    }
                }

                HStack {
                    TextField("Theme name...", text: $newThemeName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                    Button("Save Current") {
                        let name = newThemeName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        let theme = ColorTheme.capture(from: settings, name: name)
                        customThemes.removeAll { $0.id == theme.id }
                        customThemes.append(theme)
                        ColorTheme.saveCustomThemes(customThemes)
                        newThemeName = ""
                    }
                    .disabled(newThemeName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .controlSize(.small)
                }
            }

            // Background
            SettingsSection(title: "Background") {
                Picker("Mode", selection: $settings.backgroundMode) {
                    Text("Color").tag(AppSettings.BackgroundMode.color)
                    Text("Gradient").tag(AppSettings.BackgroundMode.gradient)
                }
                .pickerStyle(.segmented)

                switch settings.backgroundMode {
                case .color:
                    ColorSettingRow(label: "Color", color: $settings.backgroundColor)
                case .gradient:
                    ColorSettingRow(label: "Start", color: $settings.backgroundGradientStart)
                    ColorSettingRow(label: "End", color: $settings.backgroundGradientEnd)
                case .image:
                    Text("Background images coming soon")
                        .foregroundColor(.secondary)
                }
            }

            // Typography — font family only, weights are per-element below
            SettingsSection(title: "Typography") {
                FontFamilyPicker(selectedFamily: $settings.fontFamily)
            }

            // Global Colors
            SettingsSection(title: "Global Colors") {
                ColorSettingRow(label: "Primary", color: $settings.primaryColor)
                ColorSettingRow(label: "Secondary", color: $settings.secondaryColor)
                ColorSettingRow(label: "Accent", color: $settings.accentColor)
                ColorSettingRow(label: "Text", color: $settings.textColor)
            }

            // Text Groups — 5 unified groups
            SettingsSection(title: "Text Groups") {
                TextGroupControl(label: "Header", fontWeight: $settings.headerFontWeight, color: $settings.headerColor, fontSize: $settings.headerFontSize, availableWeights: settings.availableWeightNames)
                Divider()
                TextGroupControl(label: "Ranking", fontWeight: $settings.rankingFontWeight, color: $settings.rankingColor, fontSize: $settings.rankingFontSize, availableWeights: settings.availableWeightNames)
                Divider()
                TextGroupControl(label: "Team Names", fontWeight: $settings.teamNamesFontWeight, color: $settings.teamNamesColor, fontSize: $settings.teamNamesFontSize, availableWeights: settings.availableWeightNames)
                Divider()
                TextGroupControl(label: "Round Scores", fontWeight: $settings.roundScoresFontWeight, color: $settings.roundScoresColor, fontSize: $settings.roundScoresFontSize, availableWeights: settings.availableWeightNames)
                Divider()
                TextGroupControl(label: "Total Points", fontWeight: $settings.totalPointsFontWeight, color: $settings.totalPointsColor, fontSize: $settings.totalPointsFontSize, availableWeights: settings.availableWeightNames)
            }

            // Row Design
            SettingsSection(title: "Row Design") {
                Picker("Shape", selection: $settings.rowShape) {
                    Text("Rectangle").tag(AppSettings.RowShape.rectangle)
                    Text("Rounded").tag(AppSettings.RowShape.rounded)
                    Text("Pill").tag(AppSettings.RowShape.pill)
                    Text("Angled").tag(AppSettings.RowShape.angled)
                    Text("Notched").tag(AppSettings.RowShape.notched)
                }

                Picker("Fill Mode", selection: $settings.rowMode) {
                    Text("Solid").tag(AppSettings.RowColorMode.color)
                    Text("Gradient").tag(AppSettings.RowColorMode.gradient)
                }
                .pickerStyle(.segmented)

                switch settings.rowMode {
                case .color:
                    ColorSettingRow(label: "Row Color", color: $settings.rowColor)
                case .gradient:
                    ColorSettingRow(label: "Start", color: $settings.rowGradientStart)
                    ColorSettingRow(label: "End", color: $settings.rowGradientEnd)
                }

                HStack {
                    Text("Opacity")
                    Slider(value: $settings.rowOpacity, in: 0...1)
                    Text("\(Int(settings.rowOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40)
                }

                HStack {
                    Text("Row Gap")
                    Slider(value: $settings.rowGap, in: 0...40)
                    Text("\(Int(settings.rowGap))px")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
        }
    }

    // MARK: - System Tab

    private var systemTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Auto-Refresh (Google Sheets)") {
                HStack {
                    Text("Interval (seconds)")
                    Slider(value: $settings.refreshInterval, in: 1...60, step: 1)
                    Text("\(Int(settings.refreshInterval))s")
                        .monospacedDigit()
                        .frame(width: 35)
                }
            }

            SettingsSection(title: "Output Resolution") {
                HStack {
                    Text("Width")
                    TextField("", value: $settings.outputWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("x  Height")
                    TextField("", value: $settings.outputHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }
                HStack(spacing: 8) {
                    Button("720p") { settings.outputWidth = 1280; settings.outputHeight = 720 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("1080p") { settings.outputWidth = 1920; settings.outputHeight = 1080 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("4K") { settings.outputWidth = 3840; settings.outputHeight = 2160 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            SettingsSection(title: "Configuration") {
                HStack {
                    Button("Export Config...") {
                        SettingsManager.exportSettings(settings)
                    }
                    Button("Import Config...") {
                        SettingsManager.importSettings(into: settings)
                    }
                }
            }

            SettingsSection(title: "Reset") {
                Button("Reset All Settings to Defaults") {
                    let alert = NSAlert()
                    alert.messageText = "Reset All Settings?"
                    alert.informativeText = "This will restore all settings to their factory defaults and remove saved logos. This cannot be undone."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Reset")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == .alertFirstButtonReturn {
                        settings.resetToDefaults()
                        leftLogoImage = nil
                        rightLogoImage = nil
                    }
                }
                .foregroundColor(.red)
            }

            SettingsSection(title: "About") {
                Text("Live Scoreboard for macOS")
                    .font(.headline)
                Text("Native SwiftUI broadcast scoreboard. Supports Google Sheets and local manual scoring.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

}

// MARK: - Text Group Control

struct TextGroupControl: View {
    let label: String
    @Binding var fontWeight: String
    @Binding var color: CodableColor
    @Binding var fontSize: Double
    let availableWeights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
            HStack(spacing: 8) {
                FontWeightPicker(selectedWeight: $fontWeight, availableWeights: availableWeights)
                    .frame(maxWidth: 130)
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: color.nsColor) },
                    set: { color = CodableColor(NSColor($0)) }
                ))
                .labelsHidden()
                .frame(width: 30)
                Slider(value: $fontSize, in: 50...600)
                Text("\(Int(fontSize))%")
                    .monospacedDigit()
                    .font(.system(size: 11))
                    .frame(width: 42, alignment: .trailing)
            }
        }
    }
}

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct ColorSettingRow: View {
    let label: String
    @Binding var color: CodableColor

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 70, alignment: .leading)
                .font(.system(size: 12))
            ColorPicker("", selection: Binding(
                get: { Color(nsColor: color.nsColor) },
                set: { color = CodableColor(NSColor($0)) }
            ))
            .labelsHidden()
        }
    }
}

/// Font family picker with searchable dropdown. No weight selection — weights are per-element.
struct FontFamilyPicker: View {
    @Binding var selectedFamily: String
    @State private var searchText = ""
    @State private var isExpanded = false

    private var allFonts: [String] { AppSettings.availableFonts }
    private var filteredFonts: [String] {
        if searchText.isEmpty { return allFonts }
        return allFonts.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Font Family").font(.caption).foregroundColor(.secondary)
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(selectedFamily)
                        .font(.custom(selectedFamily, size: 13))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.caption)
                        TextField("Search fonts...", text: $searchText)
                            .textFieldStyle(.plain).font(.system(size: 11))
                    }
                    .padding(6)
                    Divider()
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredFonts, id: \.self) { fontName in
                                Button(action: {
                                    selectedFamily = fontName
                                    withAnimation { isExpanded = false }
                                    searchText = ""
                                }) {
                                    HStack {
                                        Text(fontName).font(.custom(fontName, size: 12)).lineLimit(1)
                                        Spacer()
                                        if fontName == selectedFamily {
                                            Image(systemName: "checkmark").font(.caption).foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .background(fontName == selectedFamily ? Color.accentColor.opacity(0.1) : Color.clear)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 180)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor), lineWidth: 1))
            }
        }
    }
}

/// Compact weight picker for individual text elements.
struct FontWeightPicker: View {
    @Binding var selectedWeight: String
    let availableWeights: [String]

    var body: some View {
        Picker("", selection: $selectedWeight) {
            ForEach(availableWeights, id: \.self) { weight in
                Text(weight).tag(weight)
            }
        }
        .labelsHidden()
        .controlSize(.small)
    }
}
