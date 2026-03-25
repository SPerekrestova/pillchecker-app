import SwiftUI

struct InteractionCard: View {
    let interaction: SavedInteraction
    var animationDelay: Double = 0
    var uncertain: Bool = false

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SeverityBadge(severity: interaction.severity)
                Spacer()
                Text("\(interaction.drugA) + \(interaction.drugB)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(interaction.description)
                .font(.body)

            if !interaction.management.isEmpty {
                Text(interaction.management)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if uncertain {
                Text("Lower confidence — verify with a pharmacist.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .severityCardStyle(severity: interaction.severity)
        .accessibilityElement(children: .combine)
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 20)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.easeOut(duration: 0.4).delay(animationDelay)) {
                appeared = true
            }
        }
    }
}
