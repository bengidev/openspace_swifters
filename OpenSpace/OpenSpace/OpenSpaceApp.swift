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
            $0.onboardingStorage = .live(modelContainer: modelContainer)
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
            // Register every @Model type from OpenSpaceSchemaV1.models here.
            // iOS 17.6 does not support the array-based for: initializer;
            // use the variadic form. Keep this list in sync with the schema.
            return try ModelContainer(
                for: PersistedPlaceholder.self,
                OnboardingProgressEntity.self,
                migrationPlan: OpenSpaceMigrationPlan.self
            )
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }
    }
}
