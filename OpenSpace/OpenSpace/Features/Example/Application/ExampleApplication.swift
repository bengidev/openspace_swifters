import ComposableArchitecture
import Foundation

struct ExampleContainer: Reducer {
    struct State: Equatable {
        var actionCount = 0
        var statusMessage = String(localized: "Waiting for a NoOp response.")
    }

    enum Action: Equatable {
        case primaryButtonTapped
        case noOpResponse(String)
    }

    private let noOp: NoOpClient

    init(noOp: NoOpClient = .live) {
        self.noOp = noOp
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .primaryButtonTapped:
                state.actionCount += 1
                state.statusMessage = String(localized: "Calling NoOp…")
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
