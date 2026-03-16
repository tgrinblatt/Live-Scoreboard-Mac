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

            HStack(spacing: 0) {
                // Rank
                Text(String(format: "%02d", player.rank))
                    .font(settings.scaledFont(baseSize: 14, percentage: settings.rowRankFontSize))
                    .foregroundColor(settings.rowRankColor.color)
                    .frame(width: width * 0.06, alignment: .center)

                // Name
                Text(player.name)
                    .font(settings.scaledFont(baseSize: 14, percentage: settings.rowNameFontSize))
                    .foregroundColor(settings.rowNameColor.color)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: width * 0.28, alignment: .leading)

                // Rounds
                ForEach(0..<settings.numRounds, id: \.self) { i in
                    let score = i < player.rounds.count ? player.rounds[i] : nil
                    Text(score.map { formatScore($0) } ?? "-")
                        .font(settings.scaledFont(baseSize: 14, percentage: settings.rowRoundFontSize))
                        .foregroundColor(settings.rowRoundColor.color)
                        .frame(maxWidth: .infinity)
                }

                // Total with score change animation
                Text(formatScore(player.total))
                    .font(settings.scaledFont(baseSize: 14, percentage: settings.rowTotalFontSize))
                    .foregroundColor(totalColor)
                    .scaleEffect(scoreFlash != nil ? 1.2 : 1.0)
                    .frame(width: width * 0.10, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(rowBackground)
            .clipShape(rowClipShape)
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

    /// Flash green for increase, red for decrease, default color otherwise
    private var totalColor: Color {
        if let flash = scoreFlash {
            return flash.isIncrease ? .green : .red
        }
        return settings.rowTotalColor.color
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
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width * 0.95, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.25))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width * 0.05, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.75))
            path.closeSubpath()
            return path
        }
    }
}
