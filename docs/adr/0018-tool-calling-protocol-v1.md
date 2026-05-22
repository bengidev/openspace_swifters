# 0018. Tool-calling protocol v1: reserve event types only, no domain tool surface

- Status: Accepted
- Date: 2026-05-22

## Context

Both v1 dialects (ADR-0007) support tool / function calling on the
wire: OpenAI-compatible chat completions expose `tools` plus
`tool_choice`; Anthropic Messages expose `tools` plus a
`tool_use` / `tool_result` content-block exchange. ADR-0008 already
reserves `toolUseStart` / `toolUseDelta` / `toolUseStop` cases on the
shared `StreamEvent` enum so v2 can land additively.

The remaining question for v1 is whether OpenSpace itself ships any
**domain-level tools** — surfaces a tool registry, exposes a tool
registration API to features, persists tool calls and tool results,
or renders tool invocations in the UI. Shipping any of these in v1
locks the product into a tool model before we have a single tool
worth shipping. Skipping all of them entirely creates a v2 cliff if
the streaming surface is not already tool-aware.

The tension resolves cleanly: stream-shape forward-compat is cheap
and was already paid in ADR-0008; product-surface tool support is
expensive and unjustified at v1.

## Decision

The tool-calling protocol in v1 is **reserved event types only on
the streaming Interface**. There is no domain tool surface.

Concretely:

- The shared `StreamEvent` enum (ADR-0008) keeps the reserved cases
  `toolUseStart(ToolUseStartInfo)`, `toolUseDelta(ToolUseDelta)`, and
  `toolUseStop(ToolUseStopInfo)`. The associated value types
  (`ToolUseStartInfo`, `ToolUseDelta`, `ToolUseStopInfo`) are
  declared with the minimum shape needed to carry vendor data
  through to a future v2 reducer — at minimum a vendor-supplied tool
  call id, a tool name, and an opaque `Data` payload for arguments.
- Live Providers in v1 **do not send tool definitions** in any
  request. The OpenAI-compatible request builder omits the `tools`
  and `tool_choice` fields; the Anthropic request builder omits its
  `tools` field. Consequently no vendor produces tool-use events and
  the reserved cases never fire.
- If a vendor produces a tool-use event anyway (a misbehaving model,
  a server-side defaults change), the Live Provider maps it onto the
  reserved cases and emits it. No reducer in v1 consumes those
  cases; the shared "unsupported event" log path documented in
  ADR-0008 records the occurrence and the stream continues. The user
  sees the same Conversation behaviour as if the event had not been
  emitted.
- The persistence schema (ADR-0017) **does not include tool-call or
  tool-result entities**. There is no `ToolCallEntity`,
  `ToolResultEntity`, or tool-shaped audit row in v1. The
  `TurnAuditEntity.stopReason` enum may carry a future
  `toolUse` case at the Schema-V2 boundary; v1 does not.
- The Provider Interface (ADR-0006) **does not expose a tool
  registry** or a tool registration API. Features cannot register
  tools in v1 because there are no tools to register.
- The composer surface in v1 has **no tool-related affordance** —
  no "use tools" toggle, no tool picker, no tool-call rendering.

The forward-compat budget v1 pays is exactly:

- Three enum cases on `StreamEvent`.
- Three associated value types whose shape is tested only by
  round-trip fixtures (vendor JSON in, enum out, opaque payload
  preserved).
- A "drop with log" path in every reducer that consumes the stream.

Anything beyond that — registries, persistence, UI, request-side
emission of tools — is **out of scope for v1** and lands in a
deliberate v2 ADR cluster that will define:

- The domain shape of a Tool.
- How tools register (composition root, per-feature, dynamic).
- The persistence shape for tool calls and results, with
  attachment-style hashing for arguments and outputs.
- The Conversation-level UX for tool invocations.
- Vendor mapping for `tool_choice` semantics, parallel calls, and
  tool-result content blocks.

## Consequences

What gets easier:

- The v1 surface is honest. No half-built tool API misleads feature
  authors into thinking they can ship a tool today.
- The streaming Interface is the only piece of code that knows tools
  exist, and even it only knows the case names. Reducers stay
  vendor-agnostic and tool-agnostic.
- The v2 tool ADR cluster has full freedom to design the domain
  surface. It is not constrained by an early v1 sketch that nobody
  used.

What gets harder:

- A future contributor reading the streaming Interface will see
  three enum cases that never fire. The cases carry doc comments
  pointing at this ADR so the intent is unmistakable.
- If a vendor ships a tool-use event by surprise on a non-tool
  request, the Conversation may stall briefly while the reducer
  drops it. We accept this — the alternative is to crash on
  `@unknown default` in v1.

What we accept:

- v1 cannot use any feature that requires tool calling — function
  calling, structured tool output, browsing tools, code
  interpreter, retrieval. Users wanting those features stay on
  vendor-native apps until v2.
- We are committing the streaming type ahead of the rest of the
  tool design. If v2 discovers the reserved cases need a different
  shape, we will evolve them through a streaming-protocol ADR
  rather than pretending the v1 reservation was perfectly aimed.

## Alternatives considered

- **Ship a full tool surface in v1.** Rejected. Multiplies the v1
  surface area (registry, persistence, UI, request mapping, two
  vendor mappings of `tool_choice` and tool-result blocks) without
  a concrete tool to validate the shape.
- **Reserve nothing; let v2 break the streaming enum.** Rejected by
  ADR-0008 already. Forces a coordinated migration of every reducer
  in v2 and invalidates fixtures.
- **Reserve cases plus a tiny `ToolRegistry` Client with no
  implementations.** Rejected. The empty Client is documentation
  pretending to be code; it invites premature use and constrains
  v2's design freedom.
- **Reserve cases plus persistence (`ToolCallEntity`,
  `ToolResultEntity`) but no UI.** Rejected. The schema is the
  hardest thing to evolve under `VersionedSchema` (ADR-0017);
  freezing tool-shaped entities before tools are designed locks in
  the wrong shape.
- **Forward incoming tool-use events to a generic "tool result"
  feature.** Rejected. A generic surface that surfaces opaque
  payloads to the user is worse than dropping with a log; the user
  sees noise, not a tool.
