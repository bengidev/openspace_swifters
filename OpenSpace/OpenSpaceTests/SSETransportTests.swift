import Foundation
@testable import OpenSpace
import Testing

// MARK: - SSETransport validation tests

@MainActor
struct SSETransportValidationTests {

    // MARK: - HTTP response validation

    /// 200 OK is accepted.
    @Test func accepts200OK() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        let validated = try SSETransport.validateHTTPResponse(response)
        #expect(validated.statusCode == 200)
    }

    /// 201 Created is accepted (any 2xx).
    @Test func accepts201Created() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 201,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        let validated = try SSETransport.validateHTTPResponse(response)
        #expect(validated.statusCode == 201)
    }

    /// 401 Unauthorized throws nonSuccessStatus with the status code.
    @Test func rejects401Unauthorized() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        do {
            try SSETransport.validateHTTPResponse(response)
            Issue.record("Expected nonSuccessStatus")
        } catch let error as SSETransportError {
            guard case let .nonSuccessStatus(status, _, _, _) = error else {
                Issue.record("Expected nonSuccessStatus, got \(error)")
                return
            }
            #expect(status == 401)
        }
    }

    /// 500 Internal Server Error throws nonSuccessStatus with the
    /// status code.
    @Test func rejects500ServerError() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        do {
            try SSETransport.validateHTTPResponse(response)
            Issue.record("Expected nonSuccessStatus")
        } catch let error as SSETransportError {
            guard case let .nonSuccessStatus(status, _, _, _) = error else {
                Issue.record("Expected nonSuccessStatus, got \(error)")
                return
            }
            #expect(status == 500)
        }
    }

    /// Non-HTTP response throws invalidResponse.
    @Test func rejectsNonHTTPResponse() throws {
        let response = URLResponse(
            url: URL(string: "https://example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        #expect(throws: SSETransportError.invalidResponse) {
            try SSETransport.validateHTTPResponse(response)
        }
    }

    // MARK: - Host extraction

    /// Extracts the host from a valid URL, stripping scheme, path, and
    /// query parameters.
    @Test func extractHostFromValidURL() throws {
        let url = URL(
            string: "https://api.example.com/v1/chat?key=secret"
        )
        #expect(SSETransport.extractHost(from: url) == "api.example.com")
    }

    /// Returns "unknown" when the URL is nil.
    @Test func extractHostFromNilURL() {
        #expect(SSETransport.extractHost(from: nil) == "unknown")
    }

    /// Extracts host from a URL with a port number.
    @Test func extractHostIncludesPort() throws {
        let url = URL(string: "https://localhost:8080/sse")
        #expect(SSETransport.extractHost(from: url) == "localhost")
    }

    // MARK: - Non-success status error fields

    /// The nonSuccessStatus error carries host, bodyExcerpt, and
    /// retryAfter when the full openStream flow is exercised.
    @Test func nonSuccessErrorCarriesDiagnosticContext() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DiagnosticContextProtocol.self]
        let session = URLSession(configuration: config)
        let request = URLRequest(
            url: URL(string: "https://api.example.com/v1/chat")!
        )

        do {
            _ = try await SSETransport.openStream(
                request,
                session: session
            )
            Issue.record("Expected nonSuccessStatus error")
        } catch let error as SSETransportError {
            guard case let .nonSuccessStatus(
                status,
                host,
                bodyExcerpt,
                retryAfter
            ) = error else {
                Issue.record(
                    "Expected nonSuccessStatus, got \(error)"
                )
                return
            }
            #expect(status == 401)
            #expect(host == "api.example.com")
            #expect(
                bodyExcerpt
                    == #"{"error": "invalid API key"}"#
            )
            #expect(retryAfter == "60")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// Body excerpt is capped at bodyExcerptMaxLength.
    @Test func bodyExcerptCappedAtMaxLength() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [OversizedBodyProtocol.self]
        let session = URLSession(configuration: config)
        let request = URLRequest(
            url: URL(string: "https://api.example.com/v1/chat")!
        )

        do {
            _ = try await SSETransport.openStream(
                request,
                session: session
            )
            Issue.record("Expected nonSuccessStatus error")
        } catch let error as SSETransportError {
            guard case let .nonSuccessStatus(_, _, bodyExcerpt, _) = error
            else {
                Issue.record(
                    "Expected nonSuccessStatus, got \(error)"
                )
                return
            }
            #expect(
                bodyExcerpt.count
                    == SSETransport.bodyExcerptMaxLength
            )
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// The host field in nonSuccessStatus contains only the host
    /// component — no path, query, or fragment.
    @Test func nonSuccessStatusHostIsHostOnly() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [HostOnlyProtocol.self]
        let session = URLSession(configuration: config)
        let request = URLRequest(
            url: URL(
                string: "https://api.example.com/v1/chat?api_key=secret"
            )!
        )

        do {
            _ = try await SSETransport.openStream(
                request,
                session: session
            )
            Issue.record("Expected nonSuccessStatus error")
        } catch let error as SSETransportError {
            guard case let .nonSuccessStatus(_, host, _, _) = error
            else {
                Issue.record(
                    "Expected nonSuccessStatus, got \(error)"
                )
                return
            }
            #expect(host == "api.example.com")
            // Host must not contain path or query.
            #expect(!host.contains("/"))
            #expect(!host.contains("api_key"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// Missing Retry-After header results in nil retryAfter.
    @Test func nonSuccessStatusRetryAfterNilWhenMissing() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MissingRetryAfterProtocol.self]
        let session = URLSession(configuration: config)
        let request = URLRequest(
            url: URL(string: "https://api.example.com/v1/chat")!
        )

        do {
            _ = try await SSETransport.openStream(
                request,
                session: session
            )
            Issue.record("Expected nonSuccessStatus error")
        } catch let error as SSETransportError {
            guard case let .nonSuccessStatus(
                status, _, _, retryAfter
            ) = error else {
                Issue.record(
                    "Expected nonSuccessStatus, got \(error)"
                )
                return
            }
            #expect(status == 429)
            #expect(retryAfter == nil)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// A successful openStream yields parsed SSE events through the
    /// parser (happy-path regression).
    @Test func openStreamSuccessYieldsParsedEvents() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SuccessSSEProtocol.self]
        let session = URLSession(configuration: config)
        let request = URLRequest(
            url: URL(string: "https://api.example.com/v1/chat")!
        )

        do {
            let stream = try await SSETransport.openStream(
                request,
                session: session
            )
            var events: [SSEEvent] = []
            for try await event in stream {
                events.append(event)
            }
            #expect(events.count == 2)
            #expect(events.first?.data == "hello")
            #expect(events.dropFirst().first?.data == "world")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Content-Type validation

    /// text/event-stream is accepted.
    @Test func acceptsTextEventStream() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/event-stream"]
        )!

        // Should not throw.
        try SSETransport.validateContentType(response)
    }

    /// text/event-stream with charset parameter is accepted.
    @Test func acceptsTextEventStreamWithCharset() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/event-stream; charset=utf-8"]
        )!

        // Should not throw.
        try SSETransport.validateContentType(response)
    }

    /// text/plain is accepted for backward compatibility.
    @Test func acceptsTextPlain() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )!

        // Should not throw.
        try SSETransport.validateContentType(response)
    }

    /// Missing Content-Type header is accepted.
    @Test func acceptsMissingContentType() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        // Should not throw.
        try SSETransport.validateContentType(response)
    }

    /// application/json throws unexpectedContentType.
    @Test func rejectsApplicationJSON() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        #expect(throws: SSETransportError.unexpectedContentType("application/json")) {
            try SSETransport.validateContentType(response)
        }
    }

    /// Case-insensitive content type matching.
    @Test func acceptsCaseInsensitiveContentType() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "Text/Event-Stream"]
        )!

        // Should not throw (case-insensitive).
        try SSETransport.validateContentType(response)
    }
}
