# 0013. Inference parameters: common subset at ProviderConfig only

- Status: Accepted
- Date: 2026-05-22

## Context

Vendors expose long, divergent lists of inference parameters: top-k,
top-p, frequency penalty, presence penalty, repetition penalty, seed,
logit bias, stop sequences, response format, reasoning effort, and
more. Each vendor names them slightly differently and gates some of
them on specific models.

OpenSpace must decide:

- **Which parameters** to surface to the user.
- **Where** to persist them — on the `ProviderConfig` (ADR-0009),
  on the Conversation, or per request.
- **How** to map the chosen subset to each vendor's wire format
  (ADR-0006, ADR-0007).

Surfacing every parameter on every screen punishes the median user.
Hiding everything strips power users of control. Persisting at the
wrong level defeats the reproducibility posture of ADR-0009 and
ADR-0012.

## Decision

The inference-parameter surface in v1 is the **common subset of
three fields**:

- `temperature: Double` — typical range `0.0 ... 2.0`, default per
  curated model entry or `1.0` if unknown.
- `maxTokens: Int?` — optional cap on output tokens; `nil` means
  "vendor default".
- `topP: Double?` — optional nucleus sampling parameter,
  typical range `0.0 ... 1.0`; `nil` means "vendor default".

These three fields live on the **`ProviderConfig` only**. They are
not duplicated on Conversation, Message, or Turn. There is no per-
turn override UI in v1.

Vendor mapping:

- OpenAI-compatible dialect: passed through as `temperature`,
  `max_tokens`, `top_p`. `nil` values are omitted from the request.
- Anthropic Messages dialect: passed through as `temperature`,
  `max_tokens` (required by Anthropic — when our value is `nil` we
  send a vendor-appropriate default documented in the Live
  implementation), `top_p`. `nil` for `top_p` is omitted.

Range handling at the edge:

- The Live implementations clamp into vendor-supported ranges and
  report any clamping via a structured warning event on the stream
  (no silent rewrites; the user sees a one-line note that the value
  was adjusted).
- Validation at the UI layer rejects obviously-out-of-range values
  (e.g. negative `maxTokens`); the Client triplet treats inputs as
  trusted-by-construction.

Reproducibility at Conversation level:

- A Conversation's behaviour depends on the parameters in effect at
  request time. To preserve the reproducibility posture of ADR-0009
  and ADR-0012, the Live Provider snapshots the resolved parameter
  triple onto the request-level audit log of the message it sends.
  Editing a `ProviderConfig`'s parameters changes future turns of
  existing Conversations — we accept this for parameters (unlike
  the system prompt) because parameters are quantitative knobs the
  user expects to tweak live; the audit log preserves the per-turn
  values for diagnostics.

## Consequences

What gets easier:

- The settings surface stays small: three fields, one place. New
  contributors and AI agents do not have to reason about
  parameter-vs-Conversation precedence.
- The vendor mapping is short. Adding a vendor requires implementing
  three field translations, plus the dialect-specific defaults for
  required-but-nilable fields.
- Tests for the Live Providers fixtureise three values rather than
  the cross product of a long parameter list.

What gets harder:

- Power users who want top-k, frequency/presence penalty, seeds, or
  stop sequences are not served in v1. We will add them in a
  deliberate later ADR rather than ad-hoc field-by-field.
- Editing parameters affects existing Conversations — the
  parameter-side trade-off mirroring ADR-0012's snapshot decision
  for system prompts. The audit log mitigates the diagnostic
  consequences but not the user-visible behaviour change.

What we accept:

- The chosen subset is the smallest one that materially affects
  output quality across the v1 vendors. Anything else is deferred.
- The asymmetry with ADR-0012 (parameters live; system prompt
  snapshotted) is intentional. System prompts encode persona and
  ground rules whose mid-conversation drift confuses both model and
  user; numeric parameters are knobs whose drift is bounded and
  observable.

## Alternatives considered

- **Surface every vendor parameter.** Rejected. Bloats the UI,
  multiplies tests, and produces a settings screen that few users
  can reason about.
- **Per-Conversation override of parameters.** Rejected for v1.
  Doubles the precedence rules and the test matrix without a
  proven product need. Revisitable if user feedback demands it.
- **Per-turn override (slider in chat composer).** Rejected for
  v1. Same objection plus an interaction-design problem (where in
  the composer does it live, when does it persist, when does it
  reset). Out of scope for the foundation phase.
- **Vendor-specific parameter dictionaries with `[String: Any]` on
  the config.** Rejected. Trades type safety for an open-ended
  surface that still has to be validated and mapped per vendor;
  the savings are illusory.
- **Snapshot parameters onto the Conversation at creation time.**
  Considered seriously; rejected because users expect quantitative
  knobs to be live-editable in a way they do not expect for
  persona-defining system prompts. The audit log preserves the
  history without freezing the controls.
