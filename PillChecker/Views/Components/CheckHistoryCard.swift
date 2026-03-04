import SwiftUI

struct CheckHistoryCard: View {
    let record: CheckRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.drugA) + \(record.drugB)")
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(record.source == "scan" ? "AI Scan" : "Manual")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.checkedAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: record.safe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(record.safe ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}
