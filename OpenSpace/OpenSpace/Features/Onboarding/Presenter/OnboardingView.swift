import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFlow>

    private var slide: OnboardingSlide {
        OnboardingSlide.all[store.currentPageData]
    }

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                Spacer(minLength: 32)

                VStack(spacing: 24) {
                    Image(systemName: slide.systemImageName)
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    VStack(spacing: 12) {
                        Text(slide.title)
                            .font(.title)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(slide.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 32)

                OnboardingNavigationView(store: store)
            }
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFlow.State()) {
            OnboardingFlow()
        }
    )
}
