import ComposableArchitecture

@ObservableState
struct OnboardingPageDemoState: Equatable {
    var selectedPromptIndex = 0
    var queuedPromptCount = 2
    var reasoningLevel = 0.62
    var pairingConfirmed = true
}

@CasePathable
enum OnboardingPageDemoAction: Equatable {
    case promptChipTapped(Int)
    case addQueuedPromptTapped
    case reasoningLevelChanged(Double)
    case pairingToggleTapped
}

@Reducer
struct OnboardingPageDemo {
    var body: some Reducer<OnboardingPageDemoState, OnboardingPageDemoAction> {
        Reduce { state, action in
            switch action {
            case let .promptChipTapped(index):
                state.selectedPromptIndex = min(max(index, 0), OnboardingPromptOptionModel.samples.count - 1)
                return .none

            case .addQueuedPromptTapped:
                state.queuedPromptCount = state.queuedPromptCount >= OnboardingPromptQueueItemModel.samples.count ? 2 : state.queuedPromptCount + 1
                return .none

            case let .reasoningLevelChanged(value):
                state.reasoningLevel = min(max(value, 0), 1)
                return .none

            case .pairingToggleTapped:
                state.pairingConfirmed.toggle()
                return .none
            }
        }
    }
}
