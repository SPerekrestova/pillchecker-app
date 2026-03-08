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

            VStack(spacing: 24) {
                Spacer()

                HStack(spacing: 32) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.accent)
                    Image(systemName: "keyboard")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.accent)
                }

                Text("Scan or Search")
                    .font(.title.bold())

                Text("Take a photo of the medicine label or search by name. Results are saved for reference.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

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

    private func onboardingPage(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text(title)
                .font(.title.bold())

            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}
