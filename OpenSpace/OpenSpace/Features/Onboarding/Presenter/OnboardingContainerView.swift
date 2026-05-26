import ComposableArchitecture
import SwiftUI

/// Placeholder view for the Onboarding feature.
///
/// Full UI (slide carousel, "Get Started" button, progress indicators)
/// lands in P2-S3. This minimal wrapper lets the Composition Root
/// route to the Container without a compile error.
struct OnboardingContainerView: View {
    let store: StoreOf<OnboardingContainer>
    var onCompletion: (() -> Void)?

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.tint)

                Text("Onboarding")
                    .font(.title)
                    .fontWeight(.semibold)

                if let message = store.state.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
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
