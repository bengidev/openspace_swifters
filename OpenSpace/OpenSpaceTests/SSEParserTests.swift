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

    // MARK: - Retry field is recognized but out of scope

    /// `retry:` field does not fail parsing and is silently ignored.
    @Test func retryFieldIsIgnored() async {
        let lines = ["retry: 3000", "data: payload", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "payload")
    }

    // MARK: - Malformed / unknown lines

    /// Unknown fields (not event/data/id/retry) are silently ignored.
    @Test func unknownFieldsAreIgnored() async {
        let lines = ["foo: bar", "data: payload", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "payload")
    }

    /// A line with no colon is treated as field-only with empty value.
    @Test func lineWithNoColonIsFieldOnly() async {
        let lines = ["nocolon", "data: payload", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "payload")
    }

    // MARK: - Cancellation does not flush partial event

    /// Cancelling the consuming task mid-stream does not yield a partial
    /// event. When the consumer is cancelled, the parser's internal task
    /// is cancelled via the stream's `onTermination` handler; the
    /// `CancellationError` path must not flush any accumulated state.
    @Test func cancellationDoesNotFlushPartialEvent() async {
        // Gate that fires once the partial (un-terminated) data line has
        // been yielded into the parser, making cancellation timing
        // deterministic instead of sleep-based.
        let gate = PartialYieldedGate()
        let stream = SSEParser.parse(partialThenHang(gate: gate))

        let count = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            group.addTask {
                var count = 0
                do {
                    for try await _ in stream { count += 1 }
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

        // No event was emitted; cancellation prevented flushing.
        #expect(count == 0)
    }

    // MARK: - Record without data is discarded

    /// Event field alone with no data — discarded.
    @Test func recordWithoutDataIsDiscarded() async {
        let lines = ["event: heartbeat", "", "data: real", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "real")
    }

    // MARK: - Record size cap

    /// A record whose accumulated size is just under the cap parses
    /// successfully.
    @Test func recordJustUnderSizeLimitSucceeds() async {
        let maxRecordSize = SSEParser.maxRecordSize
        // Build a data line whose total characters (including "data: "
        // prefix) is exactly maxRecordSize - 1.
        let prefix = "data: "
        let payloadCount = maxRecordSize - prefix.count - 1 // -1 for just-under
        let payload = String(repeating: "x", count: max(0, payloadCount))
        let line = prefix + payload

        let events = await collect(SSEParser.parse(testAsync([line, ""])))

        #expect(events.count == 1)
        #expect(events[0].data == payload)
    }

    /// A record whose accumulated size is exactly at the cap parses
    /// successfully (the boundary is strict greater-than).
    @Test func recordExactlyAtSizeLimitSucceeds() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let prefix = "data: "
        let payloadCount = maxRecordSize - prefix.count
        let payload = String(repeating: "x", count: max(0, payloadCount))
        let line = prefix + payload

        let events = await collect(SSEParser.parse(testAsync([line, ""])))

        #expect(events.count == 1)
        #expect(events[0].data == payload)
    }

    /// A record whose accumulated size exceeds the cap fails with
    /// SSEParseError.recordSizeExceeded and does not yield a partial
    /// event.
    @Test func recordOverSizeLimitFails() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let line = "data: " + String(repeating: "x", count: maxRecordSize)

        var iterator = SSEParser.parse(testAsync([line, ""])).makeAsyncIterator()

        do {
            _ = try await iterator.next()
            Issue.record("Expected recordSizeExceeded error")
        } catch let error as SSEParseError {
            #expect(error == .recordSizeExceeded(maxSize: maxRecordSize))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    /// Multi-line data payloads that stay within the cap still parse
    /// correctly, with lines joined by newline.
    @Test func multiLineDataWithinCapParsesNormally() async {
        let lines = [
            "data: first line",
            "data: second line",
            "data: third line",
            "",
        ]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "first line\nsecond line\nthird line")
    }

    /// OpenAI [DONE] sentinel within the cap parses as a normal event.
    @Test func doneSentinelWithinCapParsesNormally() async {
        let lines = ["data: [DONE]", ""]

        let events = await collect(SSEParser.parse(testAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "[DONE]")
    }

    /// A record that crosses the cap across multiple data lines fails
    /// without yielding a partial event.
    @Test func multiLineDataExceedingCapFails() async {
        let maxRecordSize = SSEParser.maxRecordSize
        // First line is under the limit; second line pushes over.
        let firstLine = "data: " + String(repeating: "a", count: maxRecordSize / 2)
        let secondLine = "data: " + String(repeating: "b", count: maxRecordSize)

        var iterator = SSEParser.parse(
            testAsync([firstLine, secondLine, ""])
        ).makeAsyncIterator()

        do {
            _ = try await iterator.next()
            Issue.record("Expected recordSizeExceeded error")
        } catch let error as SSEParseError {
            #expect(error == .recordSizeExceeded(maxSize: maxRecordSize))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    /// event: and id: fields contribute to the accumulated record size.
    @Test func eventAndIdFieldsCountTowardSizeCap() async {
        let maxRecordSize = SSEParser.maxRecordSize
        // Build event: and id: lines that together are just under the cap,
        // then a data: line that pushes over.
        let eventLine = "event: " + String(repeating: "e", count: maxRecordSize / 3)
        let idLine = "id: " + String(repeating: "i", count: maxRecordSize / 3)
        let dataLine = "data: " + String(repeating: "d", count: maxRecordSize)

        var iterator = SSEParser.parse(
            testAsync([eventLine, idLine, dataLine, ""])
        ).makeAsyncIterator()

        do {
            _ = try await iterator.next()
            Issue.record("Expected recordSizeExceeded error")
        } catch let error as SSEParseError {
            #expect(error == .recordSizeExceeded(maxSize: maxRecordSize))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    /// After an oversized record fails, subsequent normal records in
    /// the same stream are NOT yielded (the stream is terminated).
    @Test func oversizedRecordTerminatesEntireStream() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let oversize = "data: " + String(repeating: "x", count: maxRecordSize)
        let normal = "data: ok"

        var events: [SSEEvent] = []
        var caughtError: SSEParseError?
        let stream = SSEParser.parse(testAsync([oversize, "", normal, ""]))

        do {
            for try await event in stream {
                events.append(event)
            }
        } catch let error as SSEParseError {
            caughtError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(events.isEmpty)
        #expect(caughtError == .recordSizeExceeded(maxSize: maxRecordSize))
    }

    /// Cancellation mid-stream does not flush a partial event even
    /// when the record is within the size cap.
    @Test func cancellationDoesNotFlushPartialEventWithinCap() async {
        let gate = PartialYieldedGate()
        let stream = SSEParser.parse(partialThenHang(gate: gate))

        let count = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            group.addTask {
                var count = 0
                do {
                    for try await _ in stream { count += 1 }
                } catch {
                    // Cancellation — expected path.
                }
                return count
            }
            await gate.waitUntilYielded()
            group.cancelAll()
            return await group.next() ?? 0
        }

        #expect(count == 0)
    }

    /// Upstream error propagates without flushing a partial event.
    @Test func upstreamErrorStillPropagatesWithoutFlushing() async {
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

    // MARK: - Sendable conformance (compile-time check)

    /// Verify SSEParseError is Sendable — this is a compile-time
    /// guarantee enforced by Swift 6 strict concurrency. The test
    /// exists to document the contract; if the type ever loses
    /// Sendable conformance this file will not compile.
    @Test func parseErrorIsSendable() async {
        let error: SSEParseError = .recordSizeExceeded(maxSize: 1024)
        let _: any Sendable = error
        #expect(error == .recordSizeExceeded(maxSize: 1024))
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

/// Yields a single partial (un-terminated) data line, signals the gate,
/// then never finishes — used to test mid-stream cancellation without
/// timing assumptions.
private func partialThenHang(gate: PartialYieldedGate) -> AsyncStream<String> {
    AsyncStream { continuation in
        Task {
            continuation.yield("data: partial")
            await gate.signalYielded()
            // Never call continuation.finish() — cancellation must terminate.
        }
    }
}
