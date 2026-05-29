import Foundation
@testable import OpenSpace
import Testing

@MainActor
struct SSEParserRecordSizeTests {

    // MARK: - Record size cap

    /// A record whose accumulated UTF-8 byte size is just under the cap
    /// parses successfully.
    @Test func recordJustUnderSizeLimitSucceeds() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let prefix = "data: "
        let payloadByteCount = maxRecordSize - prefix.utf8.count - 1
        let payload = String(repeating: "x", count: payloadByteCount)
        let line = prefix + payload

        #expect(line.utf8.count == maxRecordSize - 1)

        let events = await collect(SSEParser.parse(recordSizeTestAsync([line, ""])))

        #expect(events.count == 1)
        #expect(events[0].data == payload)
    }

    /// A record whose accumulated UTF-8 byte size is exactly at the cap
    /// parses successfully (the boundary is strict greater-than).
    @Test func recordExactlyAtSizeLimitSucceeds() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let prefix = "data: "
        let payloadByteCount = maxRecordSize - prefix.utf8.count
        let payload = String(repeating: "x", count: payloadByteCount)
        let line = prefix + payload

        #expect(line.utf8.count == maxRecordSize)

        let events = await collect(SSEParser.parse(recordSizeTestAsync([line, ""])))

        #expect(events.count == 1)
        #expect(events[0].data == payload)
    }

    /// A record whose accumulated UTF-8 byte size exceeds the cap fails
    /// with SSEParseError.recordSizeExceeded and does not yield a partial
    /// event.
    @Test func recordOverSizeLimitFails() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let line = "data: " + String(repeating: "x", count: maxRecordSize)

        var iterator = SSEParser.parse(
            recordSizeTestAsync([line, ""])
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

    /// Non-ASCII payloads are capped by UTF-8 byte count, not Swift
    /// Character count. This would stay below the old `line.count` cap
    /// while exceeding the documented 1 MiB byte cap.
    @Test func nonASCIIRecordOverByteLimitFails() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let prefix = "data: "
        let scalar = "é"
        let payloadCharacterCount = (
            (maxRecordSize - prefix.utf8.count) / scalar.utf8.count
        ) + 1
        let payload = String(repeating: scalar, count: payloadCharacterCount)
        let line = prefix + payload

        #expect(line.count < maxRecordSize)
        #expect(line.utf8.count > maxRecordSize)

        var iterator = SSEParser.parse(
            recordSizeTestAsync([line, ""])
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

    /// Multi-line data payloads that stay within the cap still parse
    /// correctly, with lines joined by newline.
    @Test func multiLineDataWithinCapParsesNormally() async {
        let lines = [
            "data: first line",
            "data: second line",
            "data: third line",
            "",
        ]

        let events = await collect(SSEParser.parse(recordSizeTestAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "first line\nsecond line\nthird line")
    }

    /// OpenAI [DONE] sentinel within the cap parses as a normal event.
    @Test func doneSentinelWithinCapParsesNormally() async {
        let lines = ["data: [DONE]", ""]

        let events = await collect(SSEParser.parse(recordSizeTestAsync(lines)))

        #expect(events.count == 1)
        #expect(events[0].data == "[DONE]")
    }

    /// A record that crosses the cap across multiple data lines fails
    /// without yielding a partial event.
    @Test func multiLineDataExceedingCapFails() async {
        let maxRecordSize = SSEParser.maxRecordSize
        let firstLine = "data: " + String(repeating: "a", count: maxRecordSize / 2)
        let secondLine = "data: " + String(repeating: "b", count: maxRecordSize)

        var iterator = SSEParser.parse(
            recordSizeTestAsync([firstLine, secondLine, ""])
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
        let eventLine = "event: " + String(repeating: "e", count: maxRecordSize / 3)
        let idLine = "id: " + String(repeating: "i", count: maxRecordSize / 3)
        let dataLine = "data: " + String(repeating: "d", count: maxRecordSize)

        var iterator = SSEParser.parse(
            recordSizeTestAsync([eventLine, idLine, dataLine, ""])
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
        let stream = SSEParser.parse(recordSizeTestAsync([oversize, "", normal, ""]))

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

    /// Cancellation mid-stream does not flush a partial event even when
    /// the record is within the size cap.
    @Test func cancellationDoesNotFlushPartialEventWithinCap() async {
        let gate = RecordSizePartialYieldedGate()
        let stream = SSEParser.parse(recordSizePartialThenHang(gate: gate))

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
        let stream = SSEParser.parse(recordSizeThrowingAfterPartialEvent())
        var iterator = stream.makeAsyncIterator()

        do {
            _ = try await iterator.next()
            Issue.record("Expected upstream failure")
        } catch let error as RecordSizeTestSSEError {
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

// MARK: - Record size test fixtures

private func recordSizeTestAsync(_ lines: [String]) -> AsyncStream<String> {
    AsyncStream { continuation in
        for line in lines {
            continuation.yield(line)
        }
        continuation.finish()
    }
}

private enum RecordSizeTestSSEError: Error, Equatable {
    case upstreamFailed
}

private func recordSizeThrowingAfterPartialEvent() -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        continuation.yield("data: partial")
        continuation.finish(throwing: RecordSizeTestSSEError.upstreamFailed)
    }
}

private actor RecordSizePartialYieldedGate {
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

private func recordSizePartialThenHang(
    gate: RecordSizePartialYieldedGate
) -> AsyncStream<String> {
    AsyncStream { continuation in
        Task {
            continuation.yield("data: partial")
            await gate.signalYielded()
            // Never call continuation.finish() — cancellation must terminate.
        }
    }
}
