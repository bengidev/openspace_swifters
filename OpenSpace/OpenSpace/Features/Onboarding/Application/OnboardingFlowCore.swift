import ComposableArchitecture

@ObservableState
struct OnboardingFlowState: Equatable {
    var currentPage = 0
    var isFinished = false
    var pageDemo = OnboardingPageDemoState()

    var totalPages: Int { OnboardingPageModel.all.count }
    var isLastPage: Bool { currentPage >= totalPages - 1 }
    var currentPageData: OnboardingPageModel {
        let safeIndex = min(max(currentPage, 0), totalPages - 1)
        return OnboardingPageModel.all[safeIndex]
    }
}

@CasePathable
enum OnboardingFlowAction: Equatable {
    case nextTapped
    case previousTapped
    case pageSelected(Int)
    case finishTapped
    case skipTapped
    case themeToggleTapped
    case pageDemo(OnboardingPageDemoAction)
}

@Reducer
struct OnboardingFlow {
    var body: some Reducer<OnboardingFlowState, OnboardingFlowAction> {
        Scope(state: \.pageDemo, action: \.pageDemo) {
            OnboardingPageDemo()
        }

        Reduce { state, action in
            switch action {
            case .nextTapped:
                state.currentPage = min(state.currentPage + 1, state.totalPages - 1)
                return .none

            case .previousTapped:
                state.currentPage = max(state.currentPage - 1, 0)
                return .none

            case let .pageSelected(index):
                state.currentPage = min(max(index, 0), state.totalPages - 1)
                return .none

            case .finishTapped:
                state.isFinished = true
                return .none

            case .skipTapped:
                state.currentPage = state.totalPages - 1
                return .none

            case .themeToggleTapped, .pageDemo:
                return .none
            }
        }
    }
}
