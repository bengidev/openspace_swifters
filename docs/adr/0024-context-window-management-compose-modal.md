# 0024. Context window management: compose-time modal Truncate / New Conversation / Cancel; per-vendor tokenizer

- Status: Accepted
- Date: 2026-05-22

## Context

Every vendor exposes a finite context window per model — measured
in tokens, with the exact accounting differing per dialect. A long-
running OpenSpace Conversation can grow past that window, at which
point the next turn either fails on the vendor side
(`.contextLengthExceeded` per ADR-0023) or silently drops earlier
turns inside the vendor's own truncation policy. Either path
surprises the user.

The app needs a forcing function before submission. The forcing
function must answer:

- Where does the check happen — at compose time, at send time, or
  inside the Live Provider?
- How is the token count computed when each vendor counts tokens
  differently?
- What does the user see, and what choices does the user have?
- What is the structural shape of "this Conversation cannot continue
  here" without being a dead end?

A late check inside the Live Provider would surface as a network-
round-trip failure with a useful but post-hoc error. A compile-time
or send-time check on the client side gives the user agency before
the request fires and before any vendor-side billing.

Tokenizer accuracy matters. A heuristic estimator (characters-
divided-by-four) is fast but produces false positives at the limit
boundary, generating modals that the vendor would have accepted.
A per-vendor tokenizer (the published encoder for OpenAI-dialect
models, the Anthropic counter for the Anthropic dialect, a
sensible fallback for OpenRouter-dynamic) is more accurate but
ships more code.

## Decision

The context-window check runs at **compose time**, immediately
before a turn is dispatched. The reducer asks the active
Conversation's resolved configuration (system prompt + history
window + composed turn) for its **token count**, compares it
against the model entry's **`contextWindow`** value (per ADR-0011's
model catalog), and gates submission accordingly.

Token counting is **per-vendor**:

- OpenAI-dialect models use a `tiktoken`-equivalent encoder bundled
  with the app and selected by model family. The encoder runs
  on-device.
- Anthropic-dialect models use Anthropic's documented token-
  counting approach, implemented locally to avoid a pre-flight
  network round trip in v1.
- OpenRouter-routed models inherit the upstream vendor's encoder
  when known (the catalog entry carries a `tokenizerHint` field);
  unknown upstreams fall back to a documented heuristic with a
  conservative safety margin (the catalog entry can pin the margin
  per model).

The tokenizer surface is a `TokenizerClient` triplet in `Shared/`,
with `Interface`/`Live`/`Test` per the project's standard split.
Live implementations are deterministic and Sendable (ADR-0022).

UX at compose time. When the projected token count plus a small
reserved-output margin exceeds the model's `contextWindow`, the
compose action presents a **modal with three options**:

- **Truncate** — drop the oldest user/assistant turn pairs from the
  Conversation's history-in-effect for this submission until the
  projected count fits, then send. The truncated turns are not
  deleted from persistence; they remain in the Conversation history
  and can be browsed in the scroll-back. Subsequent turns again
  reconsider truncation against the new projected size.
- **New Conversation** — start a fresh Conversation, optionally
  pre-filled with the composed turn (the modal preserves the user's
  draft). The current Conversation is left intact.
- **Cancel** — return to compose without sending. The user can
  edit the draft, switch to a model with a larger `contextWindow`,
  or delete attachments.

The modal's "Truncate" path is **not silent**: a per-turn audit
note records the truncated range so the persisted Conversation can
explain to a returning user why the assistant's later replies do
not reference earlier text.

The send-time check is **conservative**: the reserved-output margin
defaults to a small fixed value (e.g. 512 tokens) and can be raised
per model entry when the curated catalog knows the model needs
more headroom. This avoids a class of failures where the request
fits but leaves no room for the response.

## Consequences

What gets easier:

- The user is never surprised by a vendor-side context-length
  rejection on a normal turn. The forcing function is local,
  predictable, and pre-billing.
- The UX vocabulary around context — Truncate vs New — is a single
  modal with two paths plus Cancel; no separate flows for
  "shorten" vs "branch".
- Per-vendor tokenizers keep the false-positive rate low at the
  limit boundary; the modal fires when it really matters.
- The Conversation's truncation history is preserved on disk; users
  who want to recover earlier context can branch into a New
  Conversation seeded from a specific message later.

What gets harder:

- The app ships tokenizer code and per-model encoder data. Binary
  size grows; the curated catalog must include encoder hints per
  model entry.
- Anthropic's token counting is a moving target relative to
  OpenAI's; the Anthropic-dialect counter must be reviewed when the
  vendor publishes updates. We accept the maintenance cost in
  exchange for offline accuracy.
- OpenRouter-dynamic entries with unknown upstream tokenizers fall
  back to a heuristic. The heuristic is conservative and can fire
  the modal earlier than necessary; we accept this over the
  alternative of letting the vendor reject the request.
- Truncate-then-send produces a Conversation whose visible scroll-
  back includes turns the model did not see when generating the
  most recent reply. The audit note explains this; we accept the
  cognitive load.

What we accept:

- Reserved-output margin is a knob, not a guarantee. A reply that
  blows past the margin is still possible and still surfaces as
  a vendor-side failure handled by ADR-0023.
- Pre-flight network token-count APIs (where vendors offer them)
  are out of scope for v1. On-device counting keeps the compose
  step instantaneous.
- The modal is shown synchronously at compose time. Users typing
  past the limit see the gating only on send; we do not paint a
  live "tokens used" gauge in v1 (revisitable).

## Alternatives considered

- **No client-side check; rely on vendor errors.** Rejected. The
  failure happens after the network round-trip, post-billing, and
  trains users to retry into the same wall.
- **Heuristic-only token counting (chars/4).** Rejected. Too many
  false positives at the boundary; the modal cries wolf and users
  learn to dismiss it.
- **Single "Truncate" button, silent.** Rejected. Loss of context
  must be explicit; users frequently choose New Conversation when
  the prompt deserves a clean slate.
- **Auto-summarise history when over the limit.** Rejected for
  v1. Summarisation is itself a turn, costs tokens, and changes
  the Conversation's semantics in a way the user did not request.
  Belongs in a deliberate later ADR.
- **Branch the Conversation in place (forking).** Rejected for
  v1. The data model and UX of branches is a large feature; "New
  Conversation" preserves the v1 single-thread invariant and
  ships the same recovery path.
- **Server-side token count via a vendor pre-flight.** Rejected.
  Adds latency to compose; not consistently available across
  vendors; on-device is good enough with curated catalog hints.
- **Single-vendor tokenizer for all models.** Rejected. Cross-
  vendor inaccuracy is unbounded — Anthropic and OpenAI tokenize
  the same input to materially different counts on long inputs.
