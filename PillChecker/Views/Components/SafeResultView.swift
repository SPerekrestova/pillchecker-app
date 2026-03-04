import SwiftUI

struct SafeResultView: View {
    let drugA: String
    let drugB: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("No Known Interactions")
                .font(.title2.bold())

            Text("\(drugA) and \(drugB) appear safe to take together.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
