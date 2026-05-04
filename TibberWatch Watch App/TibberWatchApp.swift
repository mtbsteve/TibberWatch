import SwiftUI

@main
struct TibberWatchApp: App {
    @StateObject private var tibberStore = TibberStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tibberStore)
                .onChange(of: scenePhase) { _, newPhase in
                    // When the watch wakes / app returns to foreground, check for day rollover
                    if newPhase == .active {
                        tibberStore.checkForDayRollover()
                    }
                }
        }
    }
}
