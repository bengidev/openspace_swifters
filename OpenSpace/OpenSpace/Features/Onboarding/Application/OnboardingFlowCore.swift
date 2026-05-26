import ComposableArchitecture

/// Slide state machine for the onboarding carousel.
///
/// Owns page advancement and boundary clamping. Does **not** call
/// persistence — the parent `OnboardingContainer` handles storage
/// when the user taps "Get Started" on the final slide.
@Reducer
struct OnboardingFlow {
    @ObservableState
    struct State: Equatable {
        var currentPage: Int = 0
        let totalPages: Int = OnboardingSlide.all.count

        var isLastPage: Bool { currentPage == totalPages - 1 }
        var currentPageData: Int {
            min(max(currentPage, 0), totalPages - 1)
        }
    }

    @CasePathable
    enum Action: Equatable {
        case nextTapped
        case previousTapped
        case finishTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextTapped:
                state.currentPage = min(
                    state.currentPage + 1,
                    state.totalPages - 1
                )
                return .none

            case .previousTapped:
                state.currentPage = max(
                    state.currentPage - 1,
                    0
                )
                return .none

            case .finishTapped:
                // Container observes this and handles persistence.
                return .none
            }
        }
    }
}
