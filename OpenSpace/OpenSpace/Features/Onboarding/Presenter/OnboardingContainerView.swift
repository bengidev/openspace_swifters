import ComposableArchitecture
import SwiftUI

struct OnboardingContainerView: View {
    let store: StoreOf<OnboardingContainer>
    var onCompletion: (() -> Void)?

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 16) {
                OnboardingView(
                    store: store.scope(state: \.flow, action: \.flow)
                )

                if let message = store.state.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .onChange(of: store.state.isFinished) { _, isFinished in
                if isFinished { onCompletion?() }
            }
        }
    }
}

#Preview {
    OnboardingContainerView(
        store: Store(initialState: OnboardingContainer.State()) {
            OnboardingContainer()
        }
    )
}
