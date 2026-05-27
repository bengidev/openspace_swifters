import SwiftUI

struct ThemeToggleButton: View {
    let onTap: () -> Void

    @Environment(\.palette) private var palette
    @Environment(\.appTheme) private var appTheme
    @State private var tapped = false

    private var isSystemMode: Bool {
        appTheme == .system
    }

    private var resolvedIsDark: Bool {
        palette.isDark
    }

    var body: some View {
        ZStack {
            // Track
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(palette.surface.opacity(0.5))
                .frame(width: 30, height: 26)
                .shadow(
                    color: palette.textPrimary.opacity(0.1),
                    radius: 2,
                    x: 0,
                    y: 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(
                            isSystemMode ? palette.strongBorder : palette.border,
                            lineWidth: isSystemMode ? 0.8 : 0.5
                        )
                )

            // Sliding thumb
            HStack {
                if resolvedIsDark, !isSystemMode {
                    Spacer()
                }

                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(palette.accent)
                    .frame(width: 10, height: 20)
                    .shadow(
                        color: palette.accent.opacity(isSystemMode ? 0.30 : 0.50),
                        radius: isSystemMode ? 2 : 4,
                        x: 0,
                        y: 2
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .stroke(
                                isSystemMode
                                    ? palette.textPrimary.opacity(0.08)
                                    : palette.textPrimary.opacity(0.18),
                                lineWidth: 0.5
                            )
                    )
                    .padding(.horizontal, isSystemMode ? 10 : 3)
                    .scaleEffect(tapped ? 0.88 : 1.0)
                    .rotationEffect(.degrees(tapped ? -8 : 0))

                if !resolvedIsDark, !isSystemMode {
                    Spacer()
                }
            }
            .frame(width: 30, height: 26)
        }
        .frame(width: 30, height: 26)
        .scaleEffect(tapped ? 0.94 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.72)) {
                tapped = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.72)) {
                    tapped = false
                    onTap()
                }
            }
        }
    }
}

#Preview("System Light") {
    ThemeToggleButton(onTap: {})
        .environment(\.palette, OpenSpacePalette.resolve(.light))
        .environment(\.appTheme, .system)
        .padding()
}

#Preview("System Dark") {
    ThemeToggleButton(onTap: {})
        .environment(\.palette, OpenSpacePalette.resolve(.dark))
        .environment(\.appTheme, .system)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("Manual Light") {
    ThemeToggleButton(onTap: {})
        .environment(\.palette, OpenSpacePalette.resolve(.light))
        .environment(\.appTheme, .light)
        .padding()
}

#Preview("Manual Dark") {
    ThemeToggleButton(onTap: {})
        .environment(\.palette, OpenSpacePalette.resolve(.dark))
        .environment(\.appTheme, .dark)
        .padding()
        .preferredColorScheme(.dark)
}
