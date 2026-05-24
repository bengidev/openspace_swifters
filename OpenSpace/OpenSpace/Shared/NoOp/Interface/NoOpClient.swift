import ComposableArchitecture

struct NoOpClient: Sendable {
    var call: @Sendable () async -> String
}

extension NoOpClient: DependencyKey {
    static let liveValue = Self.live
    static let testValue = Self.test
}

extension DependencyValues {
    var noOp: NoOpClient {
        get { self[NoOpClient.self] }
        set { self[NoOpClient.self] = newValue }
    }
}
