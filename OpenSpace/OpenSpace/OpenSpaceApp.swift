import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct OpenSpaceApp: App {
    private let modelContainer: ModelContainer

    private let exampleStore: StoreOf<ExampleContainer>
    private let onboardingStore: StoreOf<OnboardingContainer>

    @AppStorage("openspace.appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var appRoute: AppRoute = .onboarding

    enum AppRoute {
        case loading
        case onboarding
        case main
    }

    init() {
        let modelContainer = Self.makeModelContainer()
        self.modelContainer = modelContainer

        self.exampleStore = Store(
            initialState: ExampleContainer.State()
        ) {
            ExampleContainer()
        } withDependencies: {
            $0.noOp = .live
            $0.onboardingStorage = .live(modelContainer: modelContainer)
        }

        self.onboardingStore = Store(
            initialState: OnboardingContainer.State()
        ) {
            OnboardingContainer()
        } withDependencies: {
            $0.onboardingStorage = .live(modelContainer: modelContainer)
        }
    }

    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var body: some Scene {
        WindowGroup {
            let palette = OpenSpacePalette.resolve(
                preferredColorScheme ?? systemColorScheme
            )

            Group {
                switch appRoute {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)

                case .onboarding:
                    OnboardingContainerView(
                        store: onboardingStore,
                        onCompletion: { appRoute = .main },
                        onThemeToggle: { appThemeRaw = appTheme.next.rawValue }
                    )

                case .main:
                    ExampleView(store: exampleStore)
                }
            }
            .environment(\.palette, palette)
            .environment(\.appTheme, appTheme)
            .preferredColorScheme(preferredColorScheme)
            .modelContainer(modelContainer)
            .task {
                let client = OnboardingStorageClient.live(
                    modelContainer: modelContainer
                )
                let progress = try? await client.loadProgress()
                appRoute = (progress == nil)
                    ? .onboarding
                    : .main
            }
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
            fatalError(
                "Failed to create SwiftData model container: \(error)"
            )
        }
    }
}
