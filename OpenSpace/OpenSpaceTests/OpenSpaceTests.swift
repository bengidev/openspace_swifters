import ComposableArchitecture
@testable import OpenSpace
import Testing

struct OpenSpaceTests {
    @Test func exampleContainerCallsNoOpDependency() async {
        let store = TestStore(initialState: ExampleContainer.State()) {
            ExampleContainer()
        } withDependencies: {
            $0.noOp.call = { "Stubbed NoOp response" }
        }

        await store.send(.primaryButtonTapped) {
            $0.actionCount = 1
            $0.statusMessage = "Calling NoOp…"
        }

        await store.receive(.noOpResponse("Stubbed NoOp response")) {
            $0.statusMessage = "Stubbed NoOp response"
        }
    }
}
