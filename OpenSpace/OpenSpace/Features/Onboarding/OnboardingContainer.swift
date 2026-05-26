import ComposableArchitecture
import Foundation

/// Parent reducer for the Onboarding feature.
///
/// Scopes `OnboardingFlow` for slide navigation and owns the
/// persistence gate: reads progress at launch via
/// `OnboardingStorageClient`, routes to Flow or signals completion,
/// and writes the completion record when the user finishes.
@Reducer
struct OnboardingContainer {
    @ObservableState
    struct State: Equatable {
        var flow: OnboardingFlow.State = OnboardingFlow.State()
        var isFinished: Bool = false
        var errorMessage: String?
    }

    @CasePathable
    enum Action: Equatable {
        case task
        case progressLoaded(Bool)
        case flow(OnboardingFlow.Action)
        case recordCompletionFailed(String)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case onboardingCompleted
        }
    }

    @Dependency(OnboardingStorageClient.self) var onboardingStorage

    var body: some Reducer<State, Action> {
        Scope(state: \.flow, action: \.flow) {
            OnboardingFlow()
        }

        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    let progress = try? await onboardingStorage
                        .loadProgress()
                    let didComplete = progress?.completedAt != nil
                    await send(.progressLoaded(didComplete))
                }

            case let .progressLoaded(didCompletePreviously):
                if didCompletePreviously {
                    state.isFinished = true
                    return .send(.delegate(.onboardingCompleted))
                }
                return .none

            case .flow(.finishTapped):
                return .run { send in
                    let appVersion = Bundle.main
                        .object(
                            forInfoDictionaryKey: "CFBundleShortVersionString"
                        ) as? String ?? "0.0.0"
                    do {
                        try await onboardingStorage.recordCompletion(
                            appVersion
                        )
                        await send(.delegate(.onboardingCompleted))
                    } catch {
                        await send(
                            .recordCompletionFailed(
                                error.localizedDescription
                            )
                        )
                    }
                }

            case let .recordCompletionFailed(message):
                state.errorMessage = message
                return .none

            case .flow:
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
