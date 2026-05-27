import ComposableArchitecture
import Foundation
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFlow>
    let onThemeToggle: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let compactHeight = size.height < 760
            let horizontalPadding = min(max(size.width * 0.055, 20), 36)
            let visualHeight = max(compactHeight ? 270 : 326, min(size.height * (compactHeight ? 0.39 : 0.43), 390))

            ZStack {
                palette.background
                    .ignoresSafeArea()

                PixelGridBackground(
                    spacing: compactHeight ? 18 : 22,
                    dotSize: 1.0,
                    opacity: palette.isDark ? 0.06 : 0.04
                )
                .ignoresSafeArea()

                DiagonalHatchPattern(
                    spacing: 10,
                    opacity: palette.isDark ? 0.10 : 0.04
                )
                .ignoresSafeArea()

                VStack(spacing: compactHeight ? 12 : 18) {
                    OnboardingTopBarView(store: store, onThemeToggle: onThemeToggle)

                    OnboardingFeaturePageView(
                        page: store.currentPageData,
                        visualHeight: visualHeight,
                        store: store.scope(state: \.pageDemo, action: \.pageDemo)
                    )
                    .id(store.currentPageData.id)
                    .transition(.opacity)

                    OnboardingBottomNavigationView(store: store)
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, compactHeight ? 8 : 12)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 10, 18))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .sensoryFeedback(.selection, trigger: store.currentPage)
        }
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFlowState()) {
            OnboardingFlow()
        },
        onThemeToggle: {}
    )
    .environment(\.palette, OpenSpacePalette.resolve(.dark))
}
