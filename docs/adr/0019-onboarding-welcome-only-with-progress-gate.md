# 0019. Onboarding: welcome-only with OnboardingProgressEntity gate

- Status: Accepted
- Date: 2026-05-22

## Context

OpenSpace launches into a feature-rich surface (multi-config providers,
multimodal compose, conversation list with pin/archive/folder/tag).
A first-run user who is dropped straight into an empty conversation
list without any framing has no signal that the app is BYOK, that
provider configuration is required before sending a turn, or that the
keys live in their own Keychain.

At the same time, OpenSpace is a tool used repeatedly by power users.
A multi-screen forced tour on every cold launch — even a polished one —
is an irritant after the first session and a maintenance liability:
each new feature tempts a new tour slide, each tour slide tempts a new
gating decision, and the surface area grows without bound.

A separate forcing function is structural. The Settings flow that
collects the first `ProviderConfig` and writes its credential to the
Keychain (ADR-0009, ADR-0010) needs a deterministic place to be
launched from on first run, and a deterministic way to **not** launch
on subsequent runs. The decision must answer:

- What does the first-run user see, and exactly once?
- How does the app remember that onboarding is done, durably, across
  reinstalls within the same SwiftData store?
- How is the gating wired into the TCA tree without leaking onboarding
  concerns into every feature reducer?

## Decision

The onboarding surface is a **single welcome screen**. It introduces
OpenSpace in one paragraph, names the BYOK posture explicitly, and
offers exactly two affordances: a primary "Add a provider" button
that hands off to the Settings add-config flow, and a secondary
"Skip for now" link that dismisses the welcome.

There is no carousel, no permission pre-prompt, no sample
conversation, no marketing imagery. The intent is to give the user
enough to know what to do next and nothing more.

Onboarding completion is persisted as an `OnboardingProgressEntity`
in the SwiftData store. The entity has, at minimum, a `completedAt:
Date?` field; future onboarding milestones can extend it without a
schema migration beyond the standard `VersionedSchema` flow
(ADR-0017). Completion is set when the user dismisses the welcome by
either path — adding a config or skipping.

The TCA tree mirrors the Container/Flow split used elsewhere in the
app:

- An **OnboardingContainer** reducer owns presentation, reads the
  `OnboardingProgressEntity` at app start, and decides whether to
  present the welcome or pass through to the main app surface.
- An **OnboardingFlow** reducer owns the welcome screen's local
  state (button-tap intents, the hand-off action to Settings) and
  emits a single `Delegate.completed` action upward when the user
  finishes.
- The Container observes `Delegate.completed`, writes the entity
  via the persistence Client, and tears the welcome down.

Skipping is permanent for the entity-bearing user but reversible
through Settings — a "Reset onboarding" affordance is **not** in
v1; users who want the welcome back can reinstall. This is
deliberate: the welcome is informational, not gated content.

## Consequences

What gets easier:

- Cold-start UX is one screen to design, localise, and accessibility-
  audit. Adding new features does not tempt a new tour slide because
  the tour does not exist.
- Settings remains the single home for BYOK configuration. Onboarding
  hands off via the existing add-config flow rather than duplicating
  it inline, so there is one credential-write path to test
  (ADR-0010).
- The Container/Flow split keeps onboarding state out of the main
  app reducer; main features do not need to know whether onboarding
  has run.
- The `OnboardingProgressEntity` is a structured hook for future
  milestones (e.g. "saw the v1.1 release notes") without rewriting
  the gate.

What gets harder:

- Users who skip without adding a config land in an empty app and
  must discover Settings on their own. We accept this; the welcome
  states the requirement and the empty-state of the conversation
  list points at Settings.
- The entity lives in the user's SwiftData store, so a clean
  reinstall replays the welcome. We treat this as a feature, not a
  bug.

What we accept:

- The welcome is informational and dismissible. Users who want a
  longer tour can read the README or the in-app About screen
  (covered by a separate ADR if and when one is added).
- A single dismissal path mixing "added a config" and "skipped"
  collapses two intents into one entity field; if telemetry
  (ADR-0014) later distinguishes them, the entity grows a discrete
  enum without breaking the gate.

## Alternatives considered

- **No onboarding screen.** Rejected. First-run users have no signal
  that the app is BYOK; the empty conversation list is hostile to a
  user who arrived expecting a hosted assistant.
- **Multi-step carousel (welcome / providers / privacy / done).**
  Rejected. Each slide is a maintenance liability and a per-launch
  irritant after the first session; the marginal information beyond
  one screen does not justify the cost.
- **Forced provider configuration before app entry.** Rejected. The
  app must be inspectable without keys for evaluation; forcing
  configuration also conflates onboarding with Settings and
  duplicates the credential-write path.
- **`UserDefaults` flag instead of a SwiftData entity.** Rejected.
  Defaults are fine for ephemeral UI flags but onboarding state is
  user-data-shaped and benefits from being co-located with the rest
  of the SwiftData store (one backup target, one reset surface, one
  schema-versioning story per ADR-0017).
- **Server-driven onboarding content.** Rejected. OpenSpace has no
  server; an on-device welcome string is enough and aligns with the
  privacy posture of ADR-0014.
