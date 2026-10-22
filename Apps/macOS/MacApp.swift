import SwiftUI
import SharedCore

@main
struct MacApp: App {
    var body: some Scene {
        WindowGroup {
            StarterHomeView(platform: .macOS)
                .frame(minWidth: 560, minHeight: 390)
        }
    }
}

