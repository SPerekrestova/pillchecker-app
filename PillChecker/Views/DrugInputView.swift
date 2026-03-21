import SwiftUI

struct DrugInputView: View {
    @Environment(AppNavigator.self) private var navigator
    var viewModel: DrugInputViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<2, id: \.self) { index in
                    DrugSlotCard(
                        slotIndex: index,
                        slot: viewModel.slots[index],
                        onScan: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            navigator.navigate(to: .scan(slot: index))
                        },
                        onType: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            navigator.navigate(to: .search(slot: index))
                        },
                        onClear: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.clearSlot(index: index)
                        }
                    )
                }

                if viewModel.hasDuplicateDrugs {
                    Text("Both drugs are the same")
                        .font(.callout)
                        .foregroundStyle(Theme.critical)
                        .accessibilityAddTraits(.isStaticText)
                        .transition(.opacity)
                } else if !viewModel.canCheck {
                    Text("Add both drugs to continue")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                let names = viewModel.drugNames
                guard names.count == 2 else { return }
                navigator.navigate(to: .results(drugA: names[0], drugB: names[1]))
            } label: {
                Text("Check Interactions")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canCheck)
            .padding()
            .background(.bar)
        }
        .navigationTitle("New Check")
        .onChange(of: viewModel.hasDuplicateDrugs) {
            if viewModel.hasDuplicateDrugs {
                UIAccessibility.post(notification: .announcement, argument: "Both drugs are the same")
            }
        }
        .onChange(of: viewModel.canCheck) {
            if viewModel.canCheck {
                UIAccessibility.post(notification: .announcement, argument: "Ready to check interactions")
            }
        }
    }
}
