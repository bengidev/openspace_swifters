# 0002. Adopt the Composable Architecture for state management

- Status: Accepted
- Date: 2026-05-21

## Context

OpenSpace is a feature-rich SwiftUI app with non-trivial state — chat
streaming, multi-step flows, persisted progress, side effects against a
Provider, eventual Capability invocations with consent. We need a
state-management approach that:

- Models a feature as an explicit state machine.
- Makes side effects (network, persistence, time) injectable so the
  same reducer is exercised under tests without a host.
- Composes cleanly across features so the App is the sum of its
  feature reducers, not a god-object.
- Supports streaming effects (the Assistant returns tokens, not whole
  responses) without bolting on ad-hoc machinery.
- Is well documented and used widely enough that conventions are
  shared, not invented per repo.

Plain SwiftUI `@State` / `@Observable` works for view-local state but
loses traction once a feature has multiple coupled flows, side effects
that must be cancellable, or a need to test the state machine without
mounting views. MVVM is workable but ad-hoc per project — every team
re-invents how to scope, compose, and test view models, and side
effects tend to leak into them.

## Decision

We adopt **the Composable Architecture (TCA)** as the state-management
library for OpenSpace.

Each feature ships as a TCA reducer split into:

- A **Container Reducer** that owns sub-state and routes child actions.
- One or more **Flow Reducers** that own a single state machine inside
  the feature.

I/O is exposed to reducers as TCA dependencies, each backed by a
**Client triplet** (Interface / Live / Test) under
`OpenSpace/OpenSpace/Shared/<Client>/`. The Composition Root in the App
target wires Live Clients via `withDependencies`. Tests inject Test
Clients per case.

The structural details — Container vs Flow split, Client triplet — are
captured in [`docs/architecture.md`](../architecture.md).

## Consequences

What gets easier:

- Reducers are pure functions of `(State, Action) -> Effect<Action>`.
  Unit tests use the framework's `TestStore` and assert state diffs and
  effect outcomes deterministically.
- Side effects are injected, not imported. Swapping a Provider
  implementation in tests does not require subclassing or mocking
  frameworks.
- Streaming effects map naturally onto `Effect.run` driving an action
  stream. Cancellation, throttling, and debouncing are first-class.
- New features compose via `Scope` and `forEach` instead of bespoke
  glue per feature.

What gets harder:

- TCA carries a learning curve. New contributors must understand
  reducers, effects, the dependency model, and the testing patterns.
- Some SwiftUI patterns (especially navigation) require TCA-shaped
  state, which can feel verbose for trivial screens.
- Macros and code-generation features evolve with TCA versions; we
  pin to a known-good version range and update deliberately.

What we accept:

- The verbosity for small surfaces is the price of consistency at
  scale. Where a screen is genuinely trivial and stateless, plain
  SwiftUI is allowed; the reducer is introduced when state appears.
- We will pin TCA to an exact version or a narrow range, reviewed at
  update time, per the dependency policy in `SECURITY.md`.

## Alternatives considered

- **Plain SwiftUI with `@Observable`.** Rejected because the app's
  side-effect surface (streaming Provider calls, persistence,
  consent-gated Capabilities) is too rich for view-local state to stay
  manageable.
- **MVVM with hand-rolled view models.** Rejected because every project
  invents its own conventions for scoping, side effects, and testing,
  yielding inconsistent code and weak test ergonomics.
- **An in-house lightweight reducer pattern.** Tempting; rejected
  because we would re-implement TCA's primitives (effects, scoping,
  cancellation, dependencies) badly before re-implementing them well.
- **Other community reducer libraries.** Rejected because TCA has the
  largest body of public learning material, the most mature streaming
  and dependency stories, and an active maintainer cadence.
