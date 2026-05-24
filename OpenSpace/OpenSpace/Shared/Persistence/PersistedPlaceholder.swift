import Foundation
import SwiftData

@Model
final class PersistedPlaceholder {
    var id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}
