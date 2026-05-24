# Roadmap

OpenSpace ships in phases. Each phase has a single goal, a checklist of
deliverables, and an exit criterion that must be true before the next
phase opens. Phases are not strict gates — small parallel work is fine —
but a phase only counts as done when its exit criterion holds.

This is a planning artefact. Specific items become tracked Issues; see
[`docs/agents/issue-tracker.md`](agents/issue-tracker.md) for how those
are filed.

## Phase 0 — Repository foundation

**Goal.** A repository a contributor (human or AI coding agent) can open
and understand without help.

- [x] LICENSE in place.
- [x] `.gitignore` for Swift / Xcode.
- [x] `AGENTS.md` and `docs/agents/` playbooks.
- [x] User-facing doc set: README, CONTEXT, CONTEXT-MAP, CONTRIBUTING,
      SECURITY, CODE_OF_CONDUCT, CHANGELOG, architecture, roadmap, ADR
      practice.
- [x] Issue and PR templates aligned with the PRD-style body documented
      in `docs/agents/issue-tracker.md`.

**Exit criterion.** A contributor can clone the repo and answer "what
is this product, how do I contribute, what is decided" using only the
docs.

## Phase 1 — Skeleton app

**Goal.** A buildable iOS app with the architectural skeleton in place.

- [ ] Replace the Xcode template scaffold (`ContentView`, `Item`) with
      the App composition root.
- [ ] Establish the `Features/` and `Shared/` directory layout described
      in [`docs/architecture.md`](architecture.md).
- [ ] Wire TCA into the project (dependency, root Store, root reducer).
- [ ] Wire the SwiftData `ModelContainer` into the Composition Root.
- [ ] First Client triplet (a no-op example) to lock in the
      Interface / Live / Test pattern.
- [ ] Swift Testing target green with at least one reducer test using a
      Test Client.

**Exit criterion.** `OpenSpace` builds and launches on an iOS 17.6
simulator into an empty but architecturally-correct shell, and CI
build/lint/unit-test checks pass. UI smoke testing is manual and performed
by the user/developer.

## Phase 2 — Onboarding

**Goal.** A first-launch experience that introduces the Assistant and
captures the consent the app needs.

- [ ] Onboarding feature module under `Features/Onboarding/` with the
      four-layer split.
- [ ] Container Reducer + Flow Reducer for the onboarding sequence.
- [ ] `OnboardingProgressEntity` (SwiftData) to gate re-entry.
- [ ] Composition Root reads the entity at launch and routes accordingly.
- [ ] Reducer/snapshot coverage for the onboarding flow; UI smoke testing is manual by the user/developer.

**Exit criterion.** First-launch users complete onboarding once;
subsequent launches skip directly to the main surface.

## Phase 3 — Conversation surface

**Goal.** A working chat surface that streams replies from a Provider.

- [ ] Conversation feature module with Container + Flow Reducers.
- [ ] Conversation, Turn, and Message Domain types.
- [ ] Storage Client persisting Conversations through SwiftData.
- [ ] Provider Client Interface with a Live implementation against the
      project's chosen model service and a Test implementation that
      yields canned chunks.
- [ ] Streaming UI that renders partial Assistant Turns.
- [ ] Conversation list with create / open / delete.

**Exit criterion.** A user can hold a multi-turn conversation that is
persisted across launches, with streaming responses.

## Phase 4 — Capabilities

**Goal.** The Assistant can perform side effects on the user's behalf
through a small set of Capabilities, with consent.

- [ ] Capability protocol in `Shared/Capability/Interface/`.
- [ ] Consent flow modelled in the Application layer; consent state
      persisted.
- [ ] Two or three concrete Capabilities (scope to be tracked as
      Issues): something read-only, something write-side, and something
      external.
- [ ] Audit log surfaced in the UI for Capability invocations.

**Exit criterion.** The Assistant can invoke Capabilities only after
consent, and the user can review and revoke consent from inside the app.

## Phase 5 — Productivity surfaces

**Goal.** OpenSpace integrates with the platform conventions that make a
mobile assistant feel native.

- [ ] Share-sheet entry point.
- [ ] Shortcuts / App Intents for common Capabilities.
- [ ] Widgets for the most-used surface(s).
- [ ] Focus filter integration where appropriate.

**Exit criterion.** A user can invoke OpenSpace from outside the app
through at least Share Sheet and Shortcuts.

## Phase 6 — Hardening

**Goal.** The app is ready for an external beta.

- [ ] Error states reviewed across reducers and presented uniformly.
- [ ] Accessibility audit (Dynamic Type, VoiceOver, reduced motion).
- [ ] Performance pass on streaming and conversation list scrolling.
- [ ] Security review: credential handling, log redaction, ATS posture.
- [ ] CI green for build, unit tests, and lint. UI smoke testing remains manual by the user/developer.

**Exit criterion.** Beta build distributable to external testers without
known critical or accessibility-blocking issues.

## Out of scope for now

- Cross-platform targets (macOS / Catalyst, iPadOS-specific UI).
- Cloud sync of conversations across devices.
- Multi-user / shared-account workflows.
- Plugin loading at runtime.
- Public Capability marketplace.

These may be revisited in a later phase. When they are, the decision
will land as an ADR.
