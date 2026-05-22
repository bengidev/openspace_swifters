# 0029. HTTP/SSE: URLSession AsyncBytes plus internal SSEParser; no reconnect/heartbeat/resume in v1

- Status: Accepted
- Date: 2026-05-22

## Context

Every Live Provider in v1 (ADR-0007) talks to a streaming HTTP
endpoint. OpenAI-compatible and Anthropic Messages dialects both
deliver tokens over **server-sent events** (SSE) framed inside an
HTTP/1.1 or HTTP/2 response — `Content-Type: text/event-stream`,
`event: ...` plus `data: ...` lines, double-newline record
separators, terminating sentinel (`data: [DONE]` for
OpenAI-compatible; explicit `event: message_stop` for Anthropic).

Two questions need an architectural answer:

- **Which HTTP client.** A shared platform API, an embedded
  third-party HTTP/2 client, or a vendor SDK.
- **Which SSE parser.** A third-party SSE library, a hand-rolled
  parser, or the vendor SDK's parser.

Three further forces apply:

- **Cancellation.** TCA effect cancellation (ADR-0002) must
  propagate cleanly to the in-flight request and tear it down.
  Anything less leaks sockets and burns user-paid tokens.
- **Resilience scope.** Reconnect, heartbeat, and resume-from-id
  are useful but each one is real engineering. v1 needs the
  smallest stable shape; resilience features come back as
  deliberate additions if the field shows they pay for
  themselves.
- **Test surfaces.** SSE is fiddly enough that every Live
  implementation will sit on top of fixture-driven tests. The
  parser must be a unit-testable seam, not buried inside a
  third-party event handler.

## Decision

The transport in v1 is **`URLSession.bytes(for:)`** — Apple's
streaming bytes API — plus a small **internal SSE parser** at
`OpenSpace/OpenSpace/Shared/Networking/SSEParser.swift`.

**HTTP client.**

- `URLSession` configured per Live Provider with vendor-appropriate
  default headers (`Authorization`, vendor-specific `anthropic-*`
  headers) and a session-level timeout consistent with streaming
  workloads (`timeoutIntervalForRequest = 60`,
  `timeoutIntervalForResource = 600`).
- Streaming requests use `URLSession.bytes(for:)`, which yields an
  `URLSession.AsyncBytes` plus the response. The Live Provider
  validates the status code and `Content-Type: text/event-stream`
  before consuming bytes; an unexpected status maps to a structured
  `ProviderError` (ADR-0006) with the response body captured for
  diagnostics.
- HTTP/2 negotiation is left to the system; we do not force it.
- Cancellation flows through `Task.cancel()`. `URLSession` honours
  task cancellation by closing the underlying connection; the
  reducer's effect cancellation (ADR-0002) is sufficient to stop
  the stream.

**SSE parser.**

- A small, allocation-conscious type that consumes
  `URLSession.AsyncBytes` line-by-line, accumulates `event:`,
  `data:`, and `id:` fields per record, and emits `SSERecord`
  values (`event`, `data`, optional `id`) on each blank-line
  boundary.
- It does not understand vendor payloads. Each Live Provider
  decodes the `data` payload of an `SSERecord` into vendor-shaped
  JSON and maps that into the shared `StreamEvent` (ADR-0008).
- It tolerates UTF-8 boundary splits across chunks (lines are
  buffered as bytes until LF), comment lines (`:` prefix; ignored),
  and the dialect quirk of OpenAI-compatible streams emitting
  `data: [DONE]` as a terminator.
- It lives in `Shared/Networking/`, with Test fixtures (canned
  byte streams) under the corresponding test target.

**Resilience scope — explicitly omitted in v1.**

- **No reconnect.** A dropped stream surfaces as a
  `ProviderError.streamClosed(underlying:)` to the reducer, which
  decides whether to surface UI ("Connection lost — retry?") or
  cancel.
- **No heartbeat / keep-alive injection.** The parser ignores SSE
  comment lines used by some servers as keep-alives but does not
  generate its own; if the server stops sending data the
  `URLSession` resource timeout closes the request.
- **No resume-from-id.** The parser captures `id:` values into the
  `SSERecord` so a future ADR can wire `Last-Event-ID` resume into
  it without changing the parser's public shape, but no Live
  Provider in v1 issues that header.

## Consequences

What gets easier:

- Zero third-party HTTP/SSE dependency. The transport surface is
  Apple-platform code plus one small file we own and test.
- Cancellation Just Works through `Task.cancel()`; we do not
  fight a third-party scheduler.
- Each Live Provider has the same skeleton: build request,
  `bytes(for:)`, validate response, feed bytes through
  `SSEParser`, decode each record, emit `StreamEvent`s. The
  diff between OpenAI-compatible and Anthropic implementations
  is concentrated in JSON decoding and event mapping.
- The parser is unit-tested independently of any vendor; vendor
  Live tests reuse fixtures of `SSERecord` arrays.

What gets harder:

- A hostile or buggy server can deliver pathological frames
  (very long lines, unterminated records, non-UTF8 bytes). The
  parser must enforce a per-record size cap and reject violations
  cleanly; we accept that as parser-level test surface.
- `URLSession` does not surface fine-grained connection events
  (TLS handshake duration, time-to-first-byte beyond what we
  measure ourselves). Telemetry (ADR-0026) measures
  start-to-first-byte at the Live Provider boundary instead.
- Without reconnect, a transient network blip during a long
  generation drops the message. The user retries from the chat
  composer; v1 accepts the friction.

What we accept:

- The parser owns a small but real piece of protocol
  responsibility. We will track the SSE WHATWG spec drift in the
  parser's tests; if a vendor adopts a non-spec extension we map
  it at the Live layer, not the parser.
- Resume-from-id is genuinely useful for long generations on
  flaky networks. v1 explicitly defers it; the `id` field is
  captured so a follow-up ADR can wire it without touching the
  parser shape.

## Alternatives considered

- **Embed a third-party HTTP/2 client (e.g. an
  async-channel-style stack).** Rejected. `URLSession` is
  battle-tested on iOS, integrates with system proxy and VPN
  configuration, and avoids carrying a transitive dependency
  graph for a workload our usage pattern does not stress.
- **Use the OpenAI / Anthropic vendor SDK.** Rejected on two
  counts: ADR-0006 wants vendor specifics behind a Provider
  Interface we control, and the SDKs evolve on their own
  cadence with their own bug surface. Owning the transport keeps
  surprises small.
- **Third-party SSE parser package.** Rejected. The parser is
  ~150 lines of careful code and one of the highest-leverage
  places to own; a dependency here adds little for the audit cost.
- **Combine publishers / async sequences over a custom URL
  protocol.** Rejected. Adds indirection without buying anything
  the `AsyncBytes` API does not already provide.
- **Reconnect / resume-from-id in v1.** Considered seriously;
  rejected. Each is its own design problem (when to retry, how
  to deduplicate, how to surface mid-stream "we lost some
  tokens"). Capturing `id:` in the parser keeps the door open
  for a focused future ADR.
- **Heartbeat injection from client side.** Rejected. The
  client cannot meaningfully inject keep-alives over SSE
  (unidirectional from server to client); the only honest knob
  is the `URLSession` resource timeout, which we tune
  per-environment.
