import ComposableArchitecture
@testable import OpenSpace
import Foundation
import Testing

struct OpenSpaceTests {

    // MARK: - ExampleContainer

    @MainActor
    @Test func exampleContainerCallsNoOpDependency() async {
        let store = TestStore(initialState: ExampleContainer.State()) {
            ExampleContainer(noOp: .test)
        }

        await store.send(.primaryButtonTapped) {
            $0.actionCount = 1
            $0.statusMessage = "Calling NoOp…"
        }

        await store.receive(.noOpResponse("NoOp Test response")) {
            $0.statusMessage = "NoOp Test response"
        }
    }

    // MARK: - OnboardingContainer

    /// First launch: no progress → Flow presented → completion →
    /// storage written → delegate emitted.
    @MainActor
    @Test func onboardingContainerFirstLaunch() async {
        let store = TestStore(
            initialState: OnboardingContainer.State()
        ) {
            OnboardingContainer()
        } withDependencies: {
            $0.onboardingStorage = .testValue
        }

        // Load progress → nil (first launch).
        await store.send(.task)
        await store.receive(.progressLoaded(false))

        // User taps "Get Started" on the final slide.
        await store.send(.flow(.finishTapped))
        await store.receive(.delegate(.onboardingCompleted))
    }

    /// Returning user: completed progress → delegate emitted immediately
    /// without presenting Flow.
    @MainActor
    @Test func onboardingContainerReturningUser() async {
        let completedEntity = OnboardingProgressEntity(
            id: UUID(),
            createdAt: Date(),
            completedAt: Date(),
            completedAtAppVersion: "1.0.0"
        )

        let store = TestStore(
            initialState: OnboardingContainer.State()
        ) {
            OnboardingContainer()
        } withDependencies: {
            $0.onboardingStorage = OnboardingStorageClient(
                loadProgress: { completedEntity },
                recordCompletion: { _ in }
            )
        }

        // Load progress → already completed.
        await store.send(.task)
        await store.receive(.progressLoaded(true)) {
            $0.isFinished = true
        }
        await store.receive(.delegate(.onboardingCompleted))
    }

    /// Storage failure: `recordCompletion` throws → error surfaced
    /// in state, no delegate emitted.
    @MainActor
    @Test func onboardingContainerRecordCompletionFailure() async {
        let store = TestStore(
            initialState: OnboardingContainer.State()
        ) {
            OnboardingContainer()
        } withDependencies: {
            $0.onboardingStorage = OnboardingStorageClient(
                loadProgress: { nil },
                recordCompletion: { _ in
                    throw NSError(
                        domain: "test",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "disk full"
                        ]
                    )
                }
            )
        }

        // Load progress → nil (first launch).
        await store.send(.task)
        await store.receive(.progressLoaded(false))

        // User taps "Get Started" → recordCompletion throws.
        await store.send(.flow(.finishTapped))
        await store.receive(.recordCompletionFailed("disk full")) {
            $0.errorMessage = "disk full"
        }
        // No .delegate(.onboardingCompleted) — TestStore exhaustivity
        // guarantees this.
    }
}
