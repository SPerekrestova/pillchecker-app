import SwiftUI
import UIKit

// MARK: - Theme

enum Theme {
    // MARK: Color Tokens

    static let accent = Color("AccentColor")
    static let accentSoft = Color(light: Color(hex: 0xEEF2FF), dark: Color(hex: 0x4F46E5, opacity: 0.20))

    static let safe = Color(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399))
    static let safeSoft = Color(light: Color(hex: 0xECFDF5), dark: Color(hex: 0x059669, opacity: 0.20))

    static let critical = Color(light: Color(hex: 0xDC2626), dark: Color(hex: 0xF87171))
    static let warning = Color(light: Color(hex: 0xEA580C), dark: Color(hex: 0xFB923C))

    static let caution = Color(light: Color(hex: 0xCA8A04), dark: Color(hex: 0xFACC15))
    static let cautionText = Color(hex: 0x713F12)

    static let cardBackground = Color(light: .white, dark: Color(hex: 0x1C1C1E))
    static let cardBorder = Color(light: Color(hex: 0xE5E7EB), dark: Color(hex: 0x2C2C2E))

    // MARK: Card Constants

    static let cardRadius: CGFloat = 12
    static let cardShadowColor = Color.black.opacity(0.06)
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2
}

// MARK: - Color Helpers

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - CardStyle ViewModifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: Theme.cardShadowColor,
                radius: Theme.cardShadowRadius,
                y: Theme.cardShadowY
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - PrimaryButtonStyle

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Theme.accent : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}
