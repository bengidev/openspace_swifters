import Foundation

/// A vendor-neutral transport adapter that opens a streaming `URLRequest`
/// through `URLSession` and yields parsed `SSEEvent` values.
///
/// `SSETransport` uses `URLSession.bytes(for:)` for streaming HTTP
/// responses, validates that the response is a successful SSE stream,
/// and pipes response lines through the shared `SSEParser` to produce
/// parsed events.
///
/// The transport handles only the happy path: 2xx responses with
/// `text/event-stream` content type. It contains no vendor-specific
/// payload decoding or `ProviderError` mapping — those responsibilities
/// belong to the Provider Live implementations.
///
/// Cancellation: cancelling the consuming `Task` cancels the underlying
/// `URLSession` data task and stops yielding events without emitting
/// partial records.
enum SSETransport {

    /// Opens a streaming SSE connection and yields parsed events.
    ///
    /// This method:
    /// 1. Opens the request via `URLSession.bytes(for:)`.
    /// 2. Validates the HTTP response status code is 2xx.
    /// 3. Validates the `Content-Type` header contains `text/event-stream`.
    /// 4. Feeds response lines through `SSEParser.parse(_:)`.
    /// 5. Yields parsed `SSEEvent` values.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to stream (typically a POST to a
    ///     vendor's chat/completions endpoint with SSE headers).
    ///   - session: The `URLSession` to use. Defaults to `.shared`.
    /// - Returns: An `AsyncThrowingStream<SSEEvent, Error>` that yields
    ///   each parsed SSE record, finishes when the server closes the
    ///   stream, and throws on HTTP errors or transport failures.
    static func openStream(
        _ request: URLRequest,
        session: URLSession = .shared
    ) async throws -> AsyncThrowingStream<SSEEvent, Error> {
        let (bytes, response) = try await session.bytes(for: request)

        // Validate HTTP status code.
        let httpResponse = try validateHTTPResponse(response)

        // Validate Content-Type.
        try validateContentType(httpResponse)

        // Feed lines through the shared parser.
        return SSEParser.parse(bytes.lines)
    }

    // MARK: - Validation helpers

    /// Validates that the response is an HTTP response with a 2xx status
    /// code. Throws ``SSETransportError/nonSuccessStatus(status:)`` for
    /// non-2xx responses.
    static func validateHTTPResponse(
        _ response: URLResponse
    ) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SSETransportError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SSETransportError.nonSuccessStatus(
                status: httpResponse.statusCode
            )
        }
        return httpResponse
    }

    /// Validates that the response's `Content-Type` header indicates an
    /// SSE stream. Per the SSE specification, the content type must be
    /// `text/event-stream` (case-insensitive, ignoring parameters).
    static func validateContentType(
        _ response: HTTPURLResponse
    ) throws {
        guard let contentType = response.value(
            forHTTPHeaderField: "Content-Type"
        ) else {
            // No Content-Type header — some servers omit it for SSE.
            // Allow this for maximum compatibility.
            return
        }

        // Extract the MIME type, ignoring parameters (e.g., charset).
        let mimeType = contentType
            .split(separator: ";", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        // Allow text/event-stream. Some vendors may use text/plain
        // for backwards compatibility — accept that too.
        let allowedTypes: Set<String> = [
            "text/event-stream",
            "text/plain",
        ]

        guard let mimeType, allowedTypes.contains(mimeType) else {
            throw SSETransportError.unexpectedContentType(contentType)
        }
    }
}

/// Errors thrown by ``SSETransport``.
enum SSETransportError: Error, Sendable, Equatable {

    /// The response was not a valid HTTP response.
    case invalidResponse

    /// The HTTP status code was not in the 2xx range.
    case nonSuccessStatus(status: Int)

    /// The `Content-Type` header was present but not an expected SSE
    /// content type.
    case unexpectedContentType(String)
}