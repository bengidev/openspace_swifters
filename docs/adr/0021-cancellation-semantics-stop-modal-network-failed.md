# 0021. Cancellation semantics: Stop modal Keep/Discard; network drop equals .failed

- Status: Accepted
- Date: 2026-05-22

## Context

A streaming turn (ADR-0008) can end in several ways: it completes
normally, the user taps Stop, or the network connection drops mid-
stream. Each ending must produce a deterministic, observable end
state on the Conversation and a coherent UX, and the three endings
must be distinguishable so the user (and the audit log) can tell a
deliberate stop from a connectivity failure.

Two questions hang together. First: when the user taps Stop on a
partially-streamed assistant message, what happens to the partial
text? Discarding it surprises a user who tapped Stop because the
answer was already good enough; keeping it surprises a user who
tapped Stop because the answer was off and now expects a clean
state. Second: when the network drops mid-stream, should the UI
behave the same as a user-initiated cancellation (showing a Keep/
Discard prompt) or differently (treating it as a failure mode)?

There is also a structural concern. The TCA cancellation idiom
(cancellable effects, `.cancel(id:)`) gives us deterministic effect
teardown but does not by itself decide what to persist. The decision
must answer:

- What modal, if any, does Stop present?
- What is the persisted message state for each branch?
- How is a network-induced end-of-stream distinguished from a user-
  induced one?
- Does the user get a chance to recover a network-dropped partial?

## Decision

User-initiated cancellation (Stop button on a streaming message)
opens a **modal with two actions: Keep partial / Discard**, plus a
Cancel button on the modal itself that returns to the still-
streaming state when feasible.

- **Keep partial**: the partially-streamed assistant message is
  persisted with its accumulated text, marked with a structured
  `endReason: .userStopped` and a `partial: true` flag for UI
  affordance (e.g. the "stopped" indicator). The Conversation
  becomes ready for a follow-up turn.
- **Discard**: the partial message is removed from the Conversation
  before any persistence write commits. From the Conversation's
  point of view the turn never happened; the user's prompt remains
  and can be re-sent or edited.

Network-induced end-of-stream — connection dropped, vendor returned
a non-recoverable error mid-stream, request timed out — produces a
**`.failed` terminal state with no modal**. The partial text, if
any, is persisted as a failed assistant message with
`endReason: .networkFailure` (or the matching `ProviderError` case
per ADR-0023) and is rendered with a failure affordance and a
single-tap Retry that re-issues the original turn. Retry is a fresh
request; we do not attempt to resume a stream.

The branch is decided by **provenance, not by content**: the TCA
effect that drives the stream knows whether it was cancelled by a
user action (`.cancel(id:)` triggered by the Stop reducer action)
or by the underlying transport (an error event on the stream). The
two paths route to different reducer actions and the modal is bound
to the user-action path only.

A user who cancels a turn that has already produced no tokens still
sees the modal; Discard removes the empty assistant message,
producing the same end state as if Stop had been tapped before any
network call. Keep on a zero-token partial persists an empty
`partial: true` message — rare in practice, intentionally not
special-cased because the audit value of "user cancelled before any
tokens" is non-zero.

## Consequences

What gets easier:

- Reading any Conversation, the end state of every turn is
  unambiguous: completed, user-stopped (kept or discarded), or
  failed. The audit log inherits this taxonomy without extra work.
- Retry semantics are simple. Only `.failed` messages get a Retry
  affordance; user-stopped messages do not, because the user
  expressed intent to end the turn.
- Network drops never block the UI on a modal. The user is not
  forced to triage a partial answer at a moment when their attention
  is on connectivity.
- The TCA cancellation idiom maps cleanly to the user branch; the
  transport branch maps cleanly to the error event protocol of
  ADR-0008.

What gets harder:

- Two distinct persistence shapes for "stream ended early"
  (user-stopped-kept vs failed) increase the surface area of any
  feature that walks message history (export, search, summarisation).
  Each consumer must know the taxonomy.
- The modal adds a tap to user-initiated cancellation. We accept
  this as the price of explicitness; the alternative — silent
  discard — punishes the common "answer was already useful" case.
- A user who taps Stop on a flaky network experiences the modal
  even though the underlying cause was connectivity. Provenance is
  decided in-process, not by inspecting the stream, so a near-
  simultaneous user-tap and network-drop resolves to whichever
  reducer action the runloop processes first; we accept the small
  ambiguity.

What we accept:

- Resume-mid-stream is out of scope for v1. Vendors do not offer a
  reliable resume primitive; "Retry" is "re-issue the same prompt".
- The modal text and affordances are localisable and accessibility-
  audited; specific copy is design-driven and not pinned by this
  ADR.
- Empty-partial Keep is not a UX feature, but it is permitted to
  keep the persistence shape uniform.

## Alternatives considered

- **Stop discards silently.** Rejected. Punishes the common case
  where the partial answer is what the user wanted; produces a
  surprising loss of work.
- **Stop keeps silently.** Rejected. Produces stale, half-formed
  answers in Conversation history when the user stopped because the
  answer was wrong.
- **Treat network drops the same as Stop (show modal).** Rejected.
  Conflates intent with failure, blocks the UI on connectivity
  events, and obscures the diagnostic signal that a turn failed
  rather than was abandoned.
- **Single Cancel button without a modal, defaulting to Discard,
  with Undo toast for Keep.** Considered. Rejected because Undo
  toasts are dismiss-on-time and lose state on app backgrounding;
  the modal is more accessible and more deterministic.
- **Resume mid-stream after a drop.** Rejected for v1. Requires
  vendor cooperation we do not have, and a re-issued prompt
  reproduces the answer well enough; the cost-to-value ratio is
  poor.
- **Per-vendor cancellation semantics.** Rejected. The user-facing
  contract must be consistent across vendors; vendor-specific
  behaviour belongs inside the Live implementation, not the
  reducer.
