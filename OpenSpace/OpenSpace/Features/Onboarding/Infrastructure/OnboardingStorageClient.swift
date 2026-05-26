import ComposableArchitecture
import Foundation
import SwiftData

// MARK: - Client

struct OnboardingStorageClient: Sendable {
    /// Returns `nil` on first launch; the completed entity otherwise.
    var loadProgress: @Sendable () async throws -> OnboardingProgressEntity?

    /// Upserts the singleton progress entity with `completedAt` and the
    /// caller-supplied app version string.
    var recordCompletion: @Sendable (_ appVersion: String) async throws -> Void
}

// MARK: - DependencyKey

extension OnboardingStorageClient: DependencyKey {
    /// Sentinel — crashes loudly when the Composition Root forgets to
    /// inject a live implementation.
    static let liveValue = Self(
        loadProgress: {
            fatalError(
                """
                OnboardingStorageClient.loadProgress was called but no live \
                implementation is registered. Inject `.onboardingStorage` \
                via `live(modelContainer:)` at the Composition Root.
                """
            )
        },
        recordCompletion: { _ in
            fatalError(
                """
                OnboardingStorageClient.recordCompletion was called but no live \
                implementation is registered. Inject `.onboardingStorage` \
                via `live(modelContainer:)` at the Composition Root.
                """
            )
        }
    )

    /// Factory producing a client backed by a `ModelContainer`.
    /// Each operation opens a fresh `ModelContext` from the container.
    static func live(modelContainer: ModelContainer) -> Self {
        let container = modelContainer
        return Self(
            loadProgress: {
                let context = ModelContext(container)
                let descriptor = FetchDescriptor<OnboardingProgressEntity>()
                let results = try context.fetch(descriptor)
                return results.first
            },
            recordCompletion: { appVersion in
                let context = ModelContext(container)
                let descriptor = FetchDescriptor<OnboardingProgressEntity>()
                let existing = try context.fetch(descriptor).first
                if let entity = existing {
                    entity.completedAt = Date()
                    entity.completedAtAppVersion = appVersion
                } else {
                    let entity = OnboardingProgressEntity(
                        createdAt: Date(),
                        completedAt: Date(),
                        completedAtAppVersion: appVersion
                    )
                    context.insert(entity)
                }
                try context.save()
            }
        )
    }

    /// In-memory test implementation.
    ///
    /// - First call to `loadProgress` returns `nil`.
    /// - After `recordCompletion`, subsequent `loadProgress` returns the
    ///   completed entity.
    static let testValue: Self = {
        let store = TestProgressStore()
        return Self(
            loadProgress: { await store.progress },
            recordCompletion: { appVersion in
                await store.setProgress(
                    OnboardingProgressEntity(
                        id: UUID(),
                        createdAt: Date(),
                        completedAt: Date(),
                        completedAtAppVersion: appVersion
                    )
                )
            }
        )
    }()
}

// MARK: - DependencyValues

extension DependencyValues {
    var onboardingStorage: OnboardingStorageClient {
        get { self[OnboardingStorageClient.self] }
        set { self[OnboardingStorageClient.self] = newValue }
    }
}

// MARK: - Test helper

private actor TestProgressStore {
    var progress: OnboardingProgressEntity?

    func setProgress(_ entity: OnboardingProgressEntity) {
        progress = entity
    }
}
