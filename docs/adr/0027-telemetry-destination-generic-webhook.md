# 0027. Telemetry destination: generic webhook, HTTPS-only, fire-and-forget

- Status: Accepted
- Date: 2026-05-22

## Context

ADR-0026 establishes a tiered telemetry model whose third tier
forwards events to a destination the user controls. That ADR
deliberately leaves the *shape* of the destination to a follow-up
record. This is that record.

Three forces apply:

- **User trust.** OpenSpace cannot ship a telemetry path that the
  user cannot turn off, inspect, or point somewhere else. A vendor
  SDK that phones home to an endpoint we operate would invert the
  local-first posture established for the rest of the data plane.
- **App Store privacy nutrition label.** Anything we ship as an
  always-on data flow expands the declared categories on the
  privacy label and binds the project to a specific operational
  posture (retention, deletion, subject access). A user-configured
  destination that is off by default keeps the declared surface to
  the minimum that is honest.
- **Engineering scope.** A telemetry pipeline that buffers, retries,
  authenticates, multiplexes destinations, and reports back to the
  app is a small product on its own. v1 needs the smallest shape
  that delivers value without becoming a maintenance load.

## Decision

The remote telemetry destination in v1 is a **generic outbound
webhook** with the following constraints:

**Transport.**

- HTTPS only. The Live implementation rejects `http://` URLs and
  any URL whose TLS evaluation fails the system trust store.
  Self-signed certificates are not accepted in v1.
- One destination at a time. The user configures a single URL; no
  fan-out, no multiplexing.
- HTTP `POST` with `Content-Type: application/json`. The body is a
  single `TelemetryEvent` (ADR-0026) encoded with the project's
  shared `JSONEncoder` configuration. No batching in v1.

**Authentication.**

- Optional, configured alongside the URL. Three modes:
  1. None (URL only).
  2. Bearer token, sent as `Authorization: Bearer ***
  3. Custom header (single name/value pair) for sinks that prefer
     a non-standard auth scheme.
- The token or custom header value is stored in Keychain under a
  per-destination identifier, mirroring ADR-0010's per-config
  pattern. The webhook URL itself is stored in user defaults; only
  the secret material is in Keychain.
- Removing the destination triggers a cascade delete of the
  associated Keychain entry.

**Delivery semantics — fire-and-forget.**

- Each event is dispatched on a detached `Task` from the
  `TelemetryClient` Live implementation.
- The Live implementation reads the response status, **logs an
  internal `clientWarning` event into the Tier-1 ring buffer on
  failure**, and discards the event. There is no retry, no queue,
  no replay.
- A request timeout of **5 seconds** is enforced; longer requests
  are cancelled and counted as a failure.
- Failures do not block, surface UI, or interrupt the data plane.
  The user sees forwarding health only via the diagnostics view,
  which renders the recent ring buffer.

**Privacy nutrition label posture.**

- The remote tier is declared as **Optional / Not Linked to
  identity** on the App Store privacy nutrition label. The decision
  hinges on three properties: (a) the destination is user-supplied,
  (b) the project does not operate any default endpoint, (c) the
  events declared in ADR-0026 omit message bodies, prompts, keys,
  and full URLs.
- The Settings UI must state, in plain text adjacent to the
  destination field, that events leave the device when forwarding
  is enabled and that the project never receives them by default.

## Consequences

What gets easier:

- The remote pipeline is a thin pass-through. One Live
  implementation reads the next event from the ring buffer and
  posts it; the failure mode is bounded by the timeout.
- Adding sink integrations is a documentation problem, not a code
  problem. Any sink that accepts a JSON-bodied webhook works on
  day one.
- The Optional / Not Linked posture survives an App Store privacy
  audit because the default install makes no remote calls.

What gets harder:

- Sinks that require multipart, form-encoded, or batched payloads
  are not supported in v1. Users who need them will use a
  lightweight relay between the device and their sink. We accept
  that friction.
- Without retry, transient network blips drop events. ADR-0026's
  Tier-2 persistence mitigates the diagnostic loss; remote
  forwarding is best-effort by construction.
- The custom-header auth mode is open enough that users can
  misconfigure it (wrong header name, wrong value). The Settings
  UI shows the last forwarding result so misconfiguration is
  visible without instrumentation we control.

What we accept:

- A single destination is a real limit for power users who run
  multiple observability stacks. Multi-destination forwarding is
  out of scope for v1 and revisitable on demand.
- HTTPS-only excludes intranet HTTP sinks. We treat that as a
  feature, not a bug; ADR-0026's privacy posture would be
  hollowed out by a setting that disables transport encryption.

## Alternatives considered

- **Project-owned default endpoint.** Rejected. Forces the
  Optional posture into a Linked posture, requires us to operate
  ingestion infrastructure, and conflicts with the local-first
  posture established for the data plane.
- **Vendor SDK (OTel collector embedded, third-party APM).**
  Rejected. Expands the privacy label, pulls in a closed or large
  dependency we cannot fully audit, and removes user control over
  the sink.
- **Queue-and-retry with persistent durable storage.** Rejected
  for v1. Doubles the storage surface (ADR-0026 already debates
  Tier 2) and introduces ordering, deduplication, and backoff
  problems whose value is small relative to the in-memory plus
  optional-persist tiers.
- **Multi-destination fan-out.** Rejected for v1. Each additional
  destination compounds the failure surface and the Settings UX.
  The single-destination shape can be extended later without
  breaking the wire format.
- **TLS pinning.** Considered. Rejected for v1 because the
  destination is user-configured; pinning a user-supplied URL to
  a project-known certificate set is incoherent. Users who want
  pinning operate it at their relay.
