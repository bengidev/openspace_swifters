import ComposableArchitecture
import SwiftUI

@main
struct OpenSpaceApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleView(
                store: Store(initialState: ExampleContainer.State()) {
                    ExampleContainer()
                }
            )
        }
    }
}
