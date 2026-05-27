import SwiftUI

struct OnboardingReasoningPresetButtonView: View {
    let title: String
    let value: Double
    @Binding var level: Double

    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                level = value
            }
        } label: {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .tracking(-0.24)
                .foregroundStyle(abs(level - value) < 0.08 ? palette.primaryActionText : palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(abs(level - value) < 0.08 ? palette.primaryActionFill : palette.surface.opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(abs(level - value) < 0.08 ? palette.primaryActionFill.opacity(0.3) : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
