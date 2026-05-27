# OpenSpace — Shared Tokens (Light + Dark)

> Platform-agnostic. Color, typography, spacing, motion, iconography. Both `mobile-guide.md` and `web-guide.md` inherit from this file.

---

## 1. Brand World

**Mood**: Editorial workstation. Calm, precise, technical-but-warm. Reads like a quiet manual for a serious creative tool — not a SaaS dashboard, not a marketing landing page.

**Three traits that must always hold across light and dark**:

1. **Warm paper, not cold UI.** In light mode the page is an off-white paper tone with a faint diagonal hatch. In dark mode the page is a warm near-black with the **same** diagonal hatch in a low-alpha warm stroke. The texture is brand.
2. **One accent, used like ink.** A single burnt-orange/terracotta accent is the only chromatic voice in both themes. It marks identity, primary actions, status, and data. No secondary brand colors, no rainbow gradients.
3. **Monospaced labels carry meaning.** Display copy is humanist sans; functional labels (status tags, route codes, system fields, IDs, numeric readouts) are monospaced. The monospace is what makes the product feel like an instrument, in either theme.

**Personality dial**:
- Editorial > Corporate
- Instrument > Dashboard
- Composed > Energetic
- Warm > Neutral
- Restrained > Decorative

---

## 2. Color System

All colors are tokens. Names are stable across themes; the **value** changes between light and dark, the **role** never does.

### 2.1 Surface tokens

| Token | Light | Dark | Role |
|---|---|---|---|
| `surface/page` | `#F4F1EC` | `#1A1816` | Page background. Carries the diagonal hatch texture. |
| `surface/card` | `#EDE9E2` | `#23211D` | Inset module surface (the soft inner panel that holds widgets). |
| `surface/raised` | `#FFFFFF` (matte) | `#2C2A26` | Floating tile inside a card (queue item, status row, secondary chip tile). |
| `surface/inverse` | `#111111` | `#F4F1EC` | Primary CTA background, selected segment fill. Inverts between themes. |
| `surface/scrim` | `rgba(0,0,0,0.04)` | `rgba(0,0,0,0.32)` | Optional subtle overlay for focused modals. |

### 2.2 Ink tokens (text)

| Token | Light | Dark | Role |
|---|---|---|---|
| `ink/primary` | `#1A1A1A` | `#F2EFE9` | Headings, body display copy. |
| `ink/secondary` | `#5B5B57` | `#B7B2A8` | Subheadlines, descriptions, paragraph body. |
| `ink/muted` | `#8A8780` | `#8A867D` | Helper text, inactive segment labels, secondary metadata. |
| `ink/onInverse` | `#FFFFFF` | `#1A1816` | Text rendered on `surface/inverse`. Inverts between themes. |
| `ink/onAccent` | `#FFFFFF` | `#1A1816` | Text rendered on saturated accent fills (`accent/600`). |

### 2.3 Accent tokens (single hue, multi-step)

The accent hue stays the same family across themes. In dark mode it shifts slightly warmer and brighter to maintain perceived contrast on the dark page.

| Token | Light | Dark | Role |
|---|---|---|---|
| `accent/600` | `#C84A1A` | `#E2622A` | Primary accent (logo mark, primary data, ring stroke, active dot). |
| `accent/500` | `#D85A24` | `#EC7038` | Default state of primary-tinted strokes and bars. |
| `accent/300` | `#F1B89A` | `#7A3B22` | Tinted backgrounds for accent chips, soft fills (ADD FOLLOW-UP bar). |
| `accent/100` | `#FBE6D7` | `#3A2418` | Subtlest accent wash (icon tile backgrounds, route-code chip fill). |
| `accent/ink` | `#9A3A14` | `#F1B89A` | Text rendered on `accent/100` / `accent/300`. |

### 2.4 Functional tokens

| Token | Light | Dark | Role |
|---|---|---|---|
| `border/hairline` | `#DCD7CE` | `#3A3833` | 1px borders, dividers, segment outlines. |
| `border/strong` | `#1A1A1A` | `#F2EFE9` | Border on selected/dark surfaces. |
| `status/idle` | `#8A8780` | `#6B6862` | Inactive queue dot, paginator off-state. |
| `status/active` | `#C84A1A` | `#E2622A` | Active queue dot, paginator active step. |
| `focus/ring` | `#D85A24` | `#EC7038` | Focus outline color (web). |

### 2.5 Background texture (both themes)

The page background carries a **45° diagonal hatch** in both light and dark.

| Property | Light | Dark |
|---|---|---|
| Stroke color | `border/hairline` at 35% alpha | `#FFFFFF` at 4% alpha |
| Stroke width | 1px | 1px |
| Pitch | 6pt between lines | 6pt between lines |
| Applied to | `surface/page` only | `surface/page` only |

The hatch is the single most identifying visual signal of the brand. **Never remove it for "cleanliness," in either theme.**

### 2.6 Theme detection

- **Mobile (iOS)**: follows the system `colorScheme`. Provide a manual override in Settings (System / Light / Dark) but default to System.
- **Web**: follows `prefers-color-scheme` by default. Provide a manual toggle that writes to `localStorage` with three states (System / Light / Dark) and applies via a `data-theme` attribute on `<html>`.

Both platforms must avoid theme flicker on first paint: the chosen theme is resolved before the first render frame.

### 2.7 Contrast guarantees

All text/background pairs must meet **WCAG AA** (4.5:1 for body, 3:1 for large display). The tokens above are tuned to satisfy this. When introducing new combinations, validate before shipping.

---

## 3. Typography

Two families. No third family is permitted anywhere in the product, ever.

### 3.1 Families

- **Display / Body** → humanist geometric sans with a slight editorial weight. Reference: *Söhne*, *Inter Display*, or *Manrope*. Used for headlines, subheads, paragraph copy, button labels.
- **Mono** → clean rectangular monospace. Reference: *JetBrains Mono*, *Berkeley Mono*, or *IBM Plex Mono*. Used **only** for: route codes, status tags, system field labels (`MODEL STUDIO`, `AGENTS / PROMPTS / MODELS / REVIEW`), prompt text inside the workspace mock, queue item labels, numerical readouts (`90%`), pagination markers (`PG.02 / 05`).

Bundle both as variable fonts where possible to minimize payload.

### 3.2 Base type scale (authoring canvas)

This is the **base** scale — measured at the mobile authoring canvas of 375×667pt and at the web authoring canvas of 1440px. Platform guides describe how this scale adapts on each platform.

| Token | Size / Line | Weight | Tracking | Use |
|---|---|---|---|---|
| `display/xl` | 28 / 34 | 700 | -0.02em | Page headline ("Ask questions, write, and explore ideas…") |
| `display/lg` | 22 / 28 | 700 | -0.02em | Secondary headlines, modal titles |
| `body/lg` | 15 / 22 | 400 | 0 | Sub-paragraph beneath headline |
| `body/md` | 14 / 20 | 400 | 0 | In-card descriptions, helper paragraphs |
| `label/md` | 14 / 18 | 600 | 0 | Button labels (CONTINUE, BACK) |
| `mono/md` | 12 / 16 | 500 | 0 | Route chip text (`MODEL WORKSPACE`), card system header (`MODEL STUDIO`) |
| `mono/sm` | 10 / 14 | 500 | +0.04em | Breadcrumb path, queue item status (`RUNNING`, `NEXT`, `QUEUED`), micro-labels (`PG.02 / 05`) |
| `mono/numeric` | 24 / 28 | 600 | -0.01em | Big readouts (`90%`) |

### 3.3 Headline rules

- Headlines wrap to **2 lines on mobile**, **1–2 lines on web**.
- Never allow 4+ line headlines.
- Headlines use **sentence case**. Never all-caps for `display/*`.
- Mono labels use **UPPERCASE**, always. They are the visual "stamp" of the product.
- Body and helper copy: **sentence case**, no terminal periods on labels, periods on sentences.

### 3.4 Italic, underline, color emphasis

- No italic in display copy. Italic is allowed in body copy for genuine semantic emphasis (book titles, foreign words).
- Underline is reserved for inline text links only (web).
- Color emphasis on words inside a headline is **not allowed**. Hierarchy comes from size, weight, and position — never from coloring a single word.

---

## 4. Spacing Scale

Single 4-unit base. Both platforms share these tokens. On mobile the unit is **pt**; on web the unit is **px**. The numbers are identical.

| Token | Value |
|---|---|
| `space/1` | 4 |
| `space/2` | 8 |
| `space/3` | 12 |
| `space/4` | 16 |
| `space/5` | 24 |
| `space/6` | 32 |
| `space/7` | 48 |
| `space/8` | 64 |

Defaults:
- In-card padding: `space/5`
- Between blocks inside a card: `space/3` to `space/4`
- Between top-level page blocks: `space/5` to `space/6`

---

## 5. Radius Scale

| Token | Value | Use |
|---|---|---|
| `radius/sm` | 6 | Icon tiles inside chips |
| `radius/md` | 10 | Segmented control container |
| `radius/lg` | 12 | Buttons, queue rows, icon-tile chips |
| `radius/xl` | 16 | Module mock card outer |
| `radius/full` | 9999 | Pills (route chip, code badge, paginator active bar) |

---

## 6. Iconography

- Single outline family across the product.
- **Stroke width**: 1.5pt at base. Scales linearly with the icon size.
- **Caps and joins**: rounded.
- **Construction**: geometric, drawn on a 24×24 grid.
- **Fill icons are forbidden**, with two exceptions: the logo mark (filled accent square) and the active queue status dot.
- Icon color follows the surrounding text color unless explicitly overridden. On accent chips, icons inherit `accent/ink`.

Common sizes:
- 14 — inside buttons, beside labels
- 16 — trailing icons in queue rows
- 20 — module header indicators
- 28 — icon tile inside the icon-tile chip (tile is 28×28, icon inside is 16)

---

## 7. Motion Language

Motion is restrained, instrument-like. Two implied cues are allowed; nothing else.

### 7.1 Staggered float-up (page enter)

When a page enters, blocks land in order with a 12pt vertical travel from `opacity 0 → 1`:

| Block | Delay |
|---|---|
| Page chrome | 0ms |
| Route + code row | 60ms |
| Headline | 120ms |
| Sub-paragraph | 180ms |
| Module mock | 240ms |
| Paginator | 300ms |
| Action bar | 360ms |

- Easing: `cubic-bezier(0.2, 0.7, 0.2, 1)`
- Duration per element: 320ms

### 7.2 Smooth segmented swap

When a segmented control changes selection (ASK / WRITE / EXPLORE, FAST / BALANCED / DEEP), the dark fill **slides between segments** over 220ms with the same easing. Text color crossfades simultaneously.

### 7.3 Forbidden motion

- No bouncing or spring overshoot.
- No parallax.
- No scroll-jacking.
- No floating/orbiting decorative elements.
- No looping ambient animations on idle.

The page should feel like turning a well-bound notebook page.

### 7.4 Reduced motion

Respect `prefers-reduced-motion` (web) and `accessibilityReduceMotion` (iOS). When reduced:
- Disable the staggered float-up. Blocks fade in simultaneously at 120ms.
- Replace the segmented control slide with an instant fill swap.
- Keep focus-ring animations and other essential affordances.

---

## 8. Elevation & Depth

Depth comes from value contrast between `surface/page`, `surface/card`, and `surface/raised` — **not** from shadows.

- **No drop shadows on the module card.**
- The only shadow permitted in the system is a soft outer glow on the slider thumb (see widget spec in platform guides), used to communicate "draggable."
- No layered z-index theatrics. Pages are flat compositions of distinct surfaces.

---

## 9. The Five-Zone Page Skeleton

Every screen in the product — onboarding, settings, model picker, future surfaces — uses the same five zones, top to bottom:

1. **Page chrome** — logo + product label · pagination · skip.
2. **Route chip + code badge** — left-aligned topic chip, right-aligned page-code badge.
3. **Headline + sub-paragraph** — display headline, 2–3 line sub.
4. **Module mock card** — the inset cream/dark panel containing the page's interactive concept.
5. **Paginator + action bar** — dot/bar progress indicator, then BACK / CONTINUE.

Adding a sixth zone is a design decision, not a tactical one. The platform guides describe how these five zones lay out on each platform.

---

## 10. Component Inventory (cross-platform)

These components exist on both platforms. Each platform guide describes the **layout** of these components; this list ensures parity.

1. Page chrome (logo + pagination + skip)
2. Route chip (left)
3. Code badge (right)
4. Module mock card (outer)
5. Module mock card — header row (dots + system label + breadcrumb)
6. Icon-tile chip (the two side-by-side discovery chips at the foot of the module card)
7. Segmented control (ASK / WRITE / EXPLORE — and FAST / BALANCED / DEEP)
8. Prompt block (the inset prompt area with `>` glyph and ghost loading lines)
9. Queue row (status dot + tag + title + helper + trailing icon)
10. Add-follow-up bar (tinted full-width bar with shortcut hint)
11. Ring readout (the 90% circular progress)
12. Slider (single-thumb, with glow on hover/drag)
13. Bar histogram (8-bar ascending budget visualization)
14. Paginator (5 steps, active = stretched bar)
15. Action bar (BACK secondary + CONTINUE primary)

---

## 11. Anti-Patterns (apply to both platforms, both themes)

1. **Do not** wrap the module mock card in another card.
2. **Do not** introduce a second accent hue. Burnt orange is the only chromatic voice. No blue links, no green success states, no red errors in the visual layer.
3. **Do not** remove the diagonal hatch on the page background. The hatch is brand.
4. **Do not** swap the monospace family for a "friendlier" sans on the UPPERCASE labels.
5. **Do not** convert headlines to all-caps. Display copy stays sentence case. Only mono labels are uppercase.
6. **Do not** add drop shadows to the module card.
7. **Do not** introduce gradients in display text or large surfaces. The only acceptable gradient is the subtle vertical wash inside the ADD FOLLOW-UP bar (accent/300 → accent/100), and even that is optional.
8. **Do not** stuff the first viewport with stats, badges, tiny pills, or trust markers. The page chrome + route chip + code badge are the only "system markers" allowed above the headline.
9. **Do not** break the five-zone skeleton.
10. **Do not** use icons outside the single outline family.
11. **Do not** introduce a third typographic weight inside body copy. Body 400, mono labels 600, display headlines 700. That is the full set.
12. **Do not** ship a dark mode that is simply "light mode with inverted colors." Dark mode has its own tuned values in §2 — use them.

---

## 12. Open Questions

These are explicitly unresolved and need a design pass before implementation:

- **Page 01** of onboarding — entry page composition.
- **Page 05** of onboarding — closing recap composition.
- **Empty/error states** for the queue list, prompt block, and reasoning dial.
- **Localization line-length rules** — headlines tuned to English; Indonesian and other locales need a test pass before the 2-line headline rule is locked.
- **Theme-switch animation** — current spec is instant. Open whether to add a 180ms crossfade.

---

*End of shared tokens. Next: open the platform guide you are building for — `mobile-guide.md` or `web-guide.md`.*
