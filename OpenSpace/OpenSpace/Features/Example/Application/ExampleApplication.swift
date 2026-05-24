import ComposableArchitecture

struct ExampleContainer: Reducer {
    struct State: Equatable {
        var actionCount = 0
        var statusMessage = "Waiting for an example action."
    }

    enum Action: Equatable {
        case primaryButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .primaryButtonTapped:
                state.actionCount += 1
                state.statusMessage = "Reducer handled \(state.actionCount) example action."
                return .none
            }
        }
    }
}
