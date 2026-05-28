import Foundation

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

    /// Parses an async sequence of SSE lines into a stream of events.
    ///
    /// - Parameter lines: An async sequence of lines without trailing
    ///   line terminators. No URL, URLSession, or vendor code is
    ///   required.
    /// - Returns: An `AsyncStream<SSEEvent>` that yields each parsed
    ///   record and finishes when the input is exhausted.
    static func parse<L: AsyncSequence & Sendable>(
        _ lines: L
    ) -> AsyncStream<SSEEvent> where L.Element == String {
        AsyncStream<SSEEvent> { continuation in
            let task = Task {
                var event: String?
                var dataLines: [String] = []
                var id: String?

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
                            continue
                        }

                        // Comment line → ignore (keep-alives).
                        if line.hasPrefix(":") { continue }

                        let (field, value) = splitLine(line)

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
                } catch {
                    // Upstream threw (e.g. URLSession cancelled).
                    // Flush nothing; stream terminates below.
                }

                // Flush any unterminated record at end-of-stream.
                if let record = Self.emit(
                    event: event,
                    dataLines: dataLines,
                    id: id
                ) {
                    continuation.yield(record)
                }

                continuation.finish()
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
