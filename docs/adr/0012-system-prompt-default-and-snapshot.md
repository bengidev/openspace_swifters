# 0012. System prompt: ProviderConfig default plus Conversation snapshot override

- Status: Accepted
- Date: 2026-05-22

## Context

The system prompt steers the Assistant's persona, tone, and ground
rules. Two competing forces shape where it should live:

- **Per-config default.** The user expects "my coding config" and
  "my casual chat config" to feel different. That difference is
  largely the system prompt. Storing one default per
  `ProviderConfig` (ADR-0009) keeps the surface tidy.
- **Per-conversation override.** The user occasionally needs to nudge
  a single thread — "for this conversation, answer in formal English"
  — without rewriting the config that powers ten other threads.

A third force is reproducibility. ADR-0009 already pins
`providerConfigId` per Conversation and forbids mid-conversation
provider switching. The system prompt has to honour the same posture:
once a Conversation is under way, its system prompt must not silently
change because the underlying config was edited.

## Decision

The system prompt has **two layers** with deterministic precedence:

1. **`ProviderConfig.defaultSystemPrompt`** — a string field on
   the `ProviderConfig` record (ADR-0009). It is the starting value
   used when a new Conversation is created against that config.
2. **`Conversation.systemPromptSnapshot`** — a string field on the
   Conversation record, captured at creation time from the active
   config's default. The snapshot is the value sent to the vendor
   on every turn of that Conversation.

Behaviour:

- Creating a Conversation copies the `ProviderConfig`'s
  `defaultSystemPrompt` into `Conversation.systemPromptSnapshot`.
  The two strings are independent from then on.
- The Conversation snapshot is **immutable mid-conversation**. The
  Assistant UI does not expose an edit affordance once at least one
  user turn has been sent.
- Before the first user turn, the snapshot may still be edited (the
  user is still "setting up" the thread). After the first user turn,
  the snapshot is locked.
- Editing `ProviderConfig.defaultSystemPrompt` later does **not**
  flow into existing Conversations. It only affects future ones.
- An empty `defaultSystemPrompt` is allowed and yields an empty
  snapshot; reducers send no system message in that case rather
  than sending a literal empty string.

Vendor mapping:

- OpenAI-compatible dialect: the snapshot is sent as a leading
  `{"role":"system","content":"…"}` message.
- Anthropic Messages dialect: the snapshot is sent as the
  request-level `system` field (out-of-band of the messages array),
  per Anthropic's API.

## Consequences

What gets easier:

- A Conversation's behaviour is reproducible from its persisted
  state. Replaying the same input produces the same output (up to
  vendor non-determinism) regardless of how `ProviderConfig` drifts
  later.
- The user's mental model is simple: "the config sets the default,
  the conversation captures it once". No surprise prompt swaps.
- Vendor mapping is a per-Live concern; the reducer always sees a
  single string and does not branch on dialect.

What gets harder:

- The "I want to update the system prompt for this thread mid-way"
  instinct is blocked. The cure is the same as for provider
  switching (ADR-0009): clone-as-new-conversation. We should make
  that flow obvious.
- Storing a copy of the system prompt on every Conversation
  duplicates data. We accept the storage cost; system prompts are
  small and the benefit (reproducibility, immutability) outweighs
  bytes saved.

What we accept:

- Migrations that change the *structure* of system prompts (e.g.
  adopting a new template) cannot retroactively rewrite old
  Conversations. They start applying at the next new Conversation.
- A user who wants to evolve a long thread with a new prompt must
  clone. We treat that as the right escape valve, not a missing
  feature.

## Alternatives considered

- **Single layer on `ProviderConfig` only.** Rejected. Edits to a
  shared config silently change the behaviour of every Conversation
  that depends on it, breaking reproducibility.
- **Single layer on `Conversation` only.** Rejected. Forces the
  user to retype or paste the same prompt for every new Conversation
  against a given config. Bad ergonomics.
- **Mutable per-Conversation system prompt.** Rejected. Mid-thread
  system-prompt changes confuse the model and the user; the result
  is non-reproducible. Same posture as ADR-0009 on provider
  switching.
- **Layered prompts with concatenation rules (e.g. base + overlay).**
  Rejected as premature complexity. We can revisit if a real product
  need surfaces; today the "snapshot-on-creation" model is enough.
