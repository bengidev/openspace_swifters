# 0011. Model catalog: 3-tier (dynamic /models, curated fallback, free-form override)

- Status: Accepted
- Date: 2026-05-22

## Context

A user editing a `ProviderConfig` (ADR-0009) needs to pick a model id.
The product can source that list from several places, each with
trade-offs:

- **Dynamic vendor endpoint.** OpenAI, Anthropic, and OpenRouter all
  expose a `/models` (or equivalent) endpoint that returns the
  current catalog for the caller's account. Most accurate, but
  requires a valid credential and a network round-trip, and the
  payload shape varies per vendor.
- **Curated bundled list.** A list shipped with the app, picked by
  the maintainers. Always available, no network. Stale by
  construction.
- **Free-form text entry.** The user types any model id. Maximum
  flexibility, no validation. Necessary when a vendor releases a new
  model the app does not know about yet.

None of these alone is sufficient. Forcing dynamic-only blocks the
"create config" flow when offline or before a key is entered.
Forcing curated-only ages badly. Forcing free-form punishes users
who do not memorise model ids.

## Decision

The model picker is a **three-tier cascade**, presented as a single
UI surface:

1. **Tier 1 — Dynamic catalog.** When the active `ProviderConfig`
   has a stored credential (ADR-0010) and the device is online, the
   picker fetches the vendor's `/models` endpoint and presents the
   live list. Results are cached per `providerConfigId` for the app
   session; cache is invalidated on credential change. Each Live
   Provider implements `listModels()` returning a vendor-neutral
   `[ModelDescriptor]`.
2. **Tier 2 — Curated fallback.** When Tier 1 is unavailable
   (no credential yet, network failure, vendor returned an error),
   the picker shows a curated list bundled with the app, scoped to
   the selected vendor. The curated list lives at
   `OpenSpace/OpenSpace/Shared/Provider/Resources/CuratedModels.json`
   and is reviewed at every release. Each entry carries the same
   `ModelDescriptor` shape.
3. **Tier 3 — Free-form override.** A persistent "Use a custom
   model id" affordance below the list lets the user type any
   string. The string is validated only for non-empty, trimmed
   input; the vendor decides whether it is real at request time.

Selection precedence at edit time:

- The user's chosen string is what gets persisted on the
  `ProviderConfig`, regardless of which tier surfaced it.
- If a `ProviderConfig` references a model id no longer present in
  Tier 1 or Tier 2, the picker still shows the saved value as
  selected (with a "custom" annotation). Existing Conversations
  pinned to that config are unaffected.

The shared `ModelDescriptor` carries: `id`, `displayName`, optional
`contextWindow`, optional `isReasoning` flag, and optional
`deprecatedAt`. Vendor-specific fields are dropped at the boundary;
they would not portably mean anything across vendors.

## Consequences

What gets easier:

- The "happy path" gives users an accurate, current list. The
  fallback path keeps the app usable offline or before keys are
  entered. The override path keeps the app from blocking on a model
  id we have not heard of yet.
- The curated list is one bundled JSON to maintain, not three
  vendor-specific code paths.
- New vendors plug in by implementing `listModels()` and adding
  their curated entries; the picker UI does not change.

What gets harder:

- The curated list ages. We commit to reviewing it per release and
  treating its staleness as a defect. The test suite includes a
  smoke check that every curated entry deserialises into
  `ModelDescriptor`.
- Vendor `/models` payloads vary; mapping into the neutral
  descriptor occasionally drops information (e.g. per-model pricing
  on OpenRouter). We accept the loss and surface only what is
  portable.
- Free-form override means request-time errors for typos. The error
  surfacing has to make "model not found" obvious without blaming
  the user.

What we accept:

- Tier 1's session cache is intentionally short-lived. We do not
  persist model lists to SwiftData; if the vendor catalog changes
  mid-session the next picker open re-fetches.
- The curated list is opinionated. We document the criteria in the
  bundled JSON's header comment and accept that reasonable users
  may want different defaults; the override path is the answer.

## Alternatives considered

- **Tier 1 only (live `/models`).** Rejected. Blocks the "create
  config" flow when offline or before a key is entered, which is
  the most common state during onboarding.
- **Tier 2 only (curated).** Rejected. Ages badly and forces a
  release cadence on every vendor model launch.
- **Tier 3 only (free-form).** Rejected. Punishes users with
  perfect typing and makes the picker an unhelpful textbox.
- **Persisted local cache of the dynamic catalog.** Rejected at
  this stage. Adds a SwiftData entity and a freshness policy for
  marginal benefit; session cache covers the common case.
- **Per-model pricing display in the picker.** Rejected as out of
  scope. The vendors that expose pricing do so in incompatible
  shapes; surfacing it portably is its own design problem.
