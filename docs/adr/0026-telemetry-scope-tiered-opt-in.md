# 0026. Telemetry scope: tiered opt-in (in-memory, optional persist, optional remote)

- Status: Accepted
- Date: 2026-05-22

## Context

OpenSpace needs operational visibility — request latency, stream
duration, error categories, model id, vendor id, token counts when
reported (ADR-0008). Without that signal, diagnosing a "slow on
network X" or "this model returns truncated streams" report devolves
to guessing.

iOS users are privacy-sensitive, and the project's stated posture is
local-first: a BYOK assistant whose data plane sits between the user
and the vendor of their choice. Any always-on remote telemetry
contradicts that posture, complicates the App Store privacy
nutrition label (ADR-0027), and creates a class of bug ("did the
event leave the device") that is expensive to debug.

Three forces apply:

- The vast majority of diagnostic value lives in the **most recent**
  events — the last few requests before a reported issue. A
  bounded in-memory window covers that need without persistence.
- Some classes of bug only manifest across launches (intermittent
  failures, day-over-day drift). Those require optional persistence.
- A small subset of power users — and the project itself, during
  beta — benefit from forwarding events to a sink they control.
  That subset must not subsidise its cost onto every other user.

## Decision

Telemetry is **tiered and strictly opt-in beyond the first tier**.

**Tier 1 — in-memory ring buffer (default, always on).**
A fixed-capacity ring buffer of `TelemetryEvent` values lives in a
shared Client (`TelemetryClient`, Interface/Live/Test triplet under
`OpenSpace/OpenSpace/Shared/Clients/`). Capacity is **256 events**;
on overflow, the oldest event is dropped. The buffer is wiped on
app termination — no disk write, no Keychain entry, no
cross-launch persistence. The buffer is read-only to the rest of
the app via a `recent(limit:)` accessor used by the diagnostics
view.

**Tier 2 — local persistence (opt-in).**
When the user enables "Save diagnostics across launches" in
Settings, the ring buffer's contents are mirrored into a SwiftData
store (ADR-0003) with a hard cap of **2 000 events** and rolling
eviction by `recordedAt`. Events are stored as-is; no further
processing. Disabling the toggle deletes the persisted store
synchronously. The setting is off by default.

**Tier 3 — remote forwarding (opt-in).**
When the user configures a telemetry destination, each new event
is forwarded according to ADR-0027 (generic webhook, HTTPS-only,
fire-and-forget). Tier 3 implies Tier 1 but does **not** imply
Tier 2 — a user who wants ephemeral local visibility plus remote
forwarding should not be forced to also persist on disk. The
absence of a configured destination disables Tier 3 entirely; no
network call is ever made.

`TelemetryEvent` carries:

- `id: UUID`, `recordedAt: Date`
- `kind: Kind` — enum (`requestStart`, `streamFirstByte`,
  `streamFinish`, `error`, `clientWarning`)
- `vendor: String`, `model: String`, `providerConfigID: UUID`
- `latencyMS: Int?`, `tokensIn: Int?`, `tokensOut: Int?`
- `errorCategory: ErrorCategory?` — coarse classification only
  (network, decode, vendor4xx, vendor5xx, cancelled)
- `correlationID: UUID` — joins related events from the same turn

Notable omissions: no message bodies, no system prompts, no API
keys, no full URLs (host only), no stack traces.

## Consequences

What gets easier:

- The default install ships zero telemetry surface area. The
  privacy posture is defensible without a checklist.
- Diagnosing a recently-reported bug works against the in-memory
  buffer with no setup, including in TestFlight builds.
- Persistence is a thin mirror layer; the ring buffer is the
  source of truth and retains its semantics offline.
- The remote tier is a single Live implementation (ADR-0027) that
  reads from the same buffer; no parallel pipeline.

What gets harder:

- A bug that requires events older than the ring buffer or the
  current launch is invisible without Tier 2. We accept that as
  the price of an opt-in posture.
- Settings UI must clearly differentiate the three tiers and
  explain that disabling Tier 2 deletes data immediately. That UX
  cost is real but bounded.

What we accept:

- The fixed capacities (256 in-memory, 2 000 persisted) are
  educated guesses for v1. They will be revisited if user reports
  show meaningful loss; no migration is needed since the buffer
  is non-authoritative.
- Field-level redaction (no message bodies, no full URLs) means
  some bug classes ("the request body was malformed") cannot be
  reproduced from telemetry alone. The user-supplied repro path
  remains the canonical mechanism for those.

## Alternatives considered

- **Always-on remote telemetry to a project-owned endpoint.**
  Rejected. Contradicts the local-first posture, forces a
  Linked-to-User entry on the privacy nutrition label, and
  introduces a server-side dependency the project does not want
  to operate.
- **Disk persistence by default.** Rejected. Burdens users who
  never open the diagnostics view with a growing local store and
  raises the floor of what an attacker who gets file-system access
  can read.
- **Unbounded in-memory buffer.** Rejected. Long-running sessions
  would accumulate megabytes of structured data that the app
  never frees until termination.
- **Single global toggle "send anonymous diagnostics".**
  Rejected. Conflates local visibility with remote forwarding;
  users who want one but not the other are not served. The
  three-tier split is one extra setting for a meaningful gain.
- **Vendor-managed telemetry SDK.** Rejected. Pulls in a
  closed-source dependency, expands the privacy label surface,
  and removes user control over the sink. ADR-0027 keeps the
  sink user-owned.
