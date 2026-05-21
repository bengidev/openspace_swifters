# Architecture

This document is the layered sketch of OpenSpace. It captures the goals
that shape the architecture, the layers each feature is split into, the
shape of cross-cutting Clients, and a representative turn so a new
contributor can see how a single user interaction flows end to end.

It is intentionally short. Specific decisions live in
[`docs/adr/`](adr/). Vocabulary lives in [`CONTEXT.md`](../CONTEXT.md).

## Goals shaping the design

- **Feature isolation.** A feature owns its UI, its state machine, its
  domain types, and its I/O integration. Features can be added,
  rewritten, or removed without rippling into other features.
- **Testable by default.** I/O lives behind Clients with Live and Test
  implementations. Reducers are pure. Tests do not need a network or a
  device.
- **Provider-agnostic intelligence.** Whichever model service powers
  the Assistant, the rest of the app sees the same Provider Client
  surface.
- **Local-first persistence.** SwiftData is the source of truth for
  Conversations and user state on device. Sync is a future Client.
- **Composable through TCA.** The Composable Architecture provides the
  state machine, dependency injection, and side-effect model. Each
  feature ships a reducer that the App composition root assembles.

## Layered fractal layout

Every feature module under
`OpenSpace/OpenSpace/Features/<Feature>/` is split into four layers:

```
Features/<Feature>/
├── Presenter/         SwiftUI views + view-state mapping
├── Application/       Reducers (Container, Flow), actions, dependencies
├── Domain/            Entities, value types, business rules — no I/O
└── Infrastructure/    Adapters from Domain to platform APIs and Clients
```

Cross-cutting code lives in `OpenSpace/OpenSpace/Shared/`:

```
Shared/
└── <Client>/
    ├── Interface/     Protocol or struct-of-closures shape
    ├── Live/          Real implementation used in the app target
    └── Test/          Test double used in unit tests
```

### Layer responsibilities

**Presenter.** SwiftUI views, modifiers, animations, accessibility. Maps
reducer state to view state and view actions back to reducer actions.
Knows nothing about I/O. Holds no state of its own beyond presentation
concerns (focus, scroll position).

**Application.** TCA reducers and the actions, state, and dependencies
they manage. Splits by responsibility:

- **Container Reducer.** The feature's top-level reducer. Owns child
  states, routes child actions, scopes dependencies. Performs no
  business logic itself.
- **Flow Reducer.** A scoped reducer for a single flow's state machine
  (e.g. an onboarding sequence, a conversation lifecycle). Composed
  under the Container Reducer.

**Domain.** Pure types: entities, value objects, errors, enums modelling
the business. No SwiftUI, no SwiftData, no Foundation networking.
Trivially testable without a host app.

**Infrastructure.** Adapters that implement Domain ports against
platform APIs or Clients. SwiftData models live here when their
persistence concerns leak beyond pure Domain (the model itself can be a
thin wrapper that maps to a Domain entity).

### Clients (cross-cutting)

A Client is a protocol-shaped boundary for I/O. The repository ships
each Client as a triplet:

- **Interface** — the protocol or `@DependencyClient` struct of
  closures. Imported by features.
- **Live** — the production implementation. Performs real I/O. Used in
  the app target.
- **Test** — the unit-test implementation. Returns canned values,
  records calls, fails fast on unexpected use.

The Composition Root (the `App` type) injects Live Clients. Tests inject
Test Clients per case.

## Composition root

The App target's `App` type is the single place where:

- The SwiftData `ModelContainer` is constructed.
- Live Clients are instantiated and bound into TCA `withDependencies`.
- The root feature's Container Reducer is created with its initial state.

This is the only place the app target depends on concrete Live
implementations. Features compile against Interfaces.

## Representative turn

A user types into the conversation and submits. The flow:

1. **Presenter.** The Conversation view sends a `submitTapped` action to
   the Conversation Container Reducer.
2. **Container Reducer.** Routes the action to the Conversation Flow
   Reducer with the user's draft.
3. **Flow Reducer.** Appends a user Turn to state, transitions to
   `awaitingProvider`, and returns an `Effect.run` that calls the
   Provider Client.
4. **Provider Client (Live).** Constructs the request, opens an
   `AsyncSequence` of partial responses, and yields tokens back into
   the reducer through an action stream.
5. **Flow Reducer.** On each streamed chunk, updates the Assistant Turn
   in state. On terminal chunk, marks the Turn complete and persists
   the Conversation through the Storage Client.
6. **Storage Client (Live).** Writes the updated Conversation entity to
   SwiftData on a background context.
7. **Presenter.** Re-renders as state changes; the streamed reply
   animates into the conversation list.

A unit test for step 3 swaps the Provider Client for a Test
implementation that yields fixed chunks, asserts the reducer's state
after each chunk, and never touches the network.

## Cross-cutting concerns

**Configuration.** Environment-specific configuration (Provider base
URLs, feature flags) is loaded at the Composition Root and passed in as
dependencies. Features do not read `Bundle` or `UserDefaults` directly.

**Conversations and persistence.** Conversations are the unit of
history. SwiftData provides on-device persistence. Migration ADRs will
record schema changes as they happen. Sync is out of scope until the
roadmap calls for it.

**Security.** Provider credentials live in the iOS Keychain via a
Credentials Client. Logs redact prompts, responses, and credentials by
default. See [`SECURITY.md`](../SECURITY.md).

**Errors.** Each Client defines its own error type. Reducers translate
Client errors into user-facing Assistant turns or system alerts. Domain
types do not import platform error types.

**Observability.** A Telemetry Client captures durations and outcomes
for Provider calls and Capability invocations, with PII stripped.
Sampling and destination are configured at the Composition Root.

## Non-goals

- Cross-platform UI. OpenSpace is iOS-first; SwiftUI views are not
  expected to compile for AppKit or Catalyst without rework.
- Pluggable Capabilities at runtime. Capabilities are declared in code
  and shipped with the binary; dynamic loading is out of scope.
- Multi-tenant accounts. The app is a single-user product; account
  sharing is not modelled.

## Future direction

The current scope ships a single Conversation as the user-facing
surface. That is a deliberate MVP boundary, not the ceiling of what the
architecture can carry.

The fractal layered layout is designed so the app can grow into a
multi-surface workbench without rewriting existing features. A future
revision could host peer surfaces alongside the Conversation — for
example, long-form authoring, structured output rendering, or
sandboxed code-style transcripts — by adding feature modules under
`OpenSpace/OpenSpace/Features/` with the same four-layer split, and by
adding sub-feature folders under any existing feature when a surface
naturally lives inside another (for example a richer Home shell that
hosts more than one peer surface).

Three properties keep that door open today:

- **Provider Client is surface-agnostic.** Any new surface that needs
  model output consumes the same streaming Client; Providers do not
  need to know which surface invoked them.
- **Capabilities are declared, not surface-bound.** A Capability is
  invoked by the Assistant regardless of which surface initiated the
  Turn, so adding a surface does not require redesigning the
  Capability protocol.
- **Each feature owns its own state machine.** TCA scoping means a new
  feature module composes into the App root without touching the
  reducers of features that are already shipping.

None of this is committed work. It is the rationale for treating Home
(and, in time, any other shell feature) as an isolatable module rather
than collapsing the Conversation into the App root. When the project
decides to expand beyond a single surface, that decision will land as
an ADR and a roadmap phase, not as an architecture rewrite.

## Where to next

- Decisions that landed: [`docs/adr/README.md`](adr/README.md).
- What is shipping when: [`docs/roadmap.md`](roadmap.md).
- Vocabulary used above: [`CONTEXT.md`](../CONTEXT.md).
