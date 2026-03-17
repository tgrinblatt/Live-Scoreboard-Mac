import SwiftUI

struct ScoreboardView: View {
    @EnvironmentObject var settings: AppSettings
    let players: [PlayerData]
    let isLoading: Bool
    let lastUpdated: Date?
    let countdown: Int
    let errorMessage: String?
    /// When false, hides the sync status from the scoreboard (used for broadcast output)
    var showSyncOverlay: Bool = true

    // Cache logo images to avoid decoding from disk every render
    @State private var leftLogoImage: NSImage? = nil
    @State private var rightLogoImage: NSImage? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundView

                VStack(spacing: 0) {
                    // Header
                    headerSection(width: geo.size.width)
                        .frame(height: geo.size.height * 0.15)

                    // Leaderboard
                    leaderboardSection(size: geo.size)
                        .frame(height: geo.size.height * CGFloat(settings.scoreboardVerticalHeight) / 100.0 * 0.75)
                        .padding(.horizontal, geo.size.width * 0.04)

                    Spacer()

                    // Footer
                    footerSection(width: geo.size.width)
                        .frame(height: geo.size.height * 0.06)
                        .padding(.horizontal, geo.size.width * 0.04)
                        .padding(.bottom, geo.size.height * 0.02)
                }
            }
        }
        .aspectRatio(settings.outputAspectRatio, contentMode: .fit)
        .clipped()
        .onAppear { loadLogos() }
        .onChange(of: settings.showLeftLogo) { _, _ in loadLogos() }
        .onChange(of: settings.showRightLogo) { _, _ in loadLogos() }
    }

    private func loadLogos() {
        leftLogoImage = settings.showLeftLogo ? AppSettings.loadLogoImage(side: .left) : nil
        rightLogoImage = settings.showRightLogo ? AppSettings.loadLogoImage(side: .right) : nil
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        switch settings.backgroundMode {
        case .gradient:
            LinearGradient(
                gradient: Gradient(colors: [
                    settings.backgroundGradientStart.color,
                    settings.backgroundGradientEnd.color
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .color:
            settings.backgroundColor.color
        case .image:
            settings.backgroundColor.color
        }
    }

    // MARK: - Header

    private func headerSection(width: CGFloat) -> some View {
        HStack {
            if settings.showLeftLogo, let img = leftLogoImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(CGFloat(settings.leftImagePadding))
                    .frame(width: width * 0.15)
            } else {
                Spacer().frame(width: width * 0.15)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(settings.title)
                    .font(.system(size: CGFloat(settings.titleSize) * 16, weight: .heavy))
                    .foregroundColor(settings.titleColor.color)
                    .tracking(4)

                if settings.showTitleBar {
                    Rectangle()
                        .fill(settings.accentColor.color.opacity(0.6))
                        .frame(width: 200, height: 3)
                }
            }

            Spacer()

            if settings.showRightLogo, let img = rightLogoImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(CGFloat(settings.rightImagePadding))
                    .frame(width: width * 0.15)
            } else {
                Spacer().frame(width: width * 0.15)
            }
        }
        .padding(.horizontal, width * 0.04)
        .padding(.top, 8)
    }

    // MARK: - Leaderboard

    private func leaderboardSection(size: CGSize) -> some View {
        VStack(spacing: 0) {
            columnHeaderRow(width: size.width * 0.92)
                .padding(.bottom, 4)

            if players.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressIndicator()
                    } else {
                        Image(systemName: settings.dataSourceMode == .localManual
                              ? "gamecontroller" : "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 40))
                            .foregroundColor(settings.textColor.color.opacity(0.4))
                        Text(settings.dataSourceMode == .localManual
                             ? "Set up a game to begin"
                             : "Source Disconnected")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(settings.textColor.color.opacity(0.5))
                    }
                }
                Spacer()
            } else {
                let availableHeight = size.height * CGFloat(settings.scoreboardVerticalHeight) / 100.0 * 0.75 - 30
                let rowHeight = max(20, (availableHeight - CGFloat(players.count - 1) * CGFloat(settings.rowGap)) / CGFloat(players.count))

                VStack(spacing: CGFloat(settings.rowGap)) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        LeaderboardRowView(player: player, rowHeight: rowHeight)
                            .environmentObject(settings)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: players.map(\.id))
            }
        }
    }

    private func columnHeaderRow(width: CGFloat) -> some View {
        let headerFont = settings.scaledFont(baseSize: 10, percentage: settings.headerFontSize, weightName: settings.headerFontWeight)
        let headerColor = settings.headerColor.color

        return HStack(spacing: 0) {
            Text("RK")
                .frame(width: width * 0.06, alignment: .center)
            Text("TEAM")
                .frame(width: width * 0.28, alignment: .leading)
            ForEach(1...settings.numRounds, id: \.self) { i in
                Text("R\(i)")
                    .frame(maxWidth: .infinity)
            }
            Text("TOTAL")
                .frame(width: width * 0.10, alignment: .center)
        }
        .font(headerFont)
        .foregroundColor(headerColor)
        .textCase(.uppercase)
        .tracking(1)
    }

    // MARK: - Footer

    private func footerSection(width: CGFloat) -> some View {
        HStack {
            if settings.showFooterText {
                Text(settings.footerText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(settings.textColor.color.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }

            Spacer()

            if settings.showSyncStatus && showSyncOverlay {
                syncStatusView
            }
        }
    }

    @ViewBuilder
    private var syncStatusView: some View {
        let timeText = lastUpdated.map { formatTime($0) } ?? "--:--:--"

        switch settings.syncStatusStyle {
        case .broadcast:
            HStack(spacing: 6) {
                Circle()
                    .fill(isLoading ? Color.yellow : (lastUpdated != nil ? Color.green : Color.red))
                    .frame(width: 6, height: 6)
                Text("\(timeText)  |  HB: \(countdown)s")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(settings.textColor.color.opacity(0.6))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
        case .compact:
            HStack(spacing: 4) {
                Circle()
                    .fill(isLoading ? Color.yellow : Color.green)
                    .frame(width: 5, height: 5)
                Text(timeText)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(settings.textColor.color.opacity(0.6))
            }
        case .textOnly:
            Text("SYNC: \(timeText)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(settings.textColor.color.opacity(0.6))
        case .micro:
            Circle()
                .fill(isLoading ? Color.yellow : (lastUpdated != nil ? Color.green : Color.red))
                .frame(width: 6, height: 6)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct ProgressIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.white.opacity(0.5), lineWidth: 2)
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}
