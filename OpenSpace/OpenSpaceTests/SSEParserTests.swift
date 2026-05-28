import Foundation
@testable import OpenSpace
import Testing

@MainActor
struct SSEParserTests {

    // MARK: - Data-only events

    /// Single data line terminated by blank line.
    @Test func parsesDataOnlyEvent() async {
        let lines = ["data: hello world", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].event == nil)
        #expect(events[0].data == "hello world")
        #expect(events[0].id == nil)
    }

    /// Multiple data lines joined with newline separators.
    @Test func parsesMultipleDataLines() async {
        let lines = [
            "data: line one",
            "data: line two",
            "data: line three",
            "",
        ]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "line one\nline two\nline three")
    }

    // MARK: - Event with event name

    /// `event:` field + `data:` field.
    @Test func parsesNamedEvent() async {
        let lines = ["event: message", "data: content", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].event == "message")
        #expect(events[0].data == "content")
    }

    // MARK: - Event with id

    @Test func parsesEventWithId() async {
        let lines = ["id: 42", "data: payload", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].id == "42")
        #expect(events[0].data == "payload")
    }

    // MARK: - Blank-line termination

    /// Two events separated by blank lines.
    @Test func blankLineTerminatesEvent() async {
        let lines = ["data: first", "", "data: second", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 2)
        #expect(events[0].data == "first")
        #expect(events[1].data == "second")
    }

    /// Consecutive blank lines produce no spurious events.
    @Test func consecutiveBlankLinesProduceNoEvents() async {
        let lines = ["data: one", "", "", "", "data: two", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 2)
    }

    // MARK: - Comment lines

    /// Lines starting with `:` are ignored.
    @Test func commentLinesAreIgnored() async {
        let lines = [": this is a keep-alive", "data: real event", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "real event")
    }

    // MARK: - End-of-stream flush

    /// Event not terminated by blank line at end of stream.
    @Test func flushesUnterminatedEventAtEndOfStream() async {
        let lines = ["data: no trailing blank"]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "no trailing blank")
    }

    // MARK: - Empty / no-event input

    @Test func emptyInputProducesNoEvents() async {
        let lines: [String] = []

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.isEmpty)
    }

    @Test func onlyBlankLinesProduceNoEvents() async {
        let lines = ["", "", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.isEmpty)
    }

    // MARK: - OpenAI [DONE] sentinel

    /// `data: [DONE]` is a normal data event (codec decides disposal).
    @Test func openAIDoneSentinelIsNormalEvent() async {
        let lines = ["data: [DONE]", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "[DONE]")
    }

    // MARK: - Leading space stripping

    /// Single leading space after colon is stripped per spec.
    @Test func stripsLeadingSpaceFromValue() async {
        let lines = ["data: spaced", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events[0].data == "spaced")
    }

    /// No space after colon — value still parsed.
    @Test func noSpaceAfterColonStillParses() async {
        let lines = ["data:nospaces", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events[0].data == "nospaces")
    }

    // MARK: - Record without data is discarded

    /// Event field alone with no data — discarded.
    @Test func recordWithoutDataIsDiscarded() async {
        let lines = ["event: heartbeat", "", "data: real", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "real")
    }

    // MARK: - Helpers

    @Test func upstreamErrorPropagatesWithoutFlushingPartialEvent() async {
        let stream = SSEParser.parse(throwingAfterPartialEvent())
        var iterator = stream.makeAsyncIterator()

        do {
            _ = try await iterator.next()
            Issue.record("Expected upstream failure")
        } catch let error as TestSSEError {
            #expect(error == .upstreamFailed)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func collect(
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

// MARK: - Test fixture helper

/// Converts a `[String]` into a sending `AsyncStream<String>` so tests
/// can feed canned line fixtures into the parser without an external
/// dependency like `swift-async-algorithms`.
private func testAsync(_ lines: [String]) -> AsyncStream<String> {
    AsyncStream { continuation in
        for line in lines {
            continuation.yield(line)
        }
        continuation.finish()
    }
}

private enum TestSSEError: Error, Equatable {
    case upstreamFailed
}

private func throwingAfterPartialEvent() -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        continuation.yield("data: partial")
        continuation.finish(throwing: TestSSEError.upstreamFailed)
    }
}
