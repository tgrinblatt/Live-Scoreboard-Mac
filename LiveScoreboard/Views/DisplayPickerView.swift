import SwiftUI
import AppKit

/// Lets the operator choose which connected display to present the scoreboard on.
struct DisplayPickerView: View {
    var onSelect: (NSScreen) -> Void
    var onCancel: () -> Void

    @State private var screens: [NSScreen] = NSScreen.screens

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Output Display")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Choose which screen to present the scoreboard on")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)

            Divider()

            // Display list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                        DisplayCard(
                            screen: screen,
                            index: index,
                            isMain: screen == NSScreen.main,
                            onSelect: { onSelect(screen) }
                        )
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
        }
        .frame(width: 420, height: min(CGFloat(180 + screens.count * 90), 500))
        .onAppear {
            screens = NSScreen.screens
        }
    }
}

/// A card representing a single display option.
struct DisplayCard: View {
    let screen: NSScreen
    let index: Int
    let isMain: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Monitor icon with index
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .frame(width: 52, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )
                    Image(systemName: "display")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 13, weight: .medium))
                        if isMain {
                            Text("Main")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(3)
                        }
                    }
                    Text(resolutionText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var displayName: String {
        screen.localizedName
    }

    private var resolutionText: String {
        let w = Int(screen.frame.width)
        let h = Int(screen.frame.height)
        return "\(w) x \(h)"
    }
}
