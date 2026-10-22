import SwiftUI
import SharedCore

@main
struct WatchApp: App {
    var body: some Scene {
        WindowGroup {
            ScrollView {
                StarterHomeView(platform: .watchOS)
            }
        }
    }
}

