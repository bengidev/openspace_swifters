import SwiftUI

struct OnboardingEncryptedPairingVisualView: View {
    let isConfirmed: Bool
    let appeared: Bool
    let onToggle: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                OnboardingDeviceNodeView(title: "LOCAL", subtitle: "Local key", systemImage: "iphone", active: isConfirmed)
                    .offset(x: appeared ? 0 : -24)
                Spacer(minLength: 6)
                OnboardingDeviceNodeView(title: "OPENSPACE", subtitle: "AI chat lane", systemImage: "macbook", active: true)
                    .offset(x: appeared ? 0 : 24)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 8) {
                ZStack {
                    Capsule(style: .continuous)
                        .stroke(palette.border.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))
                        .frame(height: 3)
                        .padding(.horizontal, 82)

                    Circle()
                        .fill(palette.accent)
                        .frame(width: 9, height: 9)
                        .shadow(color: palette.accent.opacity(0.45), radius: 10)
                        .offset(x: isConfirmed ? 56 : -56)
                        .animation(.spring(response: 0.46, dampingFraction: 0.72), value: isConfirmed)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(palette.inverseSurface)
                        .frame(width: 82, height: 82)
                        .overlay(
                            Image(systemName: isConfirmed ? "lock.shield.fill" : "lock.open.trianglebadge.exclamationmark")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(isConfirmed ? palette.accent : palette.warning)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(palette.textPrimary.opacity(palette.isDark ? 0.15 : 0.08), lineWidth: 1)
                        )
                }

                Button(action: onToggle) {
                    HStack(spacing: 7) {
                        Image(systemName: isConfirmed ? "arrow.triangle.2.circlepath" : "link.badge.plus")
                        Text(isConfirmed ? "ROTATE KEY" : "PAIR DEVICE")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(-0.24)
                    .foregroundStyle(isConfirmed ? palette.accent : palette.warning)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill((isConfirmed ? palette.accent : palette.warning).opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke((isConfirmed ? palette.accent : palette.warning).opacity(0.32), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isConfirmed ? "Rotate encryption key" : "Pair device")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
