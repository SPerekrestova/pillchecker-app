import SwiftUI

struct SafeResultView: View {
    let drugA: String
    let drugB: String

    @State private var showTitle = false
    @State private var showSubtitle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            AnimatedCheckmark()

            Text("No Known Interactions")
                .font(.title2.bold())
                .opacity(showTitle || reduceMotion ? 1 : 0)

            Text("\(drugA) and \(drugB) appear safe to take together.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(showSubtitle || reduceMotion ? 1 : 0)
        }
        .padding(32)
        .onAppear {
            guard !reduceMotion else {
                showTitle = true
                showSubtitle = true
                return
            }
            withAnimation(.easeIn.delay(0.2)) { showTitle = true }
            withAnimation(.easeIn.delay(0.4)) { showSubtitle = true }
        }
    }
}
