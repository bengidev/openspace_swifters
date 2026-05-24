import ComposableArchitecture
@testable import OpenSpace
import Testing

struct OpenSpaceTests {
    @Test func exampleContainerHandlesPrimaryAction() async {
        let store = TestStore(initialState: ExampleContainer.State()) {
            ExampleContainer()
        }

        await store.send(.primaryButtonTapped) {
            $0.actionCount = 1
            $0.statusMessage = "Reducer handled 1 example action."
        }
    }
}
