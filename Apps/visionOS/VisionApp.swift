import SwiftUI
import SharedCore

@main
struct VisionApp: App {
    var body: some Scene {
        WindowGroup {
            StarterHomeView(platform: .visionOS)
        }
    }
}
