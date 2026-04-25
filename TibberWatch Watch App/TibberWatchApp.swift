import SwiftUI

@main
struct TibberWatchApp: App {
    @StateObject private var tibberStore = TibberStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tibberStore)
        }
    }
}
