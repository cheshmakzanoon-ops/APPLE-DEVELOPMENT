import Foundation

/// The five Apple application platforms. iPhone Duo is a form factor within iOS.
public enum ApplePlatform: String, CaseIterable, Codable, Sendable {
    case iOS
    case macOS
    case watchOS
    case tvOS
    case visionOS

    public var displayName: String {
        switch self {
        case .iOS: "iPhone, iPad & iPhone Duo"
        case .macOS: "Mac"
        case .watchOS: "Apple Watch"
        case .tvOS: "Apple TV"
        case .visionOS: "Apple Vision Pro"
        }
    }

    public var symbolName: String {
        switch self {
        case .iOS: "iphone.gen3"
        case .macOS: "desktopcomputer"
        case .watchOS: "applewatch"
        case .tvOS: "appletv"
        case .visionOS: "visionpro"
        }
    }
}

/// Testable layout policy. The presentation layer can interpret it however it likes.
public enum AdaptiveLayout {
    public enum Mode: Sendable, Equatable {
        case compact
        case expanded
    }

    public static func mode(forWidth width: Double) -> Mode {
        guard width.isFinite, width >= 700 else { return .compact }
        return .expanded
    }
}

