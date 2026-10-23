import SwiftUI

/// Editorial paper-and-ink identity: warm ivory, near-black, vermilion and acidic chartreuse.
enum MouthColors {
    static let paper = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let ink = Color(red: 0.13, green: 0.14, blue: 0.13)
    static let pale = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let red = Color(red: 0.98, green: 0.31, blue: 0.24)
    static let lime = Color(red: 0.84, green: 0.95, blue: 0.37)
    static let blue = Color(red: 0.38, green: 0.60, blue: 0.90)
    static let muted = Color(red: 0.48, green: 0.48, blue: 0.45)
}

struct MouthWordmark: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(MouthColors.red)
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-7))
                // The two bars and tooth read as a stylized, crooked mouth.
                Capsule()
                    .fill(MouthColors.ink)
                    .frame(width: 29, height: 8)
                    .rotationEffect(.degrees(12))
                    .offset(y: 5)
                RoundedRectangle(cornerRadius: 2)
                    .fill(MouthColors.pale)
                    .frame(width: 8, height: 9)
                    .rotationEffect(.degrees(12))
                    .offset(x: -5, y: 7)
            }
            VStack(alignment: .leading, spacing: -5) {
                Text("ODD")
                Text("MOUTH")
            }
            .font(.system(size: 24, weight: .black, design: .rounded))
            .tracking(-1.3)
            .foregroundStyle(MouthColors.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Oddmouth")
    }
}

struct MouthTag: View {
    let text: String
    var fill: Color = MouthColors.lime

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .tracking(1.3)
            .foregroundStyle(MouthColors.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(fill, in: Capsule())
    }
}

struct MouthPanel<Content: View>: View {
    var color: Color = MouthColors.pale
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(MouthColors.ink, lineWidth: 2)
            }
            .shadow(color: MouthColors.ink.opacity(0.15), radius: 0, x: 5, y: 6)
            .padding(.trailing, 5)
            .padding(.bottom, 6)
    }
}

struct MouthButtonStyle: ButtonStyle {
    var fill: Color = MouthColors.lime
    var foreground: Color = MouthColors.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .black, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.horizontal, 12)
            .background(fill, in: RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(MouthColors.ink, lineWidth: 2)
            }
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
            .background {
                RoundedRectangle(cornerRadius: 17)
                    .fill(MouthColors.ink)
                    .offset(x: 4, y: 5)
            }
            .padding(.trailing, 4)
            .padding(.bottom, 5)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct MouthSectionHeading: View {
    let kicker: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MouthTag(text: kicker, fill: MouthColors.red)
            Text(title)
                .font(.system(size: 41, weight: .black, design: .rounded))
                .tracking(-2.2)
                .lineSpacing(-3)
                .foregroundStyle(MouthColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MouthColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
