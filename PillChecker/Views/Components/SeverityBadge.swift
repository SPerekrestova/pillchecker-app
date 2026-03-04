import SwiftUI

struct SeverityBadge: View {
    let severity: String

    private var color: Color {
        switch severity.uppercased() {
        case "MAJOR": return .red
        case "MODERATE": return .orange
        case "MINOR": return .yellow
        default: return .gray
        }
    }

    var body: some View {
        Text(severity.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }
}
