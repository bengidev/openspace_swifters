import SwiftUI

struct OnboardingResponseLineView: View {
    let width: CGFloat
    let active: Bool
    let delay: Double

    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.18),
                            palette.textPrimary.opacity(0.20),
                            palette.textMuted.opacity(0.12),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: proxy.size.width * width, height: 8)
                .opacity(active ? 1 : 0)
                .offset(x: active ? 0 : -12)
                .animation(.easeOut(duration: 0.34).delay(delay), value: active)
        }
        .frame(height: 8)
    }
}
