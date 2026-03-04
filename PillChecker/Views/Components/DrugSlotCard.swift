import SwiftUI

struct DrugSlotCard: View {
    let slotIndex: Int
    let slot: DrugSlot
    let onScan: () -> Void
    let onType: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Drug \(slotIndex + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if slot.isFilled {
                HStack {
                    VStack(alignment: .leading) {
                        Text(slot.displayName ?? "")
                            .font(.headline)
                        if slot.isScanned {
                            Text("Scanned")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: onScan) {
                        Label("Scan", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onType) {
                        Label("Type", systemImage: "keyboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
