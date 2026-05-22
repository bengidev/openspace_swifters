# 0009. Provider configuration: multi-config; pin per Conversation; no mid-conversation switching

- Status: Accepted
- Date: 2026-05-22

## Context

A user might have several distinct Provider configurations active at
the same time:

- A free OpenRouter config for casual chat.
- An OpenAI direct config tuned for code generation, with a higher
  `maxTokens`.
- An Anthropic direct config used to compare model behaviour.

Each config bundles a vendor (ADR-0007), credentials (ADR-0010), a
default model and inference parameters (ADR-0013), and a default
system prompt (ADR-0012). These bundles are durable, named, user-
visible records — not implicit settings.

A separate question is what happens *during* a Conversation. Mid-
conversation provider switching sounds attractive (compare answers
mid-thread) but is hostile to the model: changing system prompts,
tokenisers, or context windows partway through a thread produces
results that are hard for the user to interpret and impossible to
reproduce.

## Decision

Provider configuration is a **multi-config** model:

- The user can create, edit, and delete an arbitrary number of named
  `ProviderConfig` records. Each has a stable UUID.
- A `ProviderConfig` carries: a user-facing name, a vendor identifier
  (ADR-0007), the model id, the inference parameters
  (`temperature`, `maxTokens`, `topP`; ADR-0013), and the default
  system prompt (ADR-0012).
- Credentials are not stored on the `ProviderConfig` directly; they
  live in the Keychain keyed by the config's UUID (ADR-0010).
- Exactly one `ProviderConfig` is the user's *current default* at any
  time. New Conversations are created against that default.

Each Conversation **pins** the `providerConfigId` it was created with.
That pin is persisted and immutable for the life of the Conversation:

- The Composition Root resolves the Live Provider for a Conversation
  by looking up its pinned `providerConfigId`, not the current
  default.
- The system-prompt snapshot stored on the Conversation (ADR-0012) is
  taken from that pinned config at creation time.
- Mid-conversation provider switching is **not supported**. The
  Assistant UI offers "start new conversation with…" instead.

If the pinned `ProviderConfig` is deleted, the Conversation enters a
read-only "stale config" state: it can be displayed and exported, but
no further turns can be sent. The user is invited to clone the
Conversation onto a different config to continue.

## Consequences

What gets easier:

- A Conversation is fully reproducible from its pinned config plus
  its message history. Two reads of the same Conversation behave
  the same.
- Dependency wiring is straightforward: the reducer reads
  `providerConfigId` from Conversation state, the Composition Root
  resolves the Live Provider once, and the rest of the effect runs
  with stable context.
- The user can compare vendors by running two Conversations side by
  side; each is internally consistent.

What gets harder:

- The "I want the same thread but a different model" instinct is
  blocked. The cure is the clone-as-new-conversation flow, which
  some users will find heavy.
- Migration: when a `ProviderConfig`'s default model is changed,
  existing pinned Conversations keep using the old model id (which
  is what we want for reproducibility) — but only because the
  *Conversation* pins the resolved fields it needs, not because the
  config silently snapshots them. We therefore snapshot the system
  prompt at creation (ADR-0012) and read the model id from the
  current `ProviderConfig` only if it has not changed; if it has,
  the Conversation uses the pinned `modelId` it captured at start.

What we accept:

- Stale-config Conversations are a UX surface that has to be
  designed (read-only banner, clone affordance). The cost is
  acceptable in exchange for the correctness guarantee.
- The pin model is more conservative than competitor offerings that
  allow mid-thread switching. We treat that as a feature, not a
  limitation, for the local-first / reproducible posture.

## Alternatives considered

- **Single global ProviderConfig.** Rejected. Forces a destructive
  edit every time the user wants to try a different vendor or model
  and erases prior context.
- **Per-message provider override.** Rejected. Encourages
  Frankenthread Conversations whose results are impossible to
  reason about; doubles the test matrix.
- **Pin only the credentials, resolve everything else live.**
  Rejected. The user expects a Conversation to keep behaving the
  same; live-resolving model id and system prompt would silently
  change behaviour when the underlying config drifts.
- **Snapshot the entire ProviderConfig onto the Conversation at
  creation.** Rejected. Duplicates data that should remain editable
  in one place; conflicts with the Keychain credential model where
  there is exactly one entry per config UUID.
