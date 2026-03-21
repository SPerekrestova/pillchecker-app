import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Label("No internet connection", systemImage: "wifi.slash")
            .font(.callout)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(light: Color(hex: 0xC2410C), dark: Theme.warning))
            .accessibilityAddTraits(.isStaticText)
    }
}
