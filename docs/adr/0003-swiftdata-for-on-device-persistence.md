# 0003. Use SwiftData for on-device persistence

- Status: Accepted
- Date: 2026-05-21

## Context

OpenSpace is local-first. The Assistant's Conversations, the user's
Capability consent state, and progress entities such as
`OnboardingProgressEntity` must persist across launches on device. We
need a persistence layer that:

- Integrates cleanly with SwiftUI and our chosen state-management
  library (see ADR-0002).
- Models entities idiomatically in Swift without a heavy mapping layer.
- Supports schema migrations as the data model evolves.
- Can be tested without a full app host, ideally with an in-memory
  store.
- Is stable on the deployment target (see ADR-0004).

Available options on iOS for an app at this stage:

- **Core Data.** Mature, battle-tested, but verbose and Objective-C
  flavoured. Ergonomics with SwiftUI improved with `@FetchRequest` but
  modelling, migrations, and concurrency remain heavy ceremony.
- **SwiftData.** Apple's modern persistence framework, layered on top
  of Core Data primitives, exposing an idiomatic Swift macro-based API
  that integrates with SwiftUI through `@Model`, `@Query`, and
  `ModelContainer`. Available on iOS 17 and above.
- **A SQL wrapper.** Hand-rolled or via a library. Maximum control but
  shifts modelling, migrations, and concurrency safety onto us.
- **A document-store / file-based approach.** Simple but loses
  query, indexing, and migration tooling.

## Decision

We use **SwiftData** as the on-device persistence layer for OpenSpace.

Concretely:

- A single `ModelContainer` is constructed at the App composition root
  and injected into TCA reducers through a `Storage` Client.
- Persistent entities (e.g. `OnboardingProgressEntity`, Conversation
  records) are declared with the `@Model` macro and live in the
  Infrastructure layer of their owning feature.
- Reducers do not import SwiftData directly; they go through the
  Storage Client interface, which exposes domain-shaped operations
  (`save(_:)`, `load(_:)`, etc.).
- Schema migrations are recorded in their own ADRs as they happen.

Tests inject a Storage Client backed by an in-memory `ModelContainer`
or a Test implementation that uses dictionaries.

## Consequences

What gets easier:

- Modelling persistent data is concise: `@Model` types read like
  domain types, not ORM rows.
- The container/context lifecycle plays well with SwiftUI and TCA via
  dependency injection, so the rest of the app does not see SwiftData
  types.
- Migrations have a documented framework path; we will lean on it
  rather than hand-roll.
- Tests can run against an in-memory store without a host app.

What gets harder:

- SwiftData is younger than Core Data; some edge cases (complex
  predicates, performance under high-volume writes, certain CloudKit
  scenarios) are still maturing. We will track issues as they appear
  and may write a focused ADR if a workaround becomes load-bearing.
- Tying persistence to iOS 17+ APIs reinforces the deployment-target
  decision in ADR-0004; backporting to older OS versions is not on the
  table.

What we accept:

- We sacrifice some Core Data flexibility (custom NSManagedObject
  subclasses, fine-grained context control) in exchange for ergonomics
  and integration with the rest of the stack.
- If a future need (e.g. on-device sync against an arbitrary backend,
  full-text search at scale) outgrows SwiftData, we will write an ADR
  to record the migration path rather than silently swap layers.

## Alternatives considered

- **Core Data directly.** Rejected on ergonomics. The modelling and
  context ceremony is significant for a single-developer / small-team
  product where every line counts.
- **SQL wrapper.** Rejected because we would re-build modelling,
  migrations, and concurrency safety. Reasonable for products with
  unusual access patterns; not justified here.
- **Files-on-disk.** Rejected because Conversations need indexed
  access, ordering, and pagination; rolling those over a file system
  is a poor trade.
