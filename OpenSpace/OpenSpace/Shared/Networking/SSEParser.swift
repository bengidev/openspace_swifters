import Foundation

/// Errors emitted by ``SSEParser`` when it encounters an unrecoverable
/// parse violation mid-stream.
///
/// Each case is typed so Provider Client Live implementations can
/// switch over parse failures for structured mapping to
/// `ProviderError.decoding` without depending on string parsing.
///
/// `SSEParseError` is `Sendable` under Swift 6 complete strict
/// concurrency.
enum SSEParseError: Error, Sendable, Equatable {

    /// The accumulated size of `event:`, `data:`, and `id:` fields
    /// within a single SSE record exceeded ``SSEParser/maxRecordSize``
    /// characters.
    ///
    /// The parser terminates the stream without yielding a partial
    /// event. The associated value is the documented maximum record
    /// size in characters.
    case recordSizeExceeded(maxSize: Int)
}

/// A pure, vendor-neutral SSE line parser that turns an async sequence
/// of wire-format text lines into parsed `SSEEvent` values.
///
/// `SSEParser` knows nothing about HTTP, URLSession, or any vendor
/// dialect. It consumes lines already split on newlines (for example,
/// from `URLSession.AsyncBytes.lines` or a canned test fixture),
/// accumulates `event:`, `data:`, and `id:` fields, and emits a record
/// on each blank-line boundary.
///
/// Comment lines (starting with `:`) are ignored per the WHATWG
/// EventSource specification — this is the mechanism servers use for
/// keep-alive heartbeats.
///
/// Multiple `data:` lines within one event are joined with `\n`,
/// preserving multi-line payloads verbatim.
enum SSEParser {

    /// Maximum number of characters allowed across accumulated
    /// `event:`, `data:`, and `id:` fields within a single SSE record.
    ///
    /// When the accumulated size exceeds this cap, the parser throws
    /// ``SSEParseError/recordSizeExceeded(maxSize:)`` without yielding
    /// a partial event. This guard protects against pathological or
    /// malicious servers delivering unbounded record payloads.
    ///
    /// The value is chosen to comfortably fit any realistic
    /// OpenAI-compatible or Anthropic-compatible streaming record
    /// (typical records are < 1 KB) while preventing multi-megabyte
    /// memory spikes from a misbehaving server.
    static let maxRecordSize: Int = 1 << 20 // 1 MiB

    /// Parses an async sequence of SSE lines into a stream of events.
    ///
    /// - Parameter lines: An async sequence of lines without trailing
    ///   line terminators. No URL, URLSession, or vendor code is
    ///   required.
    /// - Returns: An `AsyncThrowingStream<SSEEvent, Error>` that yields
    ///   each parsed record, finishes when the input is exhausted, and
    ///   propagates upstream sequence failures.
    static func parse<L: AsyncSequence & Sendable>(
        _ lines: L
    ) -> AsyncThrowingStream<SSEEvent, Error> where L.Element == String {
        AsyncThrowingStream<SSEEvent, Error> { continuation in
            let task = Task {
                var event: String?
                var dataLines: [String] = []
                var id: String?
                var recordSize: Int = 0

                do {
                    for try await line in lines {
                        if line.isEmpty {
                            // Blank line terminates the current record.
                            if let record = Self.emit(
                                event: event,
                                dataLines: dataLines,
                                id: id
                            ) {
                                continuation.yield(record)
                            }
                            event = nil
                            dataLines = []
                            id = nil
                            recordSize = 0
                            continue
                        }

                        // Comment line → ignore (keep-alives).
                        if line.hasPrefix(":") { continue }

                        let (field, value) = splitLine(line)

                        // Enforce per-record size cap. The accumulated
                        // size includes the field name, colon, and value
                        // for each line in the record.
                        recordSize += line.count
                        if recordSize > Self.maxRecordSize {
                            throw SSEParseError.recordSizeExceeded(
                                maxSize: Self.maxRecordSize
                            )
                        }

                        switch field {
                        case "event":
                            event = value.isEmpty ? nil : value
                        case "data":
                            dataLines.append(value)
                        case "id":
                            id = value.isEmpty ? nil : value
                        default:
                            // Unknown fields (e.g. "retry") silently
                            // ignored per spec.
                            break
                        }
                    }

                    // Flush any unterminated record only after normal
                    // end-of-stream. A thrown upstream error/cancel must
                    // not emit a partial record.
                    if let record = Self.emit(
                        event: event,
                        dataLines: dataLines,
                        id: id
                    ) {
                        continuation.yield(record)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    // MARK: - Internal helpers

    /// Builds an `SSEEvent` from accumulated fields, or returns `nil`
    /// if no `data:` lines were collected (a record without data is
    /// discarded per the SSE specification).
    private static func emit(
        event: String?,
        dataLines: [String],
        id: String?
    ) -> SSEEvent? {
        guard !dataLines.isEmpty else { return nil }
        return SSEEvent(
            event: event,
            data: dataLines.joined(separator: "\n"),
            id: id
        )
    }

    /// Splits one SSE line on the first colon. Returns the field name
    /// and value, stripping a single leading space from the value per
    /// the WHATWG EventSource specification.
    private static func splitLine(_ line: String) -> (String, String) {
        guard let colonIndex = line.firstIndex(of: ":") else {
            return (line, "")
        }
        let field = String(line[..<colonIndex])
        var valueIndex = line.index(after: colonIndex)
        if valueIndex < line.endIndex, line[valueIndex] == " " {
            valueIndex = line.index(after: valueIndex)
        }
        let value = String(line[valueIndex...])
        return (field, value)
    }
}
