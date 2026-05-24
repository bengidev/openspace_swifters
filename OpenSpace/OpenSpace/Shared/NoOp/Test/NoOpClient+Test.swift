extension NoOpClient {
    static let test = Self(
        call: { "NoOp Test response" }
    )
}
