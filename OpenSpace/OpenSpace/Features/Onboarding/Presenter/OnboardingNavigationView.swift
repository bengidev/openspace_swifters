import ComposableArchitecture
import SwiftUI

struct OnboardingNavigationView: View {
    let store: StoreOf<OnboardingFlow>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 20) {
                pageIndicator

                HStack(spacing: 12) {
                    if store.currentPage > 0 {
                        Button(String(localized: "Back")) {
                            store.send(.previousTapped)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(String(localized: "Previous onboarding page"))
                    }

                    Button(store.isLastPage
                        ? String(localized: "Get Started")
                        : String(localized: "Next")
                    ) {
                        store.send(
                            store.isLastPage ? .finishTapped : .nextTapped
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(store.isLastPage
                        ? String(localized: "Enter OpenSpace")
                        : String(localized: "Continue onboarding")
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<store.totalPages, id: \.self) { index in
                Button {
                    store.send(.pageTapped(index))
                } label: {
                    Circle()
                        .fill(index == store.currentPage ? Color.accentColor : Color.secondary.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
                .accessibilityLabel(String(localized: "Go to onboarding page \(index + 1)"))
            }
        }
        .accessibilityLabel(String(localized: "Page \(store.currentPage + 1) of \(store.totalPages)"))
    }
}

#Preview {
    OnboardingNavigationView(
        store: Store(initialState: OnboardingFlow.State()) {
            OnboardingFlow()
        }
    )
}
