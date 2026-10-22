import SwiftUI
import SharedCore

/// Works on regular iPhones, iPads, and the inner/outer iPhone Duo displays.
/// This is width-responsive UI, not a substitute for validating hinge states.
struct iOSRootView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if AdaptiveLayout.mode(forWidth: Double(geometry.size.width)) == .expanded {
                    HStack(alignment: .top, spacing: 24) {
                        StarterHomeView(platform: .iOS)
                            .frame(maxWidth: .infinity)
                        duoInformation
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("expanded-layout")
                } else {
                    VStack(spacing: 16) {
                        StarterHomeView(platform: .iOS)
                        duoInformation
                    }
                    .accessibilityIdentifier("compact-layout")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }

    private var duoInformation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Adaptive by default", systemImage: "rectangle.split.2x1")
                .font(.headline)
            Text("Resize, unfold, or move between displays. The layout uses the available width instead of assuming a fixed phone size.")
                .foregroundStyle(.secondary)
            Text("Next: verify every iPhone Duo pose in Xcode 27.1 Device Hub.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: 560, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding()
    }
}

