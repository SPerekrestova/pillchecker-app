import SwiftUI

struct InteractionCard: View {
    let interaction: SavedInteraction

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
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
