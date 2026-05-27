import SwiftUI

struct OnboardingReasoningControlVisualView: View {
    @Binding var reasoningLevel: Double
    let appeared: Bool

    @Environment(\.palette) private var palette

    private var percentage: Int {
        Int((reasoningLevel * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(palette.border.opacity(0.75), lineWidth: 1)
                        .frame(width: 76, height: 76)
                    Circle()
                        .trim(from: 0, to: reasoningLevel)
                        .stroke(palette.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 76, height: 76)
                        .animation(.spring(response: 0.42, dampingFraction: 0.74), value: reasoningLevel)
                    Text("\(percentage)%")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .tracking(-0.24)
                        .foregroundStyle(palette.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(reasoningLabel.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(-0.24)
                        .foregroundStyle(palette.accent)
                    Text("Set thinking before run.")
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(palette.textMuted)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
            }

            Slider(value: $reasoningLevel, in: 0...1)
                .tint(palette.accent)
                .accessibilityLabel("Reasoning level")
                .accessibilityValue("\(percentage) percent")

            HStack(spacing: 7) {
                OnboardingReasoningPresetButtonView(title: "FAST", value: 0.22, level: $reasoningLevel)
                OnboardingReasoningPresetButtonView(title: "BALANCED", value: 0.62, level: $reasoningLevel)
                OnboardingReasoningPresetButtonView(title: "DEEP", value: 0.9, level: $reasoningLevel)
            }

            HStack(alignment: .bottom, spacing: 7) {
                ForEach(0..<8, id: \.self) { index in
                    let normalizedIndex = Double(index + 1) / 8
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(normalizedIndex <= reasoningLevel ? palette.accent : palette.textMuted.opacity(0.22))
                        .frame(height: 12 + CGFloat(index) * 4)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(y: appeared ? 1 : 0.35, anchor: .bottom)
                        .animation(.spring(response: 0.42, dampingFraction: 0.8).delay(Double(index) * 0.035), value: appeared)
                }
            }
            .frame(height: 44)
        }
        .padding(.horizontal, 4)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private var reasoningLabel: String {
        switch reasoningLevel {
        case ..<0.38: "Fast answer"
        case ..<0.76: "Balanced plan"
        default: "Deep reasoning"
        }
    }
}
