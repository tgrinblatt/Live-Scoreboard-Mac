import SwiftUI

@main
struct LiveScoreboardApp: App {
    @StateObject private var settings = AppSettings.loadFromUserDefaults()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .defaultSize(width: 1280, height: 720)
    }
}
