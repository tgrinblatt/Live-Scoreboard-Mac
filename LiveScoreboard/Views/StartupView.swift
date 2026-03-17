import SwiftUI

/// Startup screen shown on every launch. Offers New Session, Resume, or Load From File.
struct StartupView: View {
    @EnvironmentObject var settings: AppSettings
    var onNewSession: () -> Void
    var onResume: () -> Void
    var onLoadFile: () -> Void

    private var sessionMeta: SessionMetadata? {
        SessionMetadata.load()
    }

    private var hasSavedSession: Bool {
        LocalGameState.load() != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App title
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("Live Scoreboard")
                    .font(.system(size: 28, weight: .bold))
                Text("Broadcast-quality scoring for live events")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)

            // Option cards
            VStack(spacing: 12) {
                // New Session
                StartupCard(
                    icon: "plus.circle.fill",
                    iconColor: .accentColor,
                    title: "New Session",
                    subtitle: "Start a fresh game setup"
                ) {
                    onNewSession()
                }

                // Resume Previous
                if hasSavedSession {
                    let meta = sessionMeta
                    StartupCard(
                        icon: "arrow.counterclockwise.circle.fill",
                        iconColor: .green,
                        title: "Resume Previous Session",
                        subtitle: resumeSubtitle(meta: meta)
                    ) {
                        onResume()
                    }
                }

                // Load From File
                StartupCard(
                    icon: "doc.circle.fill",
                    iconColor: .orange,
                    title: "Load From File",
                    subtitle: "Import a saved game file"
                ) {
                    onLoadFile()
                }
            }
            .frame(maxWidth: 400)

            Spacer()

            // Skip preference
            HStack {
                Spacer()
                Toggle("Always resume previous session on startup", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "alwaysResume") },
                    set: { UserDefaults.standard.set($0, forKey: "alwaysResume") }
                ))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .toggleStyle(.checkbox)
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 500)
    }

    private func resumeSubtitle(meta: SessionMetadata?) -> String {
        guard let meta = meta else {
            return "Saved session found"
        }
        var parts: [String] = []
        if !meta.name.isEmpty { parts.append("\"\(meta.name)\"") }
        parts.append("\(meta.numRounds) rounds, \(meta.numTeams) teams")
        if let date = meta.lastSaved {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            parts.append("Last saved: \(formatter.string(from: date))")
        }
        return parts.joined(separator: " — ")
    }
}

/// A clickable card on the startup screen.
struct StartupCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: isHovered ? .selectedContentBackgroundColor.withAlphaComponent(0.1) : .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Session Metadata

struct SessionMetadata: Codable {
    var name: String = ""
    var numRounds: Int = 0
    var numTeams: Int = 0
    var lastSaved: Date? = nil

    private static var metaURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LiveScoreboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session-meta.json")
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.metaURL)
    }

    static func load() -> SessionMetadata? {
        guard let data = try? Data(contentsOf: metaURL),
              let meta = try? JSONDecoder().decode(SessionMetadata.self, from: data) else {
            return nil
        }
        return meta
    }

    static func remove() {
        try? FileManager.default.removeItem(at: metaURL)
    }
}
