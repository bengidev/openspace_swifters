import Foundation
@testable import OpenSpace
import Testing

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
class MockURLProtocolBase: URLProtocol, @unchecked Sendable {

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
final class DiagnosticContextProtocol: MockURLProtocolBase {
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
final class OversizedBodyProtocol: MockURLProtocolBase {
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
final class HostOnlyProtocol: MockURLProtocolBase {
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
final class MissingRetryAfterProtocol: MockURLProtocolBase {
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
final class SuccessSSEProtocol: MockURLProtocolBase {
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
