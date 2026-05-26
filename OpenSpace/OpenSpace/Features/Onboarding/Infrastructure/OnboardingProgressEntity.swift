import Foundation
import SwiftData

/// Gating record for first-run onboarding flows.
/// Per ADR-0017, the v1 schema carries one row at most — a singleton
/// progress marker.
///
/// - First launch: no row exists → `loadProgress()` returns `nil`.
/// - Completion: one row is upserted with `completedAt` and the
///   app version that completed onboarding.
@Model
final class OnboardingProgressEntity: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var completedAt: Date?
    var completedAtAppVersion: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        completedAtAppVersion: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.completedAtAppVersion = completedAtAppVersion
    }
}
