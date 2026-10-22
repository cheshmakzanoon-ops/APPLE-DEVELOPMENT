import SwiftUI
import SharedCore

/// Deliberately small cross-platform surface. Expand with platform-specific UI as needed.
struct StarterHomeView: View {
    let platform: ApplePlatform

    @State private var tapCount = 0

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: platform.symbolName)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text("Ready for \(platform.displayName)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("One shared Swift package. Five native app targets. Cloud-based builds.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Check interaction") {
                tapCount += 1
            }
            .buttonStyle(.borderedProminent)

            Text("Interaction count: \(tapCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("interaction-count")
        }
        .frame(maxWidth: 560)
        .padding()
    }
}

