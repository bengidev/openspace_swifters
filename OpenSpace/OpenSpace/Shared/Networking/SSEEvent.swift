import Foundation

/// A parsed server-sent event carrying optional event name, required data
/// payload, and optional last-event identifier.
///
/// `SSEEvent` is vendor-neutral: it represents a single SSE record as
/// defined by the WHATWG EventSource specification, without any
/// knowledge of the payload format. Provider-specific decoding of the
/// `data` payload into vendor-shaped JSON happens at the Live Provider
/// layer, not here.
struct SSEEvent: Sendable, Equatable {

    /// The event type name from the `event:` field, or `nil` for
    /// unnamed events (the common case in OpenAI-compatible streams).
    let event: String?

    /// The data payload: all `data:` lines within one SSE record,
    /// joined with newline (`\n`) separators.
    let data: String

    /// The last-event identifier from the `id:` field, captured so that
    /// future resume-from-id support can wire `Last-Event-ID` without
    /// changing the parser's public shape.
    let id: String?
}
