@preconcurrency import SwiftData

/// Single source of truth for the v1 persistence schema (ADR-0017).
/// Future schemas (V2, V3, ...) plug into `OpenSpaceMigrationPlan` with
/// explicit migration stages.
enum OpenSpaceSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            PersistedPlaceholder.self,
            OnboardingProgressEntity.self,
        ]
    }
}

/// Migration plan registered at the Composition Root.
/// Currently single-stage (v1); additive migrations register new schemas
/// and lightweight/custom stages here.
enum OpenSpaceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [OpenSpaceSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
