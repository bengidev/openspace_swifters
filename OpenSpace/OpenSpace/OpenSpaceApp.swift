import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct OpenSpaceApp: App {
    private let modelContainer: ModelContainer
    private let store: StoreOf<ExampleContainer>

    init() {
        let modelContainer = Self.makeModelContainer()

        self.modelContainer = modelContainer
        self.store = Store(initialState: ExampleContainer.State()) {
            ExampleContainer()
        } withDependencies: {
            $0.noOp = .live
        }
    }

    var body: some Scene {
        WindowGroup {
            ExampleView(store: store)
                .modelContainer(modelContainer)
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: PersistedPlaceholder.self)
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }
    }
}
