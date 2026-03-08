import SwiftUI

struct DrugSlotCard: View {
    let slotIndex: Int
    let slot: DrugSlot
    let onScan: () -> Void
    let onType: () -> Void
    let onClear: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            Text("Drug \(slotIndex + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Group {
                if slot.isFilled {
                    filledContent
                } else {
                    emptyContent
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: slot.isFilled)
        }
        .cardStyle()
    }

    private var filledContent: some View {
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
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Clear drug \(slotIndex + 1)")
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var emptyContent: some View {
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
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
