import Foundation

/// A vendor-neutral transport adapter that opens a streaming `URLRequest`
/// through `URLSession` and yields parsed `SSEEvent` values.
///
/// `SSETransport` uses `URLSession.bytes(for:)` for streaming HTTP
/// responses, validates that the response is a successful SSE stream,
/// and pipes response lines through the shared `SSEParser` to produce
/// parsed events.
///
/// The transport contains no vendor-specific payload decoding or
/// `ProviderError` mapping — those responsibilities belong to the
/// Provider Live implementations. Transport errors are typed via
/// ``SSETransportError`` so callers can switch over failures for
/// structured mapping and diagnostics.
///
/// Cancellation: cancelling the consuming `Task` cancels the underlying
/// `URLSession` data task and stops yielding events without emitting
/// partial records.
enum SSETransport {

    /// Maximum number of characters captured from a non-2xx response
    /// body for diagnostic excerpts. Prevents unbounded memory use
    /// when the server returns a large error payload (e.g., an HTML
    /// error page).
    static let bodyExcerptMaxLength = 2048

    /// Opens a streaming SSE connection and yields parsed events.
    ///
    /// This method:
    /// 1. Opens the request via `URLSession.bytes(for:)`.
    /// 2. Validates the HTTP response status code is 2xx.
    /// 3. For non-2xx responses, reads a body excerpt for diagnostics
    ///    and throws ``SSETransportError/nonSuccessStatus``.
    /// 4. Validates the `Content-Type` header contains `text/event-stream`.
    /// 5. Feeds response lines through `SSEParser.parse(_:)`.
    /// 6. Yields parsed `SSEEvent` values.
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
        let host = extractHost(from: request.url)

        do {
            let (bytes, response) = try await session.bytes(for: request)

            // Validate HTTP status code and capture error context
            // for non-2xx responses.
            let httpResponse = try await validateResponse(
                response,
                host: host,
                bodyLines: bytes.lines
            )

            // Validate Content-Type.
            try validateContentType(httpResponse)

            // Feed lines through the shared parser.
            return SSEParser.parse(bytes.lines)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as SSETransportError {
            throw error
        } catch {
            throw SSETransportError.transportFailure(
                error.localizedDescription
            )
        }
    }

    // MARK: - Validation helpers

    /// Validates that the response is an HTTP response with a 2xx status
    /// code. For non-2xx responses, reads a body excerpt and throws
    /// ``SSETransportError/nonSuccessStatus`` with diagnostic context.
    static func validateResponse(
        _ response: URLResponse,
        host: String,
        bodyLines: AsyncLineSequence<URLSession.AsyncBytes>
    ) async throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SSETransportError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyExcerpt = await readBodyExcerpt(from: bodyLines)
            throw SSETransportError.nonSuccessStatus(
                status: httpResponse.statusCode,
                host: host,
                bodyExcerpt: bodyExcerpt,
                retryAfter: httpResponse.value(
                    forHTTPHeaderField: "Retry-After"
                )
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

    // MARK: - Backward-compatible validation

    /// Validates that the response is an HTTP response with a 2xx status
    /// code. Throws ``SSETransportError/nonSuccessStatus`` for non-2xx
    /// responses.
    ///
    /// This is a synchronous convenience for testing and lightweight
    /// validation. Use ``validateResponse(_:host:bodyLines:)`` in
    /// ``openStream(_:session:)`` for full error context including
    /// body excerpt and host.
    static func validateHTTPResponse(
        _ response: URLResponse
    ) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SSETransportError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SSETransportError.nonSuccessStatus(
                status: httpResponse.statusCode,
                host: "",
                bodyExcerpt: "",
                retryAfter: nil
            )
        }
        return httpResponse
    }

    // MARK: - Diagnostic helpers

    /// Extracts the host component from a URL, stripping the scheme,
    /// path, query, and fragment. Returns `"unknown"` if the URL is
    /// nil or has no host.
    ///
    /// This prevents leaking full URLs (which may contain API keys
    /// in query parameters) into error payloads.
    static func extractHost(from url: URL?) -> String {
        url?.host ?? "unknown"
    }

    /// Reads up to ``bodyExcerptMaxLength`` characters from the body
    /// lines of a non-2xx HTTP response.
    ///
    /// The excerpt is useful for diagnostics and error mapping
    /// without consuming unbounded memory from large error payloads.
    static func readBodyExcerpt(
        from lines: AsyncLineSequence<URLSession.AsyncBytes>
    ) async -> String {
        var excerpt = ""
        do {
            for try await line in lines {
                if !excerpt.isEmpty {
                    excerpt.append("\n")
                }
                excerpt.append(line)
                if excerpt.count >= bodyExcerptMaxLength {
                    break
                }
            }
        } catch {
            // If reading the body fails (e.g., connection reset),
            // return whatever excerpt was captured so far.
        }
        if excerpt.count > bodyExcerptMaxLength {
            excerpt = String(excerpt.prefix(bodyExcerptMaxLength))
        }
        return excerpt
    }
}

/// Errors thrown by ``SSETransport``.
///
/// Each case is typed so callers can switch over transport failures
/// for structured error mapping without depending on string parsing.
/// The SSE module does not map these errors into `ProviderError`
/// directly — that responsibility belongs to the Provider Live layer.
enum SSETransportError: Error, Sendable, Equatable {

    /// The response was not a valid HTTP response.
    case invalidResponse

    /// The HTTP status code was not in the 2xx range.
    ///
    /// Carries diagnostic context for error mapping:
    /// - `status`: the HTTP status code.
    /// - `host`: the request URL's host, without path or query.
    /// - `bodyExcerpt`: up to `bodyExcerptMaxLength` characters of
    ///   the response body for diagnostics.
    /// - `retryAfter`: the raw `Retry-After` header value, if present.
    case nonSuccessStatus(
        status: Int,
        host: String,
        bodyExcerpt: String,
        retryAfter: String?
    )

    /// The `Content-Type` header was present but not an expected SSE
    /// content type.
    case unexpectedContentType(String)

    /// The underlying URLSession transport failed before a response
    /// was received (e.g., DNS failure, connection refused, timeout).
    case transportFailure(String)

    /// The SSE stream was established but the parser encountered an
    /// unrecoverable failure mid-stream.
    case parserFailure
}
