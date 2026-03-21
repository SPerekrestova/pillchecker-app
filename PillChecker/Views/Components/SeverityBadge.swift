import SwiftUI

struct SeverityBadge: View {
    let severity: String

    // Badge-specific colors with WCAG AA contrast (4.5:1+)
    private var backgroundColor: Color {
        switch severity.uppercased() {
        case "MAJOR": return Theme.critical
        case "MODERATE": return Color(light: Color(hex: 0xC2410C), dark: Theme.warning)
        case "MINOR": return Color(light: Color(hex: 0xFDE68A), dark: Theme.caution)
        default: return .gray
        }
    }

    private var textColor: Color {
        switch severity.uppercased() {
        case "MINOR": return Color(light: Color(hex: 0x78350F), dark: Theme.cautionText)
        default: return .white
        }
    }

    var body: some View {
        Text(severity.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor, in: Capsule())
            .accessibilityLabel("Severity: \(severity)")
    }
}
