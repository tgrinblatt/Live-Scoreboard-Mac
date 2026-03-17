import AppKit
import SwiftUI

/// Manages a Keynote-style presentation window that covers the entire target screen.
///
/// Multi-monitor behavior:
/// - If presenting on an EXTERNAL display, the window fills that screen edge-to-edge.
///   The menu bar and dock remain visible on the primary screen so the operator can work.
/// - If presenting on the PRIMARY display (single-monitor setup), the menu bar and dock
///   are hidden so the scoreboard covers everything.
/// - Escape key always exits presentation mode.
class PresentationWindowController {
    private var window: NSWindow?
    private var eventMonitor: Any?
    private var isOnPrimaryScreen = false
    private var screenObserver: Any?

    /// Open a fullscreen borderless window on the specified screen.
    /// If `screen` is nil, uses the last screen (external if available, otherwise main).
    func open<V: View>(
        content: V,
        on screen: NSScreen? = nil,
        onEscape: @escaping () -> Void
    ) {
        close()

        let targetScreen = screen ?? bestOutputScreen()
        let frame = targetScreen.frame
        isOnPrimaryScreen = (targetScreen == NSScreen.main)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: targetScreen
        )

        // Use a high level that stays on top, but not so high it blocks system dialogs
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        window.collectionBehavior = [.stationary, .canJoinAllSpaces, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = false

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView

        // Position the window exactly on the target screen
        window.setFrame(frame, display: true)

        // Only hide menu bar / dock when presenting on the primary screen
        // (single-monitor setup). On external displays, leave them visible
        // so the operator can still work on their main screen.
        if isOnPrimaryScreen {
            NSApplication.shared.presentationOptions = [
                .hideMenuBar,
                .hideDock
            ]
        }

        // Show the window without stealing focus from the operator window
        window.orderFrontRegardless()
        self.window = window

        // Give focus back to the main operator window after a brief delay
        if !isOnPrimaryScreen {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApplication.shared.windows
                    .first { $0 != window && $0.isVisible && $0.canBecomeKey }?
                    .makeKeyAndOrderFront(nil)
            }
        }

        // Monitor Escape key
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                onEscape()
                return nil
            }
            return event
        }

        // Watch for screen configuration changes (display connected/disconnected)
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }

    /// Close the presentation window and restore system chrome.
    func close() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }

        window?.orderOut(nil)
        window = nil

        // Restore menu bar and dock
        NSApplication.shared.presentationOptions = []
        isOnPrimaryScreen = false
    }

    var isOpen: Bool {
        window != nil
    }

    // MARK: - Private

    /// Choose the best screen for output: external display if connected, otherwise main.
    private func bestOutputScreen() -> NSScreen {
        let screens = NSScreen.screens
        if screens.count > 1 {
            // Return the first screen that isn't the main screen (i.e., an external display)
            return screens.first(where: { $0 != NSScreen.main }) ?? screens.last!
        }
        return NSScreen.main ?? screens.first!
    }

    /// Reposition the window if screens change (e.g., external display disconnected).
    private func handleScreenChange() {
        guard let window = window else { return }

        // If our target screen disappeared, close presentation
        let currentFrame = window.frame
        let screenStillExists = NSScreen.screens.contains(where: {
            $0.frame.intersects(currentFrame)
        })

        if !screenStillExists {
            // Screen was disconnected — move to remaining screen or close
            let fallback = bestOutputScreen()
            window.setFrame(fallback.frame, display: true)
            isOnPrimaryScreen = (fallback == NSScreen.main)
            if isOnPrimaryScreen {
                NSApplication.shared.presentationOptions = [.hideMenuBar, .hideDock]
            }
        }
    }
}
