import SwiftUI

struct OnboardingWorkspaceReadyVisualView: View {
    let page: OnboardingPageModel
    let appeared: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 7, height: 7)
                        .shadow(color: palette.accent.opacity(0.45), radius: 8)

                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.textMuted)

                    Text("WORKSPACE READY")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(-0.24)
                        .foregroundStyle(palette.textMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(palette.surface.opacity(0.5))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(response: 0.48, dampingFraction: 0.82).delay(0.05), value: appeared)

                Text(page.headline)
                    .font(.system(size: 56, weight: .regular))
                    .tracking(-1.6)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.52, dampingFraction: 0.8).delay(0.12), value: appeared)

                Text(page.body)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.82)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.52, dampingFraction: 0.8).delay(0.20), value: appeared)

                HStack(spacing: 6) {
                    ForEach(Array(page.highlights.enumerated()), id: \.element.id) { index, highlight in
                        Text(highlight.title.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .tracking(-0.24)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(palette.surface.opacity(0.3))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.spring(response: 0.48, dampingFraction: 0.8).delay(0.28 + Double(index) * 0.04), value: appeared)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
