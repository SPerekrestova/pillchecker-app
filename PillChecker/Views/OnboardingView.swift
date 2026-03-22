import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            onboardingPage(
                icon: "arrow.triangle.2.circlepath",
                title: "Check Drug Interactions",
                body: "Scan or type two medications to check if they're safe to take together."
            )
            .tag(0)

            onboardingPage(
                icons: ["camera.fill", "keyboard"],
                title: "Scan or Search",
                body: "Take a photo of the medicine label or search by name. Results are saved for reference."
            ) {
                Text("For informational purposes only. Not a substitute for professional medical advice. Always consult your doctor or pharmacist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    isComplete = true
                } label: {
                    Text("Get Started")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Single icon page

    private func onboardingPage(icon: String, title: String, body: String) -> some View {
        onboardingPage(icons: [icon], title: title, body: body) {
            EmptyView()
        }
    }

    // MARK: - Multi-icon page with optional footer

    private func onboardingPage<Footer: View>(
        icons: [String],
        title: String,
        body: String,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()

            HStack(spacing: 32) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: icons.count > 1 ? 36 : 48))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }

            Text(title)
                .font(.title.bold())

            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            footer()
        }
    }
}
