import SwiftUI

struct OnboardingDeviceNodeView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let active: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(palette.surface.opacity(0.5))
                    .frame(width: 76, height: 92)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(active ? palette.accent.opacity(0.52) : palette.border, lineWidth: 1)
                    )
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(active ? palette.textPrimary : palette.textMuted)
            }
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(-0.24)
                    .foregroundStyle(palette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: 108)
    }
}
