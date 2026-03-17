import SwiftUI

struct LeaderboardRowView: View {
    @EnvironmentObject var settings: AppSettings
    let player: PlayerData
    let rowHeight: CGFloat

    @State private var isHovered = false
    @State private var scoreFlash: ScoreFlash? = nil
    @State private var previousTotal: Double? = nil

    struct ScoreFlash {
        let isIncrease: Bool
        let id = UUID()
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            // Widen the rank shape for angled in split mode since the skew eats into visible area
            let baseRankWidth = width * 0.06
            let rankWidth = (settings.rowLayoutMode == .splitRank && settings.rowShape == .angled)
                ? baseRankWidth * 1.6
                : baseRankWidth
            let padding = CGFloat(settings.rankToNamePadding)

            HStack(spacing: 0) {
                switch settings.rowLayoutMode {
                case .fullRow:
                    // One continuous shape covering everything
                    HStack(spacing: 0) {
                        rankText.frame(width: rankWidth, alignment: .center)
                        Spacer().frame(width: padding)
                        contentColumns(width: width)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(rowBackground)
                    .clipShape(rowClipShape)

                case .splitRank:
                    // Rank gets its own shape, content gets its own shape
                    rankText
                        .frame(width: rankWidth, alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(rowBackground)
                        .clipShape(rowClipShape)

                    Spacer().frame(width: padding)

                    HStack(spacing: 0) {
                        contentColumns(width: width)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(rowBackground)
                    .clipShape(rowClipShape)

                case .noRankBackground:
                    // Rank has no background, content shape starts after rank
                    rankText.frame(width: rankWidth, alignment: .center)
                    Spacer().frame(width: padding)
                    HStack(spacing: 0) {
                        contentColumns(width: width)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(rowBackground)
                    .clipShape(rowClipShape)
                }
            }
            .offset(y: isHovered ? -1 : 0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in isHovered = hovering }
        }
        .frame(height: rowHeight)
        .onChange(of: player.total) { oldVal, newVal in
            // Score change animation
            if let prev = previousTotal, prev != newVal {
                withAnimation(.easeOut(duration: 0.3)) {
                    scoreFlash = ScoreFlash(isIncrease: newVal > prev)
                }
                // Reset flash after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scoreFlash = nil
                    }
                }
            }
            previousTotal = newVal
        }
        .onAppear {
            previousTotal = player.total
        }
    }

    // MARK: - Sub-views

    private var rankText: some View {
        Text(String(format: "%02d", player.rank))
            .font(settings.scaledFont(baseSize: 14, percentage: settings.rankingFontSize, weightName: settings.rankingFontWeight))
            .foregroundColor(settings.rankingColor.color)
    }

    private func contentColumns(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Left padding inside the row shape for split/no-rank modes
            if settings.rowLayoutMode != .fullRow {
                Spacer().frame(width: 28 + CGFloat(settings.teamNameInternalPadding))
            }
            Text(player.name)
                .font(settings.scaledFont(baseSize: 14, percentage: settings.teamNamesFontSize, weightName: settings.teamNamesFontWeight))
                .foregroundColor(settings.teamNamesColor.color)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: width * 0.28, alignment: .leading)

            ForEach(0..<settings.numRounds, id: \.self) { i in
                let score = i < player.rounds.count ? player.rounds[i] : nil
                Text(score.map { formatScore($0) } ?? "-")
                    .font(settings.scaledFont(baseSize: 14, percentage: settings.roundScoresFontSize, weightName: settings.roundScoresFontWeight))
                    .foregroundColor(settings.roundScoresColor.color)
                    .frame(maxWidth: .infinity)
            }

            Text(formatScore(player.total))
                .font(settings.scaledFont(baseSize: 14, percentage: settings.totalPointsFontSize, weightName: settings.totalPointsFontWeight))
                .foregroundColor(totalColor)
                .scaleEffect(scoreFlash != nil ? 1.2 : 1.0)
                .frame(width: width * 0.10, alignment: .center)
        }
    }

    /// Flash green for increase, red for decrease, default color otherwise
    private var totalColor: Color {
        if let flash = scoreFlash {
            return flash.isIncrease ? .green : .red
        }
        return settings.totalPointsColor.color
    }

    @ViewBuilder
    private var rowBackground: some View {
        switch settings.rowMode {
        case .color:
            settings.rowColor.color.opacity(settings.rowOpacity)
        case .gradient:
            LinearGradient(
                colors: [
                    settings.rowGradientStart.color.opacity(settings.rowOpacity),
                    settings.rowGradientEnd.color.opacity(settings.rowOpacity)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var rowClipShape: some Shape {
        RowClipShape(shape: settings.rowShape)
    }

    private func formatScore(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Row Shapes

struct RowClipShape: Shape {
    let shape: AppSettings.RowShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .rectangle:
            return Path(rect)
        case .rounded:
            return Path(roundedRect: rect, cornerRadius: 8)
        case .pill:
            return Path(roundedRect: rect, cornerRadius: rect.height / 2)
        case .angled:
            var path = Path()
            let inset = rect.height * 0.3
            path.move(to: CGPoint(x: inset, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
            path.closeSubpath()
            return path
        case .notched:
            // Small 45-degree corner notches
            let notch = min(rect.height * 0.35, 12.0)
            var path = Path()
            path.move(to: CGPoint(x: notch, y: 0))
            path.addLine(to: CGPoint(x: rect.width - notch, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: notch))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - notch))
            path.addLine(to: CGPoint(x: rect.width - notch, y: rect.height))
            path.addLine(to: CGPoint(x: notch, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - notch))
            path.addLine(to: CGPoint(x: 0, y: notch))
            path.closeSubpath()
            return path
        }
    }
}
