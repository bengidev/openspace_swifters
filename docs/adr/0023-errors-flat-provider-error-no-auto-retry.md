# 0023. Errors: flat ProviderError enum, no auto retry, inline plus modal alert for critical

- Status: Accepted
- Date: 2026-05-22

## Context

Streaming and request-shaped vendor calls fail in many ways:
authentication rejected, model not found, rate limit, context-
length exceeded, content moderation blocked, transient network,
provider-side outage, malformed response, decode error on the
streaming protocol (ADR-0008), Keychain miss, and so on. The
shape of the error type the rest of the app sees, and the policy
for handling each shape, has consequences for UI, telemetry, audit
log, and reducer plumbing.

A nested error hierarchy (per-vendor enum wrapped in a per-feature
enum wrapped in an app-wide enum) preserves provenance but makes
exhaustive `switch` statements in reducers verbose and brittle.
A single flat enum collapses provenance into a `cause: Cause` payload
but keeps the call sites tractable. The choice interacts with
ADR-0008 (the streaming event protocol) and ADR-0006 (the Provider
Client surface).

Retry policy is a separate question. Auto-retry on transient
failures is a familiar pattern but has costs in a BYOK setting:
the user pays per retry (token-counted vendors do not refund the
prompt), and a silent retry hides genuine failure modes. The
question must answer:

- What error type does the Client surface?
- Does the app retry automatically?
- How does the user see an error — inline, modal, or both?
- What is the audit-log shape for an error?

## Decision

The Client triplet exposes a **single flat `ProviderError` enum**
in `Shared/`. Its cases cover the failure classes that any vendor
can produce, with associated values for the operationally useful
data (HTTP status, retry-after hint where vendors return one,
vendor-specific error code as a `String`):

- `.authentication` — credential rejected.
- `.notFound` — model or endpoint not found.
- `.rateLimit(retryAfter: Duration?)` — throttled.
- `.contextLengthExceeded(promptTokens: Int?, modelLimit: Int?)` —
  request too large for the model's window.
- `.contentBlocked(reason: String?)` — vendor moderation refused.
- `.serverError(status: Int)` — vendor-side 5xx.
- `.networkFailure(underlying: String?)` — transport dropped or
  timed out.
- `.decoding(underlying: String?)` — malformed response or stream
  event.
- `.cancelled` — propagated from user-initiated cancel
  (ADR-0021).
- `.keychain` — credential read failed (ADR-0010).
- `.unsupported(feature: String)` — request asked for a capability
  the vendor does not offer.
- `.other(message: String)` — last-resort case for novel errors;
  the audit log captures the raw payload.

There is **no auto retry**. A failed turn becomes a `.failed`
message (ADR-0021) with a single-tap **Retry** affordance owned by
the user. The user decides; the app does not silently re-bill them.

Surfacing in UI:

- **Inline**: every error renders as an inline failure affordance
  on the affected message (icon, one-line cause, Retry where
  applicable). This is the default and covers the long tail.
- **Modal**: errors classified **critical** also raise a single
  modal alert. Critical means the failure cannot be resolved by
  retrying and points at user-actionable state — currently
  `.authentication`, `.keychain`, and `.contextLengthExceeded`.
  The modal explains the cause and routes the user to the relevant
  Settings surface (rotate credential, switch config, summarise or
  truncate context).

The audit log persists the `ProviderError` case and its associated
values verbatim. The `.other` payload is captured as-is for
post-mortem analysis without leaking it into the user-visible UI.

`ProviderError` conforms to `Sendable` and `Equatable`. Vendor-
specific subtypes do not exist at the Client surface; mapping from
vendor errors to `ProviderError` cases is the Live implementation's
job and is unit-tested per Live (ADR-0006).

## Consequences

What gets easier:

- One enum to switch on. Reducers can write exhaustive handlers
  without nested case-paths or default-case escape hatches that
  silently drop new failure modes.
- The audit log shape is uniform across vendors. Diagnostics scripts
  can group by case without per-vendor decoding.
- No-auto-retry keeps the BYOK billing posture honest. Users see
  real failure rates and decide whether to retry.
- Critical errors get the visibility they deserve without flooding
  the long tail with modals.

What gets harder:

- Vendor-specific nuance (e.g. an OpenAI-only error code that
  Anthropic does not produce) gets flattened into `.other` or a
  general case. The Live implementation must decide the mapping
  rather than letting it leak through; reviewers must catch
  drift.
- `.contextLengthExceeded` and `.contentBlocked` are partially
  vendor-shaped (the metadata varies). The associated values are
  intentionally optional, which means consumers must handle
  `nil` paths.
- Adding a new failure class to the flat enum is a breaking change
  to every exhaustive switch. We accept this as the price of
  exhaustiveness.

What we accept:

- The user pays for their own retries. This is the deliberate
  cost of BYOK transparency; ADR-0010 (per-config credentials)
  reinforces the billing-locality posture.
- Critical-vs-non-critical is a curated list, not a heuristic.
  Adding a case to the critical set is an ADR-able event and is
  reviewed.
- `.other` exists. We accept the small UX cost of a generic error
  cell on the long tail in exchange for never silently swallowing
  a vendor's novel failure.

## Alternatives considered

- **Nested per-vendor error hierarchy.** Rejected. Forces every
  reducer to know the vendor matrix; multiplies test surface;
  collapses to the flat enum at every UI boundary anyway.
- **Auto-retry on transient cases (`.rateLimit`, `.networkFailure`,
  `.serverError`).** Rejected. Hides failure rate, charges the
  user for retries they did not request, and complicates the
  cancellation contract (ADR-0021). The user-driven Retry button
  is the v1 answer.
- **Modal on every error.** Rejected. Creates UI thrash for
  transient failures and trains users to dismiss without reading.
- **Inline only, no modal.** Rejected. Critical user-actionable
  failures (bad credential, exceeded context) deserve a forcing
  function; an inline cell on a single message is too easy to miss.
- **Open-protocol error type (`Error & Sendable`).** Rejected.
  Loses exhaustiveness; pushes per-vendor decoding into every
  call site.
- **Retry-with-backoff inside the Live implementation.** Rejected
  for v1. Belongs in a deliberate later ADR if usage data shows
  it pays for itself; the BYOK billing argument applies.
