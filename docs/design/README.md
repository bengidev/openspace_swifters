# OpenSpace — Design System Documentation

This folder holds the **design reference** for the OpenSpace mobile app.

The web and desktop-app guides previously lived here have been moved to their respective platform workspaces. This folder is the source of truth for **mobile (iOS / iPadOS) only**.

## Files in this folder

| File | Purpose | Self-contained? |
|---|---|---|
| `README.md` | This index. | — |
| `tokens-light-dark.md` | **Governance reference.** Canonical token tables (light + dark) maintained for design-team coordination across all platforms. The mobile guide duplicates these tokens inline. | Optional reference |
| `mobile-guide.md` | **Mobile (iOS / iPadOS).** Brand + tokens + scaling + page templates. SwiftUI-oriented. 375×667 base canvas with GeometryReader scaling, iPhone & iPad adaptations, Dynamic Type, compact-height overrides. | ✅ Yes |

## Portability

`mobile-guide.md` is **fully standalone**. It starts with a `§0 Foundations` section that inlines everything needed to read and implement the mobile design system without consulting any other file:

- Brand world (3 traits)
- Color tokens (light + dark) — surface, ink, accent, functional
- Diagonal hatch spec for both themes
- Typography (two families, base scale, headline rules)
- Spacing scale (4-unit base)
- Radius scale
- Iconography rules
- Motion language (staggered float-up, segmented swap, reduced motion)
- Elevation & depth rules
- The five-zone page skeleton
- Global anti-patterns (12 rules)

After `§0`, the guide proceeds with mobile-specific content: GeometryReader scaling, iPhone & iPad breakpoints, components, page templates, accessibility, and the implementation checklist.

## Role of `tokens-light-dark.md`

This file is **not required to read the mobile guide** — every token value already lives inside `mobile-guide.md §0`.

Its purpose is **governance**:

1. **Canonical reference** when there are questions like "what hex is `accent/300` in dark mode?" — read this file, do not infer from the mobile guide.
2. **Drift detector** between mobile and the parallel web / desktop guides (which now live in their own workspaces). When a token value changes, update this file first, then propagate to every platform guide in one coordinated commit.
3. **Change-management surface** for PRs that touch tokens — reviewers can read this file alone to understand what changed.

## Procedure for changing a token value

1. Update the value in `tokens-light-dark.md` first.
2. Propagate to `mobile-guide.md §0.2` (and to the web / desktop guides in their own workspaces).
3. Commit the four updates together so reviewers can verify alignment.

Token names are stable strings (`accent/600`, `surface/page`, `display/xl`, etc.), so find-and-replace on the hex value works cleanly across files.

## Source of truth

Three reference screenshots from the onboarding flow (PG.02 → PG.04 of 05) drive this system. The patterns extracted from them — the five-zone page skeleton, the module mock card, the icon-tile chip pair, the route chip + code badge header — are the design blueprint, not screen-specific.

Any new mobile screen in OpenSpace should be expressible in this system. If it cannot be, the system gets extended in a deliberate pass — not the screen.
