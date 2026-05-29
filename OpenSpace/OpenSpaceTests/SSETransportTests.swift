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
            #expect(events[0].data == "hello")
            #expect(events[1].data == "world")
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

// MARK: - SSETransport parser integration tests

/// Tests that verify the transport correctly pipes response lines
/// through the shared SSEParser.
@MainActor
struct SSETransportParserIntegrationTests {

    /// Parser correctly processes multiple events from lines.
    @Test func parserProcessesMultipleEvents() async {
        let lines = [
            "data: hello world",
            "",
            "data: second event",
            "",
        ]

        let stream = SSEParser.parse(testAsyncLines(lines))
        let events = await collectSSEEvents(stream)

        #expect(events.count == 2)
        #expect(events[0].data == "hello world")
        #expect(events[1].data == "second event")
    }

    /// Parser handles empty input.
    @Test func parserHandlesEmptyInput() async {
        let lines: [String] = []

        let stream = SSEParser.parse(testAsyncLines(lines))
        let events = await collectSSEEvents(stream)

        #expect(events.isEmpty)
    }

    /// Parser handles events with names and IDs.
    @Test func parserHandlesNamedEvents() async {
        let lines = [
            "event: message",
            "data: first",
            "",
            "id: 42",
            "data: second",
            "",
            "data: third",
            "",
        ]

        let stream = SSEParser.parse(testAsyncLines(lines))
        let events = await collectSSEEvents(stream)

        #expect(events.count == 3)
        #expect(events[0].event == "message")
        #expect(events[0].data == "first")
        #expect(events[1].id == "42")
        #expect(events[1].data == "second")
        #expect(events[2].data == "third")
    }

    // MARK: - Helpers

    private func testAsyncLines(_ lines: [String]) -> AsyncStream<String> {
        AsyncStream { continuation in
            for line in lines {
                continuation.yield(line)
            }
            continuation.finish()
        }
    }

    private func collectSSEEvents(
        _ stream: AsyncThrowingStream<SSEEvent, Error>
    ) async -> [SSEEvent] {
        var result: [SSEEvent] = []
        do {
            for try await event in stream {
                result.append(event)
            }
        } catch {
            Issue.record("Unexpected parser error: \(error)")
        }
        return result
    }
}

// MARK: - SSETransport cancellation test

/// Tests that verify cancellation behavior.
@MainActor
struct SSETransportCancellationTests {

    /// Cancelling the consuming task stops the stream without
    /// yielding a half-event.
    @Test func cancellationStopsStreamWithoutHalfEvent() async {
        // Use the same pattern as SSEParserTests for cancellation.
        let gate = PartialYieldedGate()
        let stream = SSEParser.parse(partialThenHang(gate: gate))

        let count = await withTaskGroup(
            of: Int.self,
            returning: Int.self
        ) { group in
            group.addTask {
                var count = 0
                do {
                    for try await _ in stream {
                        count += 1
                    }
                } catch {
                    // Cancellation — expected path.
                }
                return count
            }

            // Wait until the partial line is in the parser, then cancel.
            await gate.waitUntilYielded()
            group.cancelAll()
            return await group.next() ?? 0
        }

        // No complete events should have been emitted.
        #expect(count == 0)
    }

    // MARK: - Helpers

    private func partialThenHang(
        gate: PartialYieldedGate
    ) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                continuation.yield("data: partial")
                await gate.signalYielded()
                // Never call continuation.finish() — cancellation must terminate.
            }
        }
    }
}

// MARK: - Cancellation gate

/// Awaitable one-shot gate that resolves once the partial line has been
/// yielded into the parser. Lets the cancellation test be deterministic
/// rather than relying on `Task.sleep` timing.
private actor PartialYieldedGate {
    private var yielded = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func signalYielded() {
        guard !yielded else { return }
        yielded = true
        let pending = waiters
        waiters = []
        for waiter in pending { waiter.resume() }
    }

    func waitUntilYielded() async {
        if yielded { return }
        await withCheckedContinuation { waiters.append($0) }
    }
}

// MARK: - Mock URL protocol for openStream integration tests

/// Base class for per-test `URLProtocol` subclasses.
///
/// Each integration test creates a unique subclass (e.g.,
/// `DiagnosticContextProtocol`, `SuccessProtocol`) so that parallel
/// tests never share a static handler. Override `handler` in each
/// subclass to return the canned response for that test.
private class MockURLProtocolBase: URLProtocol, @unchecked Sendable {

    override class func canInit(
        with request: URLRequest
    ) -> Bool { true }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest { request }

    override func startLoading() {
        fatalError("Subclass must override startLoading()")
    }

    override func stopLoading() {}

    /// Helper used by subclasses to deliver a canned response.
    fileprivate func deliver(
        _ response: HTTPURLResponse,
        _ data: Data
    ) {
        client?.urlProtocol(
            self,
            didReceive: response,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

/// Protocol for `nonSuccessErrorCarriesDiagnosticContext`.
private final class DiagnosticContextProtocol: MockURLProtocolBase {
    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "application/json",
                "Retry-After": "60",
            ]
        )!
        let body = Data(
            #"{"error": "invalid API key"}"#.utf8
        )
        deliver(response, body)
    }
}

/// Protocol for `bodyExcerptCappedAtMaxLength`.
private final class OversizedBodyProtocol: MockURLProtocolBase {
    override func startLoading() {
        let oversizedBody = String(
            repeating: "x",
            count: 2048 + 500
        )
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 500,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        deliver(response, Data(oversizedBody.utf8))
    }
}

/// Protocol for `nonSuccessStatusHostIsHostOnly`.
private final class HostOnlyProtocol: MockURLProtocolBase {
    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 403,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        deliver(response, Data("forbidden".utf8))
    }
}

/// Protocol for `nonSuccessStatusRetryAfterNilWhenMissing`.
private final class MissingRetryAfterProtocol: MockURLProtocolBase {
    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        deliver(response, Data("rate limited".utf8))
    }
}

/// Protocol for `openStreamSuccessYieldsParsedEvents`.
private final class SuccessSSEProtocol: MockURLProtocolBase {
    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/event-stream"]
        )!
        let body = Data(
            "data: hello\n\ndata: world\n\n".utf8
        )
        deliver(response, body)
    }
}
