# 0022. Concurrency posture: Swift 6 language mode with complete strict concurrency

- Status: Accepted
- Date: 2026-05-22

## Context

OpenSpace runs streaming network work, persistence writes, Keychain
access, attachment encoding, and tokenizer math concurrently with a
SwiftUI/TCA UI on a single-process iOS app. The Swift toolchain has
matured through three concurrency postures in recent releases:
the pre-Swift-6 minimal mode (warnings only), the targeted-strict
mode (warnings escalated to errors per opt-in), and the Swift 6
language mode with complete strict-concurrency checking.

The decision affects every file in the app and every Client triplet
in `Shared/`. It also bounds what we can do with vendor SDKs and
system frameworks: AVFoundation (audio capture and conversion),
PDFKit (PDF text extraction per ADR-0016), and parts of UIKit
(legacy interop) ship with Sendable annotations that are partial,
inconsistent, or missing. Choosing strict concurrency means
choosing how to live with those gaps without rewriting the world.

A weaker posture (minimal or targeted) ships faster but pushes data-
race risk into the runtime, where it surfaces as flaky tests,
streaming corruption, or persistence write conflicts that are
expensive to diagnose. A stricter posture pays the cost in compiler
errors at module boundaries and ergonomic friction at framework
boundaries, but pays it once, at compile time.

## Decision

OpenSpace adopts **Swift 6 language mode with complete strict
concurrency checking** project-wide. Every Swift module — app,
features, Shared Clients, tests — sets:

- `SWIFT_VERSION = 6` (or the Package.swift `swiftLanguageModes:
  [.v6]` equivalent for any local SwiftPM-managed module).
- `SWIFT_STRICT_CONCURRENCY = complete` at the project level, with
  no per-target downgrades.

Sendable conformance is required for every type that crosses a
concurrency boundary. Reducers, State, and Action types in TCA
modules are `Sendable` by construction. Client interfaces in
`Shared/` declare `Sendable` requirements on their closures
explicitly; Live implementations are responsible for respecting
isolation domains they touch.

Where system frameworks block the strictness — AVFoundation
audio session and conversion APIs, PDFKit document handles,
specific UIKit hooks used during attachment ingestion — we use
`@preconcurrency import` **pragmatically and locally**:

- The `@preconcurrency` import is applied at the narrowest possible
  scope (a single file or a small wrapper type), not at module
  granularity.
- Each use is paired with a brief comment explaining the gap and
  the upgrade trigger ("remove when AVFoundation ships full
  Sendable annotations on `AVAudioConverter`").
- A wrapper type in the relevant Live implementation re-presents
  the framework surface with Sendable-correct types so callers
  outside the wrapper never see the `@preconcurrency` escape
  hatch.

Vendor SDKs are avoided in v1 in favour of `URLSession`-based
implementations (consistent with ADR-0006); this sidesteps most
SDK-driven concurrency gaps. If a future ADR introduces a vendor
SDK, the same pragmatic-`@preconcurrency` rule applies.

Actor adoption is deliberate: the persistence and Keychain Clients
expose actor-isolated APIs only when they own mutable state that
must be serialised; otherwise their Live implementations rely on
value-type Sendable contracts. We do not introduce a project-wide
"DataActor" or similar global actor in v1.

## Consequences

What gets easier:

- Data races that would previously surface as runtime flakes are
  caught at compile time. Streaming, persistence, and Keychain
  paths cannot accidentally share non-Sendable mutable state.
- Reasoning about reducers and effects is local: TCA's
  `Sendable`-by-construction shape is enforced rather than
  encouraged.
- Future toolchain upgrades land cleanly; we are not carrying a
  compatibility tail.
- Reviewers have an objective standard for concurrency questions —
  "does it compile under complete strict concurrency?" — rather
  than judgement calls.

What gets harder:

- Initial compilation against system frameworks produces noise.
  Each `@preconcurrency import` is a small piece of debt with a
  named upgrade trigger.
- New contributors hit Sendable-conformance errors that require
  understanding of isolation domains; the project's onboarding
  documentation must cover this explicitly.
- Some convenient idioms (capturing a class instance in a `Task`,
  passing a non-Sendable struct across a boundary) become compile
  errors. Refactoring effort up-front is non-trivial.
- Test fixtures must be Sendable too; mock objects that previously
  used unchecked references need explicit conformance or
  redesigned shape.

What we accept:

- A handful of wrapper types in `Shared/` exist primarily to
  isolate framework concurrency gaps. Their value is the boundary
  they enforce, not the behaviour they add.
- We carry compile-time strictness in exchange for runtime
  determinism. The trade-off is appropriate for a streaming,
  persistence-heavy app where races are expensive to diagnose.
- `@preconcurrency` is a tool, not a smell. Used at the narrowest
  scope with a comment, it is the documented escape hatch.

## Alternatives considered

- **Minimal concurrency checking (Swift 5 mode).** Rejected. Pushes
  race risk into the runtime; the streaming and persistence paths
  are exactly where this hurts most.
- **Targeted strict concurrency (per-module opt-in).** Rejected.
  Produces an inconsistent baseline where new code is checked
  strictly while legacy modules are not, and complicates the
  upgrade story when the project later moves to complete.
- **Swift 6 strict concurrency without `@preconcurrency` escape
  hatches.** Rejected. Would require either avoiding the affected
  system frameworks (impossible — AVFoundation and PDFKit are
  mandatory for ADR-0016) or vendoring our own; both are out of
  proportion to the problem.
- **Project-wide `@preconcurrency` import.** Rejected. Hides the
  gap rather than naming it; loses the upgrade trigger; encourages
  drift back into unchecked territory.
- **Custom global actor for "all data".** Rejected. Funnels
  unrelated state through a single isolation domain, recreating
  the very serialisation bottleneck that strict concurrency is
  meant to make explicit. Actor adoption is per-Client, not
  global.
