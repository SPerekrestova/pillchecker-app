import SwiftUI

struct SeverityBadge: View {
    let severity: String

    private var backgroundColor: Color {
        switch severity.uppercased() {
        case "MAJOR": return Theme.critical
        case "MODERATE": return Theme.warning
        case "MINOR": return Theme.caution
        default: return .gray
        }
    }

    private var textColor: Color {
        severity.uppercased() == "MINOR" ? Theme.cautionText : .white
    }

    var body: some View {
        Text(severity.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor, in: Capsule())
    }
}
