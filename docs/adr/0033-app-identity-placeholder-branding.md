# 0017. App identity: placeholder branding in v1; refined incrementally during development

- Status: Accepted
- Date: 2026-05-22

## Context

An iOS app has a visual identity surface independent of its
architecture: the app icon, accent colour, launch experience,
settings-screen header art, App Store screenshots, and marketing
copy. Each of these is a small artefact in isolation and a large
effort in aggregate, and most of them are blocked on a brand
direction the project does not yet have.

Two anti-patterns we want to avoid:

- **Branding-as-blocker.** Holding feature work because the icon
  is not finalised. Foundation phase has to ship architecture
  decisions, not pixels.
- **Branding-by-default.** Letting whatever placeholder shipped
  first calcify into the actual identity because nobody flagged
  it as temporary.

The repository's structural posture (architecture-first README per
ADR-0032, naming policy in `CONTEXT.md`) means the visual identity
will be picked deliberately, not by inheritance from a peer product
or a stock-template kit.

## Decision

OpenSpace ships **placeholder branding in v1** and refines the
visual identity **incrementally** as the product takes shape.

Concretely:

- The Xcode project ships a clearly-labelled placeholder app icon
  set. The icon is recognisably a placeholder (e.g. a wordmark
  rendered in the project's accent colour) rather than a stock
  graphic that could be mistaken for a finished mark.
- The accent colour is set to a single, identifiable hue defined
  in the asset catalog. All UI accents draw from the named asset,
  not from inline literals, so a single colour change reflows the
  app.
- The launch screen is the system default until the architecture
  feels mature enough to host a deliberate one. SwiftUI's
  `LaunchScreen` storyboard ships empty; the launch is a brief
  background-coloured frame.
- App Store metadata (name, subtitle, screenshots, description) is
  treated as a Phase 6 hardening task. v1 is not on the App Store.
- **No third-party project's branding, naming style, or icon
  motif** is borrowed even as a placeholder. The naming policy in
  `CONTEXT.md` extends to visual identity.
- A `docs/branding-placeholder.md` note (or equivalent comment in
  the asset catalog) records that the current art is a placeholder,
  links to this ADR, and lists the assets that need to be replaced
  before public release. This is the "do not let it calcify" guard.

Refinement is **incremental**:

- Each phase that touches a visible surface (Onboarding in Phase 2,
  Conversation in Phase 3, Settings in Phase 5) is allowed to
  refine its corner of the visual identity, provided the change is
  consistent with what already ships.
- A coherent identity pass — final icon, accent palette, marketing
  art, App Store assets — happens in Phase 6 hardening, when the
  surfaces have stopped moving.

## Consequences

What gets easier:

- Architecture work is not blocked on design work.
- A colour or icon update is a one-place change because the asset
  catalog is the single source.
- The placeholder document keeps "we mean to replace this" visible,
  so reviewers in later phases do not have to rediscover the
  decision.

What gets harder:

- The app looks rough internally for the duration of v1. Anyone
  showing screenshots externally has to caveat that the visual
  identity is placeholder; the README and any TestFlight notes
  carry the same caveat.
- "Incremental refinement" risks fragmenting the identity if each
  phase pulls in a different direction. We mitigate by requiring
  any phase-level identity change to update `docs/branding-placeholder.md`
  and to be consistent with the existing accent and typographic
  choices.
- Phase 6 inherits a list of placeholder assets to replace. The
  list is finite and tracked, but it is a real piece of work.

What we accept:

- A placeholder identity is *visible* during v1. We trade polish
  for time-to-architecture.
- The final identity will look different from the placeholder. We
  do not promise the placeholder accent colour or wordmark
  survives Phase 6.
- The "no peer-product motifs" rule applies even when the
  placeholder is throwaway. Borrowing a familiar shape "just for
  now" leaks into screenshots, social posts, and reviewer memory.

## Alternatives considered

- **Commission a final identity at Phase 0.** Rejected. Locks
  visual decisions before the product is shaped enough to inform
  them, and competes with foundational architecture work for the
  project's limited capacity.
- **Use a stock-template icon kit unchanged.** Rejected. Reads as
  abandonware to anyone who has seen the same kit in another app,
  and crosses the naming-policy line if the template carries a
  recognisable other-product motif.
- **Branding-by-analogy ("looks like App X").** Rejected outright
  by the naming policy. Visual identity is part of the same
  posture, not exempt from it.
- **Hold the App Store launch until a final identity exists.**
  Rejected as a default; v1 is not a Store release in the first
  place, so the constraint is hypothetical. Phase 6 ties the two
  together explicitly.
- **No placeholder; ship blank assets until final.** Rejected.
  An app with no icon and no accent colour is unreviewable in
  TestFlight and unreadable on the home screen. A *labelled*
  placeholder is the smaller cost.
