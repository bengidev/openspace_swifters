import ComposableArchitecture
@testable import OpenSpace
import Testing

struct OpenSpaceTests {
    @MainActor
    @Test func exampleContainerCallsNoOpDependency() async {
        let store = TestStore(initialState: ExampleContainer.State()) {
            ExampleContainer(noOp: NoOpClient(call: { "Stubbed NoOp response" }))
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
