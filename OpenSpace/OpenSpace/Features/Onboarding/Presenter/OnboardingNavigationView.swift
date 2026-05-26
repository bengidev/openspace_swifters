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
                        Button("Back") {
                            store.send(.previousTapped)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(store.isLastPage ? "Get Started" : "Next") {
                        store.send(
                            store.isLastPage ? .finishTapped : .nextTapped
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<store.totalPages, id: \.self) { index in
                Circle()
                    .fill(index == store.currentPage ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityLabel("Page \(store.currentPage + 1) of \(store.totalPages)")
    }
}

#Preview {
    OnboardingNavigationView(
        store: Store(initialState: OnboardingFlow.State()) {
            OnboardingFlow()
        }
    )
}
