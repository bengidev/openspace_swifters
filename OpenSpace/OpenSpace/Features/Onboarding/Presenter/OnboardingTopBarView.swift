import ComposableArchitecture
import SwiftUI

struct OnboardingTopBarView: View {
    let store: StoreOf<OnboardingFlow>
    let onThemeToggle: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 9) {
                ThemeToggleButton(onTap: onThemeToggle)

                VStack(alignment: .leading, spacing: 1) {
                    Text("OPENSPACE")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.textPrimary)
                    Text("AI ASSISTANCE")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(palette.textMuted)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("OpenSpace AI assistance")

            Spacer(minLength: 10)

            Text("PG.\(zeroPadded(store.currentPage + 1)) / \(zeroPadded(store.totalPages))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(-0.24)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Button {
                _ = store.send(.skipTapped)
            } label: {
                Text("SKIP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(palette.surface.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip onboarding")
        }
        .frame(height: 44)
    }

    private func zeroPadded(_ value: Int) -> String {
        let text = String(value)
        return text.count == 1 ? "0\(text)" : text
    }
}
