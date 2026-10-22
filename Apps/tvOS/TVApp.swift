import SwiftUI
import SharedCore

@main
struct TVApp: App {
    var body: some Scene {
        WindowGroup {
            StarterHomeView(platform: .tvOS)
        }
    }
}

