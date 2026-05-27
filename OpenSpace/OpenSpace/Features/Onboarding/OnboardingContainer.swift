import ComposableArchitecture
import Foundation
import SwiftUI

struct OnboardingContainerView: View {
    let store: StoreOf<OnboardingContainer>
    var onCompletion: (() -> Void)?
    var onThemeToggle: (() -> Void)?

    var body: some View {
        OnboardingView(
            store: store.scope(state: \.flow, action: \.flow),
            onThemeToggle: {
                store.send(.themeToggleTapped)
                onThemeToggle?()
            }
        )
        .onChange(of: store.state.isFinished) { _, isFinished in
            if isFinished { onCompletion?() }
        }
        .overlay(alignment: .bottom) {
            if let message = store.state.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 82)
            }
        }
    }
}

/// Parent reducer for the Onboarding feature.
///
/// Scopes `OnboardingFlow` for the reference visual carousel and owns the
/// persistence gate: reads progress at launch and writes completion when the
/// user enters OpenSpace on the final page.
@Reducer
struct OnboardingContainer {
    @ObservableState
    struct State: Equatable {
        var flow = OnboardingFlowState()
        var isFinished = false
        var errorMessage: String?
    }

    @CasePathable
    enum Action: Equatable {
        case task
        case progressLoaded(Bool)
        case themeToggleTapped
        case flow(OnboardingFlowAction)
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
                    let progress = try? await onboardingStorage.loadProgress()
                    await send(.progressLoaded(progress?.completedAt != nil))
                }

            case let .progressLoaded(didCompletePreviously):
                if didCompletePreviously {
                    state.isFinished = true
                    return .send(.delegate(.onboardingCompleted))
                }
                return .none

            case .themeToggleTapped:
                return .none

            case .flow(.finishTapped):
                return .run { send in
                    let appVersion = Bundle.main
                        .object(forInfoDictionaryKey: "CFBundleShortVersionString")
                        as? String ?? "0.0.0"
                    do {
                        try await onboardingStorage.recordCompletion(appVersion)
                        await send(.delegate(.onboardingCompleted))
                    } catch {
                        await send(.recordCompletionFailed(error.localizedDescription))
                    }
                }

            case let .recordCompletionFailed(message):
                state.errorMessage = message
                return .none

            case .flow:
                return .none

            case .delegate(.onboardingCompleted):
                state.isFinished = true
                return .none
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
    .environment(\.palette, OpenSpacePalette.resolve(.dark))
}
