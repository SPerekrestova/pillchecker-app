import SwiftUI

struct AnimatedCheckmark: View {
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(Theme.safe)
            .accessibilityHidden(true)
            .scaleEffect(appeared || reduceMotion ? 1 : 0)
            .opacity(appeared || reduceMotion ? 1 : 0)
            .onAppear {
                guard !reduceMotion else { appeared = true; return }
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    appeared = true
                }
            }
    }
}
