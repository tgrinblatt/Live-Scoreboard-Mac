import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    var onRefresh: () -> Void

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Scoreboard Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Content").tag(0)
                Text("Design").tag(1)
                Text("System").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
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
                .padding()
            }
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 600, idealHeight: 700)
    }

    // MARK: - Content Tab

    private var contentTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Google Sheets
            SettingsSection(title: "Data Source") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Google Sheets Link or ID")
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
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Toggle("Left Logo", isOn: $settings.showLeftLogo)
                        if settings.showLeftLogo {
                            Button("Choose Image...") {
                                SettingsManager.pickImage { data in
                                    DispatchQueue.main.async {
                                        settings.leftLogoData = data
                                    }
                                }
                            }
                            HStack {
                                Text("Padding")
                                Slider(value: $settings.leftImagePadding, in: 0...50)
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Toggle("Right Logo", isOn: $settings.showRightLogo)
                        if settings.showRightLogo {
                            Button("Choose Image...") {
                                SettingsManager.pickImage { data in
                                    DispatchQueue.main.async {
                                        settings.rightLogoData = data
                                    }
                                }
                            }
                            HStack {
                                Text("Padding")
                                Slider(value: $settings.rightImagePadding, in: 0...50)
                            }
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
                Toggle("Show Sync Status", isOn: $settings.showSyncStatus)
                if settings.showSyncStatus {
                    Picker("Style", selection: $settings.syncStatusStyle) {
                        Text("Broadcast").tag(AppSettings.SyncStatusStyle.broadcast)
                        Text("Compact").tag(AppSettings.SyncStatusStyle.compact)
                        Text("Text Only").tag(AppSettings.SyncStatusStyle.textOnly)
                        Text("Micro").tag(AppSettings.SyncStatusStyle.micro)
                    }
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
        VStack(alignment: .leading, spacing: 20) {
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

            // Typography
            SettingsSection(title: "Typography") {
                FontPickerRow(
                    selectedFamily: $settings.fontFamily,
                    selectedMemberPS: $settings.fontMemberPostScript
                )
            }

            // Global Colors
            SettingsSection(title: "Global Colors") {
                ColorSettingRow(label: "Primary", color: $settings.primaryColor)
                ColorSettingRow(label: "Secondary", color: $settings.secondaryColor)
                ColorSettingRow(label: "Accent", color: $settings.accentColor)
                ColorSettingRow(label: "Text", color: $settings.textColor)
            }

            // Header Colors
            SettingsSection(title: "Header Styling") {
                HStack {
                    Text("Font Size")
                    Slider(value: $settings.headerFontSize, in: 30...200)
                    Text("\(Int(settings.headerFontSize))%")
                        .monospacedDigit()
                        .frame(width: 45)
                }
                ColorSettingRow(label: "Rank", color: $settings.headerRankColor)
                ColorSettingRow(label: "Name", color: $settings.headerNameColor)
                ColorSettingRow(label: "Round", color: $settings.headerRoundColor)
                ColorSettingRow(label: "Total", color: $settings.headerTotalColor)
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

            // Row Text
            SettingsSection(title: "Row Text") {
                Group {
                    fontSizeRow(label: "Rank", size: $settings.rowRankFontSize, color: $settings.rowRankColor)
                    fontSizeRow(label: "Name", size: $settings.rowNameFontSize, color: $settings.rowNameColor)
                    fontSizeRow(label: "Round", size: $settings.rowRoundFontSize, color: $settings.rowRoundColor)
                    fontSizeRow(label: "Total", size: $settings.rowTotalFontSize, color: $settings.rowTotalColor)
                }
            }
        }
    }

    // MARK: - System Tab

    private var systemTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection(title: "Auto-Refresh") {
                HStack {
                    Text("Interval (seconds)")
                    Slider(value: $settings.refreshInterval, in: 1...60, step: 1)
                    Text("\(Int(settings.refreshInterval))s")
                        .monospacedDigit()
                        .frame(width: 35)
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

            SettingsSection(title: "About") {
                Text("Live Scoreboard for macOS")
                    .font(.headline)
                Text("Native SwiftUI application. Fetches live scoring data from Google Sheets and displays a broadcast-ready leaderboard.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func fontSizeRow(label: String, size: Binding<Double>, color: Binding<CodableColor>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            HStack {
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: color.wrappedValue.nsColor) },
                    set: { color.wrappedValue = CodableColor(NSColor($0)) }
                ))
                .labelsHidden()
                .frame(width: 30)
                Slider(value: size, in: 50...500)
                Text("\(Int(size.wrappedValue))%")
                    .monospacedDigit()
                    .frame(width: 45)
            }
        }
    }
}

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct FontPickerRow: View {
    @Binding var selectedFamily: String
    @Binding var selectedMemberPS: String
    @State private var searchText = ""
    @State private var isFamilyExpanded = false

    private var allFonts: [String] { AppSettings.availableFonts }

    private var filteredFonts: [String] {
        if searchText.isEmpty { return allFonts }
        return allFonts.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var members: [AppSettings.FontMember] {
        AppSettings.membersForFamily(selectedFamily)
    }

    /// Human-readable name of the currently selected member
    private var currentMemberDisplayName: String {
        if selectedMemberPS.isEmpty { return "Regular" }
        return members.first(where: { $0.postScriptName == selectedMemberPS })?.displayName ?? "Regular"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // -- Font Family --
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Family").font(.caption).foregroundColor(.secondary)

                Button(action: { withAnimation { isFamilyExpanded.toggle() } }) {
                    HStack {
                        Text(selectedFamily)
                            .font(.custom(selectedFamily, size: 14))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isFamilyExpanded ? 180 : 0))
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if isFamilyExpanded {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            TextField("Search fonts...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                        }
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))

                        Divider()

                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredFonts, id: \.self) { fontName in
                                    Button(action: {
                                        selectedFamily = fontName
                                        // Auto-select the first member (usually Regular)
                                        let newMembers = AppSettings.membersForFamily(fontName)
                                        selectedMemberPS = newMembers.first?.postScriptName ?? ""
                                        withAnimation { isFamilyExpanded = false }
                                        searchText = ""
                                    }) {
                                        HStack {
                                            Text(fontName)
                                                .font(.custom(fontName, size: 13))
                                                .lineLimit(1)
                                            Spacer()
                                            if fontName == selectedFamily {
                                                Image(systemName: "checkmark")
                                                    .font(.caption)
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .contentShape(Rectangle())
                                        .background(fontName == selectedFamily ? Color.accentColor.opacity(0.1) : Color.clear)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
            }

            // -- Weight / Style --
            if !members.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight / Style").font(.caption).foregroundColor(.secondary)

                    // Preview of current selection
                    Text("The quick brown fox jumps over the lazy dog")
                        .font(.custom(selectedMemberPS.isEmpty ? selectedFamily : selectedMemberPS, size: 14))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(members) { member in
                                Button(action: {
                                    selectedMemberPS = member.postScriptName
                                }) {
                                    HStack {
                                        Text(member.displayName)
                                            .font(.custom(member.postScriptName, size: 13))
                                            .lineLimit(1)
                                        Spacer()
                                        if member.postScriptName == selectedMemberPS {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle())
                                    .background(member.postScriptName == selectedMemberPS ? Color.accentColor.opacity(0.1) : Color.clear)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 160)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
            }
        }
    }
}

struct ColorSettingRow: View {
    let label: String
    @Binding var color: CodableColor

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            ColorPicker("", selection: Binding(
                get: { Color(nsColor: color.nsColor) },
                set: { newColor in
                    color = CodableColor(NSColor(newColor))
                }
            ))
            .labelsHidden()
        }
    }
}
