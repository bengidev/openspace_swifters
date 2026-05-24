import ComposableArchitecture

struct ExampleContainer: Reducer {
    struct State: Equatable {
        var actionCount = 0
        var statusMessage = "Waiting for a NoOp response."
    }

    enum Action: Equatable {
        case primaryButtonTapped
        case noOpResponse(String)
    }

    @Dependency(\.noOp) private var noOp

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .primaryButtonTapped:
                state.actionCount += 1
                state.statusMessage = "Calling NoOp…"
                return .run { send in
                    await send(.noOpResponse(noOp.call()))
                }

            case let .noOpResponse(response):
                state.statusMessage = response
                return .none
            }
        }
    }
}
