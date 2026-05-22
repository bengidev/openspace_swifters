# 0006. Provider abstraction shape: one Client surface, N Live per vendor

- Status: Accepted
- Date: 2026-05-22

## Context

The Assistant in OpenSpace talks to one of several LLM providers. Each
vendor exposes a different transport, authentication scheme, request
shape, and streaming format. Without a unifying abstraction, vendor
choice would leak into reducers, views, and tests, and adding a third
vendor would touch every layer.

The state-management decision in ADR-0002 already commits us to the
Client triplet pattern (Interface / Live / Test) under
`OpenSpace/OpenSpace/Shared/<Client>/`, with reducers depending on the
Interface and the Composition Root wiring a Live implementation through
`withDependencies`. That pattern needs to extend to the Provider
surface, and the question is *how*: one Interface per vendor, or one
Interface shared across vendors.

A single shared Interface lets reducers stay vendor-agnostic. Vendor
specifics — wire format, header conventions, streaming framing — sit
behind the Interface, where they can be exercised in isolation.

## Decision

We expose **one Provider Client surface** in
`OpenSpace/OpenSpace/Shared/Provider/Interface/`. The Interface defines
the operations the Assistant feature needs (model listing, streamed
chat completion, cancellation), expressed in vendor-neutral domain
types.

Each vendor gets **its own Live implementation** (`OpenAILiveProvider`,
`AnthropicLiveProvider`, `OpenRouterLiveProvider`) under
`Shared/Provider/Live/<Vendor>/`. Every Live implementation:

- Takes its credentials and base configuration through its initializer
  (no hidden globals).
- Maps the shared domain request type into its vendor wire format on
  the way out, and the vendor wire format into the shared streaming
  event type on the way in (see ADR-0008).
- Surfaces vendor-specific errors as cases of a shared `ProviderError`
  enum, with the original error preserved as `underlying` for
  diagnostics.

A single Test implementation under `Shared/Provider/Test/` provides
deterministic stubs for reducer tests; vendor-specific Test variants
are added only when a test genuinely needs vendor-shaped behaviour.

The Composition Root selects the Live implementation at runtime based
on the active `ProviderConfig` (ADR-0009).

## Consequences

What gets easier:

- Reducers, views, and feature tests stay vendor-agnostic. Adding a
  fourth vendor is a new Live implementation under `Shared/Provider/`,
  not a change to the Assistant feature.
- Vendor-specific quirks (rate limits, streaming framing, error
  taxonomy) live in one file each, where they can be unit-tested in
  isolation against canned wire fixtures.
- Swapping vendors at runtime is a change of which Live the
  Composition Root resolves, not a code change in the feature layer.

What gets harder:

- The shared Interface must be designed for the union of vendor
  capabilities, not the intersection. Some operations may have to
  return `ProviderError.unsupported` on a vendor that does not
  implement them.
- A new vendor capability that does not fit the shared Interface
  forces a small Interface update; we treat that as a deliberate
  ADR-worthy event rather than ad-hoc growth.

What we accept:

- Mapping cost: each Live implementation pays a translation tax
  between the vendor wire format and the shared domain type. We
  consider that tax acceptable for the isolation it buys.
- Lowest-common-denominator risk: the shared Interface might omit a
  vendor-specific capability we want later. When that happens we
  amend the Interface deliberately and update every Live in lockstep.

## Alternatives considered

- **One Interface per vendor.** Rejected. Reducers would import a
  vendor-specific type, leaking vendor choice into the feature layer
  and forcing duplicate reducer code per vendor.
- **A facade over vendor SDKs without a shared Interface.** Rejected.
  Vendor SDKs vary in maturity and shape; depending on them directly
  ties our release cadence to theirs and complicates testing.
- **A plug-in registry resolved by string identifier.** Rejected.
  Adds runtime indirection without buying anything we cannot get from
  a typed Interface plus N Live implementations.
