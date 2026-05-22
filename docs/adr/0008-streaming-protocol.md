# 0008. Streaming protocol: event-shaped enum with reserved tool-call cases

- Status: Accepted
- Date: 2026-05-22

## Context

The Assistant streams tokens, not whole responses. Each vendor
delivers that stream in a different framing — server-sent events with
distinct payload shapes, message types, and termination signals. The
shared Provider Interface (ADR-0006) needs a single streaming type
that reducers can consume without caring which vendor produced it.

Two further forces apply:

- TCA reducers consume effects as discrete actions. A stream type
  modelled as raw text deltas plus an optional terminator is awkward
  for a reducer; richer events (start, delta, finish, error) reduce
  branching at the call site.
- Tool calls (function calling, content blocks with tool_use) are not
  in v1 scope, but they will land in v2. Designing the streaming type
  without them now and bolting them on later means a breaking change
  to the shared Interface and every reducer that consumes it.

## Decision

The shared streaming type is an `enum StreamEvent` with a small set
of cases, distributed to reducers as `AsyncThrowingStream<StreamEvent,
Error>` from the Provider Interface.

The cases are:

- `messageStart(MessageStartInfo)` — emitted once at stream open.
  Carries vendor-supplied identifiers (message id, model echoed back)
  for diagnostics and persistence.
- `textDelta(String)` — incremental text content; the reducer
  appends to the current assistant message buffer.
- `messageStop(StopReason)` — emitted once on graceful end. Carries
  a normalised stop reason (`endTurn`, `maxTokens`, `stopSequence`,
  `vendorSpecific(String)`).
- `usage(Usage)` — optional, vendor-dependent. Token counts when the
  vendor reports them.

We **reserve, but do not yet emit**, the following cases for v2 tool
calls:

- `toolUseStart(ToolUseStartInfo)`
- `toolUseDelta(ToolUseDelta)`
- `toolUseStop(ToolUseStopInfo)`

The reserved cases are present in the enum from day one so adding
tool-call support in v2 is purely additive on the Interface side.
Reducers in v1 handle them with `@unknown default`-style branches that
route to a dedicated "unsupported event" log path; they never crash.

Vendor mapping rules:

- OpenAI/OpenRouter: `delta.content` chunks → `textDelta`. The
  terminating chunk with `finish_reason` → `messageStop` with the
  reason mapped onto `StopReason`.
- Anthropic: `content_block_delta` of type `text_delta` → `textDelta`.
  `message_stop` → `messageStop`. `content_block_start` /
  `content_block_delta` of type `tool_use` are silently dropped in
  v1 (they cannot occur if v1 never sends tool definitions); the
  reserved cases above are how v2 will surface them.

## Consequences

What gets easier:

- Reducers consume one shape regardless of vendor. The `chat-stream`
  effect is one switch, not three vendor-specific switches.
- Adding tool-call support in v2 is additive. The Interface, the
  reducer's event-handling switch, and persistence schemas grow new
  cases without rewriting existing call sites.
- Stop reasons are normalised, so reducer logic that depends on
  *why* the model stopped (e.g. retry on `maxTokens`) is portable
  across vendors.

What gets harder:

- Vendors evolve their streaming protocols. We will track each
  vendor's framing in its Live implementation's tests and update the
  mapping when a new event type appears. The shared enum may need
  new cases over time.
- The reserved tool-call cases are dead code in v1. We accept the
  cost of carrying them as documentation and as forward-compat
  scaffolding.

What we accept:

- A small loss of fidelity at the boundary: vendor-specific stop
  reasons that do not map cleanly fall into
  `vendorSpecific(String)`. Reducers must not branch on
  `vendorSpecific` payload values; they are diagnostics only.
- Backpressure is managed at the consumer end. The stream type does
  not impose flow control; reducers cancel via TCA effect
  cancellation (ADR-0002).

## Alternatives considered

- **Raw `AsyncThrowingStream<String, Error>` of text chunks.**
  Rejected. Loses metadata (stop reasons, usage), and the reducer
  cannot tell graceful end from an error close without a sentinel.
- **Mirror the OpenAI streaming chunk shape in the Interface.**
  Rejected. Couples the shared Interface to one vendor's wire
  format and forces awkward translation for Anthropic.
- **Defer tool-call cases to v2 and break the enum then.** Rejected.
  Forces a coordinated migration of every reducer in v2 and
  invalidates fixtures. Reserving cases now is cheap insurance.
- **A protocol-based event type (existential `any StreamEvent`).**
  Rejected. The case set is small and known; an enum gives
  exhaustive switches and better diagnostics than open-ended
  protocol existentials.
