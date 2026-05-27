import ComposableArchitecture
import SwiftUI

struct ExampleView: View {
    let store: StoreOf<ExampleContainer>

    @Environment(\.palette) private var palette

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationStack {
                ZStack {
                    palette.background
                        .ignoresSafeArea()

                    PixelGridBackground(
                        spacing: 22,
                        dotSize: 1,
                        opacity: palette.isDark ? 0.06 : 0.04
                    )
                    .ignoresSafeArea()

                    DiagonalHatchPattern(
                        spacing: 10,
                        opacity: palette.isDark ? 0.10 : 0.04
                    )
                    .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 18) {
                        FactoryBadge(title: "Workspace", systemImage: "sparkles")

                        Text("OpenSpace")
                            .font(.system(size: 48, weight: .regular))
                            .tracking(-1.6)
                            .foregroundStyle(palette.textPrimary)

                        Text("AI-native command center. Visual shell is now aligned with the reference factory theme.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(palette.textSecondary)
                            .lineSpacing(4)

                        FactoryCardChrome(cornerRadius: 6) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(palette.accent)
                                        .frame(width: 7, height: 7)
                                    Text("NOOP CLIENT")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .tracking(-0.24)
                                        .foregroundStyle(palette.textSecondary)
                                    Spacer()
                                    Text("LIVE")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .tracking(-0.24)
                                        .foregroundStyle(palette.accent)
                                }

                                Text(viewStore.statusMessage)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(palette.textPrimary)
                                    .accessibilityIdentifier("example-status-message")

                                Button {
                                    viewStore.send(.primaryButtonTapped)
                                } label: {
                                    HStack(spacing: 9) {
                                        Text("CALL NOOP")
                                        Image(systemName: "arrow.up.right")
                                    }
                                }
                                .buttonStyle(FactoryPrimaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("example-noop-action")
                            }
                            .padding(16)
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding(.horizontal, 24)
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        })
    }
}

#Preview {
    ExampleView(
        store: Store(initialState: ExampleContainer.State()) {
            ExampleContainer()
        }
    )
    .environment(\.palette, OpenSpacePalette.resolve(.dark))
    .environment(\.appTheme, AppTheme.dark)
}
