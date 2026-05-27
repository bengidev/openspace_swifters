import SwiftUI

struct OnboardingQueueRowView: View {
    let item: OnboardingPromptQueueItemModel
    let index: Int
    let appeared: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 3) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                if index < OnboardingPromptQueueItemModel.samples.count - 1 {
                    Rectangle()
                        .fill(palette.border.opacity(0.72))
                        .frame(width: 1, height: 20)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.status.rawValue)
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .tracking(-0.24)
                        .foregroundStyle(statusColor)
                    Text(item.title)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(item.detail)
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 4)

            Image(systemName: index == 0 ? "hourglass" : "text.line.first.and.arrowtriangle.forward")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(index == 0 ? palette.accent : palette.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(palette.surface.opacity(index == 0 ? 0.5 : 0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(index == 0 ? palette.accent.opacity(0.34) : palette.border, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.38, dampingFraction: 0.8).delay(Double(index) * 0.055), value: appeared)
    }

    private var statusColor: Color {
        switch item.status {
        case .running: palette.accent
        case .next: palette.warning
        case .queued: palette.textSecondary
        case .ready: palette.success
        }
    }
}
