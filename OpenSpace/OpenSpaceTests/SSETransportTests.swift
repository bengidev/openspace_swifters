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

    /// 401 Unauthorized throws nonSuccessStatus.
    @Test func rejects401Unauthorized() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        #expect(throws: SSETransportError.nonSuccessStatus(status: 401)) {
            try SSETransport.validateHTTPResponse(response)
        }
    }

    /// 500 Internal Server Error throws nonSuccessStatus.
    @Test func rejects500ServerError() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        #expect(throws: SSETransportError.nonSuccessStatus(status: 500)) {
            try SSETransport.validateHTTPResponse(response)
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
