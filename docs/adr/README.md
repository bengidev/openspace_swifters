# Architectural Decision Records

This directory holds the Architectural Decision Records (ADRs) for
OpenSpace. ADRs document the *why* behind a non-obvious technical
choice so that a future contributor — human or AI coding agent — can
either uphold the decision, revisit it with full context, or replace it
with a record that supersedes it.

We use the format introduced by Michael Nygard, kept lightweight.

## Format

Every ADR is a single Markdown file named `NNNN-short-slug.md`, where
`NNNN` is the next monotonic number (`0001`, `0002`, …). Each ADR has
the following sections, in order:

1. **Header.** Title (`# NNNN. Short title`), Status, Date.
2. **Context.** What forces, constraints, or unknowns are at play.
3. **Decision.** The position taken, written in active voice.
4. **Consequences.** What gets easier, what gets harder, what we accept.
5. **Alternatives considered.** What else was on the table and why those
   were not chosen.

A template is available at
[`/Users/beng/.hermes/skills/software-development/bootstrap-repo-docs/templates/adr.md`][template]
for agents that want a starting structure.

[template]: https://example.invalid/

### Status values

- **Proposed.** Drafted; not yet adopted. Open to objection.
- **Accepted.** Adopted; the codebase is expected to honour it.
- **Deprecated.** Still applicable to existing code, but no longer the
  recommended path for new code.
- **Superseded by ADR-NNNN.** Replaced by a later record.

## Where ADRs live

- **System-wide decisions** (e.g. choice of state-management library,
  minimum deployment target, persistence stack) live in this directory.
- **Feature-scoped decisions** live at
  `OpenSpace/OpenSpace/Features/<Feature>/docs/adr/`.
- **Cross-cutting Client decisions** live at
  `OpenSpace/OpenSpace/Shared/docs/adr/`.

This split mirrors the multi-context layout described in
[`CONTEXT-MAP.md`](../../CONTEXT-MAP.md) and consumed by
[`docs/agents/domain.md`](../agents/domain.md).

## When to write an ADR

Write one when the decision:

- Is not obvious from reading the code.
- Has at least one credible alternative.
- Will be costly to reverse later.
- Touches an area future contributors will need to extend.

Skip the ADR when the decision is purely tactical, easy to change, or
follows directly from an already-recorded decision.

## When to update an ADR

Do not edit the body of an Accepted ADR to reflect a different decision.
Write a new ADR with `Status: Accepted` and a `Supersedes ADR-NNNN`
line; flip the older ADR's status to `Superseded by ADR-MMMM`.

Editorial corrections (typos, broken links, clarifying a sentence
without changing meaning) are fine.

## Index

| #    | Title                                                             | Status   |
| ---- | ----------------------------------------------------------------- | -------- |
| 0001 | [Record architectural decisions](0001-record-architectural-decisions.md) | Accepted |
| 0002 | [Adopt the Composable Architecture for state management](0002-composable-architecture-for-state-management.md) | Accepted |
| 0003 | [Use SwiftData for on-device persistence](0003-swiftdata-for-on-device-persistence.md) | Accepted |
| 0004 | [Target iOS 17.6 as the minimum deployment](0004-ios-17-6-minimum-deployment.md) | Accepted |
| 0005 | [Use Swift Testing as the unit-testing framework](0005-swift-testing-as-unit-testing-framework.md) | Accepted |
| 0006 | [Provider abstraction shape: one Client surface, N Live per vendor](0006-provider-abstraction-shape.md) | Accepted |
| 0007 | [Vendor scope v1: OpenRouter, OpenAI BYOK, Anthropic BYOK; two dialects](0007-vendor-scope-v1.md) | Accepted |
| 0008 | [Streaming protocol: event-shaped enum with reserved tool-call cases](0008-streaming-protocol.md) | Accepted |
| 0009 | [Provider configuration: multi-config; pin per Conversation; no mid-conversation switching](0009-provider-configuration-multi-config.md) | Accepted |
| 0010 | [Credentials: one Keychain entry per ProviderConfig UUID; cascade delete](0010-credentials-keychain-per-config.md) | Accepted |
| 0011 | [Model catalog: 3-tier (dynamic /models, curated fallback, free-form override)](0011-model-catalog-three-tier.md) | Accepted |
| 0012 | [System prompt: ProviderConfig default plus Conversation snapshot override](0012-system-prompt-default-and-snapshot.md) | Accepted |
| 0013 | [Inference parameters: common subset at ProviderConfig only](0013-inference-parameters-common-subset.md) | Accepted |
| 0014 | [Multimodal v1 scope: text, image, PDF, audio with vendor-asymmetric capabilities](0014-multimodal-v1-scope.md) | Accepted |
| 0015 | [Attachment storage: SwiftData external storage with SHA-256 hash field](0015-attachment-storage-external-with-hash.md) | Accepted |
| 0016 | [Attachment encoding: per-vendor normalisation with PDFKit text extraction for OpenAI](0016-attachment-encoding-rules.md) | Accepted |
| 0017 | [Persistence schema v1: 7 entities under VersionedSchema with orphan-snapshot ProviderConfig deletion](0017-persistence-schema-v1.md) | Accepted |
| 0018 | [Tool-calling protocol v1: reserve event types only, no domain tool surface](0018-tool-calling-protocol-v1.md) | Accepted |
| 0019 | [Onboarding: welcome-only with OnboardingProgressEntity gate](0019-onboarding-welcome-only-with-progress-gate.md) | Accepted |
| 0020 | [Settings module: monolithic Container with nested Flow reducers](0020-settings-module-monolithic-container-flow.md) | Accepted |
| 0021 | [Cancellation semantics: Stop modal Keep/Discard; network drop equals .failed](0021-cancellation-semantics-stop-modal-network-failed.md) | Accepted |
| 0022 | [Concurrency posture: Swift 6 language mode with complete strict concurrency](0022-concurrency-posture-swift-6-strict.md) | Accepted |
| 0023 | [Errors: flat ProviderError enum, no auto retry, inline plus modal alert for critical](0023-errors-flat-provider-error-no-auto-retry.md) | Accepted |
| 0024 | [Context window management: compose-time modal Truncate / New Conversation / Cancel; per-vendor tokenizer](0024-context-window-management-compose-modal.md) | Accepted |
| 0025 | [Conversation list: search plus pin (max 5) plus archive plus folder plus tag (max 10); compound AND filter](0025-conversation-list-search-pin-archive-folder-tag.md) | Accepted |
