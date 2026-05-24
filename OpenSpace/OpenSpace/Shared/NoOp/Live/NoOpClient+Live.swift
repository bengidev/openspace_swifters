extension NoOpClient {
    static let live = Self(
        call: { "NoOp Live response" }
    )
}
