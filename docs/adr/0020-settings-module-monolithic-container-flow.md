# 0020. Settings module: monolithic Container with nested Flow reducers

- Status: Accepted
- Date: 2026-05-22

## Context

Settings in OpenSpace is large by the standards of the rest of the
app. It owns the list of `ProviderConfig`s, the add-config wizard,
the edit-config form, the per-config credential write path
(ADR-0010), the model-catalog browser (ADR-0011), the system-prompt
editor (ADR-0012), the inference-parameter triple
(ADR-0013), and the assorted utility surfaces (about, diagnostics,
telemetry opt-in per ADR-0014). It is also the destination of the
onboarding hand-off (ADR-0019).

The repository's feature-sliced fractal layout would happily admit a
multi-module split — `Settings.ProviderList`, `Settings.AddConfig`,
`Settings.EditConfig`, etc. — each a peer Feature module with its
own Container/Flow pair. That layout has real benefits: smaller
compile units, isolated test targets, and obvious ownership
boundaries.

It also has real costs in v1. Splitting Settings into N modules
multiplies the inter-module wiring (state pinning, action lifting,
delegation channels), forces a decision on which sub-module owns
shared concerns like the persistence Client handle, and produces a
test matrix that is mostly assertions about plumbing rather than
behaviour. The cost is paid before any user benefit lands.

The v1 question is therefore not "should Settings be a module" but
"should Settings be **one** module or **many**", and "what is the
internal reducer shape that lets us split later without rewriting".

## Decision

Settings is a **single Feature module** in v1, with the standard
internal layout (`Presenter/Application/Domain/Infrastructure`).
Inside the module, the reducer tree is a **monolithic Container
Reducer** that owns the persistent list of `ProviderConfig`s and
hosts **nested Flow reducers** for the bounded sub-flows:

- `AddConfigFlow` — the multi-step wizard that gathers vendor,
  endpoint, credential, default model, system prompt, and parameter
  triple, then persists a new `ProviderConfig` and writes its
  credential to the Keychain.
- `EditConfigFlow` — the form that mutates an existing
  `ProviderConfig` and rotates its credential when the secret
  changes.
- Smaller per-screen reducers (model-catalog browser, system-prompt
  editor, parameter form) live as plain child reducers inside the
  Container; they do not warrant the Flow wrapper because they have
  a single in/out shape.

The Container exposes a single dependency surface — the persistence
Client and the Keychain Client — and threads them into the Flows via
TCA's standard dependency mechanism. Flows emit `Delegate` actions
that the Container interprets (e.g. `AddConfigFlow.Delegate.created`
triggers a list refresh). Flows do not reach into peer Flows; cross-
flow effects route through the Container.

Per-feature module split is **tracked as a post-v1 follow-up**. The
trigger for splitting is concrete: when any single Flow needs its
own preview target, its own snapshot tests at scale, or grows beyond
roughly 600 lines of reducer logic, we lift it into a sibling
Feature module and delegate to it from the Settings Container. The
Container/Flow shape chosen here is intentionally compatible with
that lift — a Flow already has the boundaries a module would
require.

## Consequences

What gets easier:

- One module compiles, one test target runs, one preview catalog.
  Cold-build time and CI graph stay small in the foundation phase.
- Cross-flow concerns (refreshing the config list after an add or
  edit) live in one reducer; no inter-module event bus is needed.
- The dependency surface is declared once. Changes to the
  persistence Client signature touch one module instead of N.
- The Container/Flow split means the eventual module lift is a
  relocation, not a rewrite.

What gets harder:

- The Settings reducer file (or files within the module) grows
  faster than other Features in the foundation phase. Reviewers
  must enforce sub-file partitioning by Flow rather than letting
  the Container reducer absorb everything.
- Parallel work on Add and Edit can collide on the Container's
  state shape if contributors do not coordinate. The Flow
  boundary mitigates this for Flow-internal state but not for the
  shared list.
- A regression in any Settings Flow can stall an unrelated
  Settings change because the test target is shared.

What we accept:

- Settings is structurally heavier than other Feature modules in
  v1. The cost of premature splitting is higher than the cost of
  carrying it.
- The post-v1 split criterion is judgement-driven. We pay the cost
  of a future refactor in exchange for shipping foundation faster.
- New contributors will see Settings as the canonical example of
  Container/Flow at scale; we mitigate by keeping each Flow's
  state and action enums short, named, and documented.

## Alternatives considered

- **Per-feature module split from day one** (`AddConfig`,
  `EditConfig`, `ProviderList`, `ModelCatalog`, etc., each a peer
  module). Rejected for v1. Multiplies wiring without shipping
  user-visible value; the cost is paid up front and the benefit is
  realised only when one of the Flows grows past the lift trigger.
- **One flat reducer for all of Settings.** Rejected. Sub-flows
  have lifecycle (multi-step wizards, modal dismissals) that benefit
  from their own state machines; flattening forces every screen's
  ephemeral state into the Container.
- **Separate reducer per screen with no Container.** Rejected. The
  list of configs is shared state across screens; without a
  Container reducer, each screen must read and write the list
  directly, multiplying the persistence Client usage and the
  invariants that have to hold.
- **Move credential writes into a dedicated `CredentialsFlow`.**
  Considered; rejected. Credential writes are coupled to config
  creation/edit and gain nothing from being a peer Flow. The
  Keychain Client handle is enough abstraction; ADR-0010 already
  pins the per-config UUID contract.
- **Use an external coordinator pattern instead of TCA reducers
  for navigation.** Rejected. Mixing TCA with a coordinator layer
  for one module is more friction than the monolith costs, and
  would diverge from the rest of the app's navigation idiom.
