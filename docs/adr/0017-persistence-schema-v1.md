# 0017. Persistence schema v1: 7 entities under VersionedSchema with orphan-snapshot ProviderConfig deletion

- Status: Accepted
- Date: 2026-05-22

## Context

ADR-0003 commits OpenSpace to SwiftData. The Phase 0 ADR cluster
introduces durable user-facing data: ProviderConfigs (ADR-0009),
Conversations with pinned config and snapshotted system prompts
(ADR-0009, ADR-0012), inference parameters in the audit trail
(ADR-0013), and now multimodal Conversations with hashed attachments
(ADR-0014, ADR-0015, ADR-0016). The schema must be defined once,
written down, and evolved deliberately rather than by drift.

Three concerns shape the schema posture:

- **Migration discipline.** SwiftData supports `VersionedSchema` plus
  `SchemaMigrationPlan` for additive and lightweight migrations from
  day one. Skipping the version wrapper now makes the first migration
  a structural rewrite. Adopting it now costs a small amount of
  ceremony and removes a future cliff.
- **Reproducibility versus user agency.** A user who deletes a
  ProviderConfig (ADR-0009) reasonably expects the credentials to go
  (ADR-0010 cascade-deletes the Keychain entry). They do *not*
  reasonably expect the Conversations they had with that config to
  disappear. ADR-0012's snapshot decision already preserves the
  system prompt. We need a story for the rest of the Conversation.
- **Audit chain integrity.** ADR-0013 requires per-turn audit of the
  inference parameters in effect; ADR-0015 requires post-encode
  attachment hashes in the same audit. Both belong on a per-turn
  entity, not per-Conversation, so we can answer "what exactly did
  the model see for turn N?" without reconstructing.

## Decision

The v1 persistence schema is a **`VersionedSchema` named
`OpenSpaceSchemaV1`** containing seven entities. The schema is
registered with the `ModelContainer` at the composition root, behind
a `SchemaMigrationPlan` whose only stage is `OpenSpaceSchemaV1`.
Future schemas (`V2`, `V3`, …) will plug into the same plan with
explicit migration stages.

### Entities

1. **`ProviderConfigEntity`** — vendor identifier (ADR-0007), model
   id, inference parameters (`temperature`, `maxTokens`, `topP`;
   ADR-0013), default system prompt (ADR-0012), user-facing name,
   stable UUID. Credentials live in the Keychain by UUID (ADR-0010);
   the entity carries no key material.
2. **`ConversationEntity`** — id, title, createdAt, updatedAt,
   `pinnedProviderConfigId: UUID` (ADR-0009),
   `systemPromptSnapshot: String` (ADR-0012),
   `pinnedConfigOrphaned: Bool` (see deletion semantics below).
3. **`MessageEntity`** — id, conversationId, role
   (`user | assistant | system`), createdAt, ordering index, plus the
   text body. Streaming assembly writes deltas into a transient
   buffer; only completed messages persist (with a `truncated: Bool`
   flag on cancellation or error).
4. **`MessageAttachmentEntity`** — id, messageId, kind, mimeType,
   byteCount, sha256, createdAt, sourceMimeType?, sourceByteCount?,
   sourceSha256?, and `@Attribute(.externalStorage) data` (ADR-0015,
   ADR-0016).
5. **`TurnAuditEntity`** — id, conversationId, messageId of the
   assistant message, requestSentAt, responseFinishedAt,
   `parameters: ParametersSnapshot` (the resolved
   `(temperature, maxTokens?, topP?)` triple from ADR-0013),
   `systemPromptHash: String` (sha256 of the snapshot used),
   `attachmentHashes: [String]` (post-encode sha256 list, in
   submit order), and `stopReason: StopReason` (ADR-0008).
6. **`ModelCatalogSnapshotEntity`** — id, vendor, fetchedAt,
   `payload: Data` (the curated-or-dynamic catalog at fetch time;
   ADR-0011), and a `capabilitiesPayload: Data` carrying the
   per-model multimodal capability table that drives ADR-0014's
   compose-time gate.
7. **`OnboardingProgressEntity`** — already established as the
   gating record for first-run flows. v1 schema documents it here
   for completeness; its fields are unchanged from the existing
   implementation.

`ParametersSnapshot` is a `Codable` value type stored as `Data` (or
SwiftData transformable, depending on the implementation slice). It
is not a separate `@Model` because turn-audit rows are append-only
and the snapshot has no independent identity.

### Identity, indexing, and ordering

- All `id` fields are `UUID` with `@Attribute(.unique)`.
- `MessageEntity` carries an explicit `orderingIndex: Int64` per
  conversation; we do not rely on createdAt alone for ordering.
- `TurnAuditEntity.messageId` is unique; one audit row per assistant
  message.

### ProviderConfig deletion: orphan-snapshot read-only

When the user deletes a `ProviderConfigEntity`:

- The Keychain entry for that UUID is removed (ADR-0010 cascade).
- Conversations whose `pinnedProviderConfigId` equals the deleted
  UUID **are not deleted**. Instead:
    - The Composition Root resolves their pinned config from a
      synthesised "orphan snapshot" view backed by the
      `systemPromptSnapshot` already stored on the Conversation, the
      vendor identity recoverable from the latest `TurnAuditEntity`,
      and the model id recoverable from the same.
    - The Conversation flips `pinnedConfigOrphaned = true`.
    - The Conversation becomes **read-only**: existing turns remain
      readable; new turns are blocked at the composer with a clear
      one-line message ("This conversation's provider was deleted —
      duplicate it to a new provider to continue").
- The user can duplicate an orphaned Conversation onto an existing
  ProviderConfig; that creates a fresh ConversationEntity with a new
  pinned config and a fresh system-prompt snapshot taken from the
  new config. The history is copied; the audit chain restarts from
  the new turn.
- We do not auto-recover orphaned Conversations onto the current
  default config. The user picks deliberately.

### Migrations

- `OpenSpaceSchemaV1` is the only registered version at v1. The
  `SchemaMigrationPlan` is a single-stage plan today.
- Future schema changes register a `V2` and a migration stage that
  describes the shape change. Lightweight migrations (additive
  fields, default values) use SwiftData's lightweight path;
  structural changes get a custom stage.
- Every schema change ships with an ADR. The ADR records the new
  version, the migration stage type, and any data backfill required.

## Consequences

What gets easier:

- The schema is one place. Reducers, Live Providers, and tests all
  reference the same `OpenSpaceSchemaV1` entities. There is no
  question about "where does the audit live" or "where do
  attachments hang".
- Migrations have a defined home from day one. Adding a field is a
  V2 stage, not a panic.
- The orphan-snapshot rule preserves user-facing data. Deleting a
  ProviderConfig is no longer a foot-gun — the Conversations stay,
  just frozen.
- The audit trail is queryable per-turn, which makes diagnostics
  ("why did this turn behave differently?") tractable.

What gets harder:

- Seven entities is more than one. New contributors learn the
  surface; the upside is that the surface is small enough to fit on
  a page and is documented here.
- The orphan-snapshot path introduces a "read-only conversation"
  state that the UI must render distinctly. We accept the
  composer-level work in exchange for not destroying user data.
- `TurnAuditEntity.attachmentHashes` and
  `MessageAttachmentEntity.sha256` are coupled. A schema change in
  one will likely touch the other; the coupling is intentional and
  flagged by their being in the same versioned schema file.

What we accept:

- The audit table grows monotonically. We do not prune. A future
  ADR can introduce a retention window if growth becomes
  problematic; v1 is honest about keeping everything.
- Catalog snapshots (entity 6) duplicate per vendor over time. The
  curated path in ADR-0011 gives us a fallback when no snapshot
  exists; the snapshots are caches, not sources of truth, and a
  retention policy can land later.

## Alternatives considered

- **No `VersionedSchema` until the first migration.** Rejected. The
  first migration becomes a structural rewrite under time pressure;
  the discipline is cheap to adopt now and expensive to retrofit.
- **Cascade-delete Conversations when a ProviderConfig is deleted.**
  Rejected. The user's mental model of "I deleted the provider, not
  the chats" is correct; honour it. Cascade-delete on a credential
  delete is a destructive surprise.
- **Auto-rebind orphaned Conversations to the current default
  config.** Rejected. Silently changes the model, parameters, and
  potentially the system prompt of an existing thread. The user must
  pick. Read-only plus duplicate-onto is the explicit alternative.
- **Inline audit fields on `MessageEntity` instead of a separate
  `TurnAuditEntity`.** Rejected. The audit is per-assistant-message
  and has different read patterns (rare, diagnostic) from messages
  (frequent, ordered). Splitting keeps the message row small and
  the audit table append-only.
- **Single `BlobEntity` shared across attachments and catalog
  snapshots.** Rejected. The lifecycles, deduplication rules, and
  query patterns are different. One generic blob bag obscures both.
- **Use `String` for `id` fields to admit deterministic test ids.**
  Rejected. `UUID` plus an injected ID generator (in tests) is the
  pattern already established for the `Storage` Client (ADR-0003);
  staying consistent matters more than per-entity convenience.
