import SwiftUI

struct DrugInputView: View {
    @Environment(AppNavigator.self) private var navigator
    var viewModel: DrugInputViewModel

    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<2, id: \.self) { index in
                DrugSlotCard(
                    slotIndex: index,
                    slot: viewModel.slots[index],
                    onScan: { navigator.navigate(to: .scan(slot: index)) },
                    onType: { navigator.navigate(to: .search(slot: index)) },
                    onClear: { viewModel.clearSlot(index: index) }
                )
            }

            Spacer()

            Button {
                let names = viewModel.drugNames
                guard names.count == 2 else { return }
                navigator.navigate(to: .results(drugA: names[0], drugB: names[1]))
            } label: {
                Text("Check Interactions")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.bothFilled ? Color.accentColor : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.bothFilled)
        }
        .padding()
        .navigationTitle("New Check")
    }
}
