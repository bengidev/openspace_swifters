# OpenSpace — Mobile Guide (iOS / iPadOS)

> Self-contained. This file describes the full mobile design system: brand, tokens, scaling, layout, components, and page templates for **iPhone and iPad**.
>
> No external references required. The shared `tokens-light-dark.md` in this folder is governance reference only — it duplicates the foundational tokens captured below.

---

## 0. Foundations (tokens, type, motion)

This section is the platform-agnostic core, inlined into this guide so the file is standalone. Platform-specific layout begins in §1.

### 0.1 Brand World

**Mood**: Editorial workstation. Calm, precise, technical-but-warm. Reads like a quiet manual for a serious creative tool — not a SaaS dashboard, not a marketing landing page.

Three traits that must always hold across light and dark:

1. **Warm paper, not cold UI.** In light mode the page is an off-white paper tone with a faint diagonal hatch. In dark mode the page is a warm near-black with the **same** diagonal hatch in a low-alpha warm stroke. The texture is brand.
2. **One accent, used like ink.** A single burnt-orange/terracotta accent is the only chromatic voice in both themes.
3. **Monospaced labels carry meaning.** Display copy is humanist sans; functional labels (status tags, route codes, system fields, IDs, numeric readouts) are monospaced.

Personality dial: Editorial > Corporate · Instrument > Dashboard · Composed > Energetic · Warm > Neutral · Restrained > Decorative.

### 0.2 Color Tokens (Light + Dark)

All colors are tokens. Names are stable across themes; the **value** changes between light and dark, the **role** never does.

#### Surface tokens

| Token | Light | Dark | Role |
|---|---|---|---|
| `surface/page` | `#F4F1EC` | `#1A1816` | Page background. Carries the diagonal hatch texture. |
| `surface/card` | `#EDE9E2` | `#23211D` | Inset module surface. |
| `surface/raised` | `#FFFFFF` | `#2C2A26` | Floating tile inside a card (queue item, status row, secondary chip tile). |
| `surface/inverse` | `#111111` | `#F4F1EC` | Primary CTA background, selected segment fill. Inverts between themes. |
| `surface/scrim` | `rgba(0,0,0,0.04)` | `rgba(0,0,0,0.32)` | Optional subtle overlay for focused modals. |

#### Ink tokens (text)

| Token | Light | Dark | Role |
|---|---|---|---|
| `ink/primary` | `#1A1A1A` | `#F2EFE9` | Headings, body display copy. |
| `ink/secondary` | `#5B5B57` | `#B7B2A8` | Subheadlines, descriptions, paragraph body. |
| `ink/muted` | `#8A8780` | `#8A867D` | Helper text, inactive segment labels, secondary metadata. |
| `ink/onInverse` | `#FFFFFF` | `#1A1816` | Text rendered on `surface/inverse`. |
| `ink/onAccent` | `#FFFFFF` | `#1A1816` | Text rendered on saturated accent fills (`accent/600`). |

#### Accent tokens (single hue, multi-step)

| Token | Light | Dark | Role |
|---|---|---|---|
| `accent/600` | `#C84A1A` | `#E2622A` | Primary accent (logo mark, primary data, ring stroke, active dot). |
| `accent/500` | `#D85A24` | `#EC7038` | Default state of primary-tinted strokes and bars. |
| `accent/300` | `#F1B89A` | `#7A3B22` | Tinted backgrounds for accent chips, soft fills. |
| `accent/100` | `#FBE6D7` | `#3A2418` | Subtlest accent wash (icon tile backgrounds, route-code chip fill). |
| `accent/ink` | `#9A3A14` | `#F1B89A` | Text rendered on `accent/100` / `accent/300`. |

#### Functional tokens

| Token | Light | Dark | Role |
|---|---|---|---|
| `border/hairline` | `#DCD7CE` | `#3A3833` | 1px borders, dividers, segment outlines. |
| `border/strong` | `#1A1A1A` | `#F2EFE9` | Border on selected/dark surfaces. |
| `status/idle` | `#8A8780` | `#6B6862` | Inactive queue dot, paginator off-state. |
| `status/active` | `#C84A1A` | `#E2622A` | Active queue dot, paginator active step. |
| `focus/ring` | `#D85A24` | `#EC7038` | Focus outline color. |

#### Diagonal hatch (page background, both themes)

| Property | Light | Dark |
|---|---|---|
| Stroke color | `border/hairline` @ 35% alpha | `#FFFFFF` @ 4% alpha |
| Stroke width | 1pt | 1pt |
| Pitch | 6pt between lines | 6pt between lines |
| Angle | 45° | 45° |

Applied to `surface/page` only. **Never** applied inside cards. The hatch is brand — do not remove it for "cleanliness."

#### Contrast guarantees

All text/background pairs meet **WCAG AA** (4.5:1 body, 3:1 large display). The tokens above are tuned to satisfy this. Validate new combinations before shipping.

### 0.3 Typography

Two families. No third family is permitted anywhere in the product.

- **Display / Body** → humanist geometric sans with a slight editorial weight. Reference: *Söhne*, *Inter Display*, or *Manrope*. Used for headlines, subheads, paragraph copy, button labels.
- **Mono** → clean rectangular monospace. Reference: *JetBrains Mono*, *Berkeley Mono*, or *IBM Plex Mono*. Used **only** for: route codes, status tags, system field labels (`MODEL STUDIO`, `AGENTS / PROMPTS / MODELS / REVIEW`), prompt text, queue item labels, numerical readouts (`90%`), pagination markers (`PG.02 / 05`).

#### Base type scale (375×667 authoring canvas, pt)

| Token | Size / Line | Weight | Tracking | Use |
|---|---|---|---|---|
| `display/xl` | 28 / 34 | 700 | -0.02em | Page headline |
| `display/lg` | 22 / 28 | 700 | -0.02em | Secondary headlines, modal titles |
| `body/lg` | 15 / 22 | 400 | 0 | Sub-paragraph beneath headline |
| `body/md` | 14 / 20 | 400 | 0 | In-card descriptions, helper paragraphs |
| `label/md` | 14 / 18 | 600 | 0 | Button labels (CONTINUE, BACK) |
| `mono/md` | 12 / 16 | 500 | 0 | Route chip text, card system header |
| `mono/sm` | 10 / 14 | 500 | +0.04em | Breadcrumb path, queue status, micro-labels |
| `mono/numeric` | 24 / 28 | 600 | -0.01em | Big readouts (`90%`) |

#### Headline rules

- Headlines wrap to **2 lines on mobile**.
- Never allow 4+ line headlines.
- Headlines use **sentence case**. Never all-caps for `display/*`.
- Mono labels use **UPPERCASE**, always.
- Body: sentence case, no terminal periods on labels, periods on sentences.
- No italic in display. No underline except inline text links. No color emphasis on words inside a headline.

### 0.4 Spacing Scale (4pt base)

| Token | Value |
|---|---|
| `space/1` | 4pt |
| `space/2` | 8pt |
| `space/3` | 12pt |
| `space/4` | 16pt |
| `space/5` | 24pt |
| `space/6` | 32pt |
| `space/7` | 48pt |
| `space/8` | 64pt |

Defaults: in-card padding `space/5`; between blocks inside a card `space/3`–`space/4`; between top-level page blocks `space/5`–`space/6`.

### 0.5 Radius Scale

| Token | Value | Use |
|---|---|---|
| `radius/sm` | 6pt | Icon tiles inside chips |
| `radius/md` | 10pt | Segmented control container |
| `radius/lg` | 12pt | Buttons, queue rows, icon-tile chips |
| `radius/xl` | 16pt | Module mock card outer |
| `radius/full` | 9999pt | Pills (route chip, code badge, paginator active bar) |

### 0.6 Iconography

- Single outline family across the product.
- Stroke width 1.5pt at base, scales linearly.
- Rounded caps and joins, geometric construction, 24×24 grid.
- Fill icons forbidden except: the logo mark and the active queue status dot.
- Icon color follows surrounding text color unless explicitly overridden.

Sizes: 14 (inside buttons), 16 (queue row trailing), 20 (module header), 28 (icon tile container; glyph inside is 16).

### 0.7 Motion Language

Motion is restrained, instrument-like. Two implied cues are allowed; nothing else.

**Staggered float-up (page enter).** Blocks land in order with 12pt vertical travel from `opacity 0 → 1`:

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

**Smooth segmented swap.** When a segmented control changes selection, the dark fill slides between segments over 220ms with the same easing. Text color crossfades simultaneously.

**Forbidden**: bouncing, spring overshoot, parallax, scroll-jacking, floating decorative elements, looping ambient animations.

**Reduced motion**: respect `accessibilityReduceMotion`. Disable the staggered float-up (fade in simultaneously at 120ms). Replace the segmented control slide with an instant fill swap.

### 0.8 Elevation & Depth

Depth comes from value contrast between `surface/page`, `surface/card`, and `surface/raised` — **not** from shadows. No drop shadows on the module card. The only shadow permitted is a soft outer glow on the slider thumb (see §6.3).

### 0.9 The Five-Zone Page Skeleton

Every screen in the product uses the same five zones, top to bottom:

1. **Page chrome** — logo + product label · pagination · skip.
2. **Route chip + code badge** — left-aligned topic chip, right-aligned page-code badge.
3. **Headline + sub-paragraph** — display headline, 2–3 line sub.
4. **Module mock card** — the inset panel containing the page's interactive concept.
5. **Paginator + action bar** — progress indicator, then BACK / CONTINUE.

Adding a sixth zone is a design decision, not a tactical one.

### 0.10 Anti-Patterns (apply globally)

1. Do not wrap the module mock card in another card.
2. Do not introduce a second accent hue.
3. Do not remove the diagonal hatch.
4. Do not swap the monospace family for a sans on UPPERCASE labels.
5. Do not convert headlines to all-caps.
6. Do not add drop shadows to the module card.
7. Do not introduce gradients in display text or large surfaces. (Exception: optional vertical wash inside ADD FOLLOW-UP bar.)
8. Do not stuff the first viewport with stats, badges, trust markers.
9. Do not break the five-zone skeleton.
10. Do not use icons outside the single outline family.
11. Do not introduce a third typographic weight in body copy (400 body, 600 mono labels, 700 display — that is the full set).
12. Do not ship dark mode as inverted light mode — use the tuned dark values in §0.2.

---

## 1. Authoring Canvas

All measurements in this document are authored against a **base design canvas of 375 × 667 pt** (iPhone SE / iPhone 6 logical resolution).

This is the smallest portrait viewport the product must support **without scroll**. Every dimension — font, spacing, card height, button height — is defined at this base and scaled up for larger devices using a single proportional multiplier.

**Why 375 × 667?** It is the most constrained portrait canvas in the modern iPhone lineup. If a screen fits here without scroll, it will fit everywhere.

---

## 2. Responsive Scaling System

### 2.1 Scaling formula

Use `GeometryReader` to compute a single scale multiplier per screen. The multiplier is then passed down to every measurement in the view tree.

```swift
struct OnboardingPage: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass)   private var vSizeClass
    @Environment(\.colorScheme)         private var colorScheme
    @Environment(\.dynamicTypeSize)     private var dynamicTypeSize

    /// Base design canvas in points.
    private let baseSize = CGSize(width: 375, height: 667)

    var body: some View {
        GeometryReader { proxy in
            let current = proxy.size
            let ratioX  = current.width  / baseSize.width
            let ratioY  = current.height / baseSize.height
            let scale   = min(ratioX, ratioY)           // never max()
            let isCompactHeight = current.height < 760

            PageContent(
                scale: scale,
                isCompactHeight: isCompactHeight,
                safeArea: proxy.safeAreaInsets
            )
            .frame(width: current.width, height: current.height)
        }
        .ignoresSafeArea()
    }
}
```

| Variable | Meaning |
|---|---|
| `ratioX` | Horizontal scale relative to 375 pt |
| `ratioY` | Vertical scale relative to 667 pt |
| `scale` | `min(ratioX, ratioY)` — preserves aspect ratio, prevents overflow |
| `isCompactHeight` | `true` when screen height < 760 pt (iPhone SE 3, mini, compact split-view) |

> **Always use `min()`, never `max()`.** Using `max()` would cause content to overflow on one axis.

### 2.2 Device breakpoint reference

| Device | Logical size | ratioX | ratioY | scale | isCompactHeight |
|---|---|---|---|---|---|
| iPhone SE (1st) | 375 × 667 | 1.000 | 1.000 | **1.000** | true |
| iPhone SE (3rd) | 375 × 667 | 1.000 | 1.000 | **1.000** | true |
| iPhone 13 mini | 375 × 812 | 1.000 | 1.217 | **1.000** | false |
| iPhone 14 / 15 | 390 × 844 | 1.040 | 1.265 | **1.040** | false |
| iPhone 16 Pro | 402 × 874 | 1.072 | 1.310 | **1.072** | false |
| iPhone 16 Pro Max | 440 × 956 | 1.173 | 1.433 | **1.173** | false |
| iPad mini (portrait) | 744 × 1133 | 1.984 | 1.699 | **1.699** | false |
| iPad (portrait) | 820 × 1180 | 2.187 | 1.769 | **1.769** | false |
| iPad Pro 11" (portrait) | 834 × 1194 | 2.224 | 1.790 | **1.790** | false |
| iPad Pro 12.9" (portrait) | 1024 × 1366 | 2.731 | 2.048 | **2.048** | false |
| iPad (landscape) | 1180 × 820 | 3.147 | 1.229 | **1.229** | false |
| iPad Pro 12.9" (landscape) | 1366 × 1024 | 3.643 | 1.535 | **1.535** | false |

On iPad **landscape**, `ratioY` becomes the limiting factor, so `scale` drops. Content remains proportional but uses less of the available width. **Center the content with a `maxWidth` container** (see §6).

### 2.3 Scaled dimension helpers

Apply `scale` using these helpers. **Never hardcode scaled values.**

```swift
extension CGFloat {
    /// Multiply a base measurement by the screen scale.
    func scaled(by scale: CGFloat) -> CGFloat { self * scale }
}

// Usage inside views that receive `scale`:
// .font(.system(size: 28.scaled(by: scale), weight: .bold))
// .padding(.horizontal, 24.scaled(by: scale))
// .frame(height: 52.scaled(by: scale))
```

For **font sizes**, use a capped scale to prevent oversized text on iPad:

```swift
func fontScale(_ base: CGFloat, screenScale: CGFloat, cap: CGFloat = 1.35) -> CGFloat {
    let capped = min(screenScale, cap)
    return base * capped
}
```

### 2.4 Per-element font scale caps

| Element | Base size (375×667) | Scale mode | Cap |
|---|---|---|---|
| Headline (`display/xl`) | 28 pt | fontScale | **1.35×** |
| Secondary headline (`display/lg`) | 22 pt | fontScale | 1.35× |
| Body (`body/lg`) | 15 pt | fontScale | 1.30× |
| Body small (`body/md`) | 14 pt | fontScale | 1.30× |
| Button label | 14 pt | fontScale | 1.30× |
| Mono header (`mono/md`) | 12 pt | fontScale | 1.25× |
| Mono small (`mono/sm`) | 10 pt | fontScale | 1.25× |
| Mono numeric (`mono/numeric`) | 24 pt | fontScale | 1.35× |
| Brand label | 12 pt | fontScale | 1.25× |
| Stack tag | 8.5 pt | fontScale | 1.20× |

Monospace labels at ≤10pt scale conservatively because they are already small and must remain crisp.

### 2.5 Layout element scaling

| Element | Base value | Scale mode | Notes |
|---|---|---|---|
| Horizontal page padding | 20 pt | direct scale | Max 36 pt after scaling |
| Top safe-area padding | 20 pt | direct scale | Add `proxy.safeAreaInsets.top` |
| Bottom safe-area padding | 16 pt | direct scale | Add `proxy.safeAreaInsets.bottom` |
| Top bar height | 44 pt | direct scale | Fixed proportion |
| Headline top spacing | 16 pt | direct scale | Reduced to 10 pt when `isCompactHeight` |
| Body top spacing | 12 pt | direct scale | Reduced to 8 pt when `isCompactHeight` |
| Card top spacing | 20 pt | direct scale | Reduced to 12 pt when `isCompactHeight` |
| Card internal padding | 14 pt | direct scale | |
| Chip pair gap | 12 pt | direct scale | |
| Paginator-to-CTA spacing | 24 pt | direct scale | |
| Button height | 48 pt | direct scale | Min 44 pt (HIG), max 56 pt |
| Button horizontal padding | 20 pt | direct scale | |
| Paginator dot height | 6 pt | direct scale | |
| Active dot width | 28 pt | direct scale | |
| Ghost button tap area | 44 pt | **fixed** | Accessibility minimum, never scaled below this |

### 2.6 Module mock card height

The module mock card is the most critical responsive element. Compute its height dynamically:

```swift
func cardHeight(screenHeight: CGFloat, scale: CGFloat, isCompact: Bool) -> CGFloat {
    let baseHeight: CGFloat   = isCompact ? 270 : 326
    let scaledBase: CGFloat   = baseHeight * scale
    let proportional: CGFloat = screenHeight * 0.43
    let maxHeight: CGFloat    = 390 * scale
    return max(scaledBase, min(proportional, maxHeight))
}
```

| Condition | Calculation |
|---|---|
| Compact height (< 760 pt) | `max(270 * scale, min(height * 0.43, 390 * scale))` |
| Regular height (≥ 760 pt) | `max(326 * scale, min(height * 0.43, 390 * scale))` |
| iPad (max width enforced) | Same formula, but card `maxWidth = 680 pt` |

The card must **never** exceed **43% of screen height**. On iPhone SE this yields ~286 pt (43% of 667). On iPhone 16 Pro Max it yields ~410 pt, capped against `390 × 1.173 = 457 pt` — the proportional clause keeps it at ~410 pt.

### 2.7 iPad adaptations

On iPad, a single-column layout becomes visually stretched if rendered full-width. Constrain content:

```swift
struct iPadContentWidth: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 680)            // cap content column
            .frame(maxWidth: .infinity)      // then center within parent
    }
}
```

| Adaptation | Rule |
|---|---|
| Max content width | **680 pt**, centered |
| Card max width | 680 pt |
| Button max width | 680 pt |
| Horizontal padding | `min(max(width * 0.055, 20), 36)` — on iPad this hits 36 pt, but content is centered inside the 680 pt container |
| Font scale cap | 1.35× to prevent oversized typography |
| Icon-tile chip pair | Stays side-by-side (already horizontal). On iPad Pro 12.9" portrait, optionally expand chips to a 3-tile row when more chips exist. |
| Module card | Stays a single column — do not split into a 2-column dashboard on iPad. The instrument should feel the same in your hand. |
| Reasoning dial layout | Ring + label may shift from stacked-vertical (on small iPhones) to side-by-side (on iPad), see §10.3. |

### 2.8 Compact height overrides

When `isCompactHeight == true` (iPhone SE, split-view, landscape iPhones), reduce spacing aggressively:

| Token | Regular | Compact |
|---|---|---|
| Headline top spacing | `16 × scale` | `10 × scale` |
| Body top spacing | `12 × scale` | `8 × scale` |
| Card top spacing | `20 × scale` | `12 × scale` |
| Card height base | `326 × scale` | `270 × scale` |
| Paginator-to-CTA spacing | `24 × scale` | `16 × scale` |
| Icon-tile chip internal padding | `12 × scale` | `8 × scale` |

### 2.9 Dynamic Type support

The product must respect the user's content size preference **without breaking the "no scroll" rule** on the onboarding pages.

```swift
@Environment(\.dynamicTypeSize) private var dynamicTypeSize

var typeScaleMultiplier: CGFloat {
    switch dynamicTypeSize {
    case .xSmall, .small, .medium: return 1.00
    case .large:                   return 1.05
    case .xLarge:                  return 1.10
    case .xxLarge:                 return 1.15
    case .xxxLarge:                return 1.20
    case .accessibility1:          return 1.25
    case .accessibility2:          return 1.30
    case .accessibility3:          return 1.35
    case .accessibility4:          return 1.40
    case .accessibility5:          return 1.45
    @unknown default:              return 1.00
    }
}
```

Apply `typeScaleMultiplier` to font sizes **after** screen-scale. Use `minimumScaleFactor` as a fallback:

```swift
Text("Ask questions, write, and explore ideas with AI models")
    .font(.system(
        size: fontScale(28, screenScale: scale) * typeScaleMultiplier,
        weight: .bold
    ))
    .minimumScaleFactor(0.75)
    .lineLimit(2)
```

When Dynamic Type exceeds `.xxxLarge`:
- Reduce headlines to **2 lines max** (already enforced).
- Truncate body to **2 lines max** to preserve the no-scroll guarantee.
- The module mock card may switch to a vertically scrollable inner content area, but the outer page remains non-scrolling.

### 2.10 Landscape iPhone

iPhone in landscape is a **degraded experience**, not a primary one. Onboarding pages should:
- Detect landscape via `verticalSizeClass == .compact`.
- Switch to a 2-column layout: narrative left, module mock right (mirroring web). Use a 50/50 split with a `space/5` gap.
- Compact height overrides apply (§2.8).
- Bottom action bar stays full-width across both columns.

---

## 3. Light + Dark Theme on iOS

Themes follow `@Environment(\.colorScheme)` by default. Tokens are defined in §0.2. Implementation hints:

- Define a single `Theme` struct that holds resolved `Color` values for the current scheme. Inject it via the SwiftUI environment so every component reads from it.
- Provide a manual override (System / Light / Dark) in Settings. Persist with `@AppStorage`.
- Resolve the theme **before** the first render frame to avoid flicker. On launch, read the stored override and apply it before the root view appears.
- Status bar style: `.darkContent` in light mode, `.lightContent` in dark mode.
- Use `Image(systemName:)` icons sparingly — they don't match the outline icon family. Prefer custom assets that ship in both light and dark variants when needed.

### Diagonal hatch implementation

The hatch must render in both themes. Implement once, parameterize by theme:

```swift
struct DiagonalHatch: View {
    let strokeColor: Color   // border/hairline @ 0.35 in light, white @ 0.04 in dark
    let pitch: CGFloat = 6   // pt
    var body: some View {
        Canvas { ctx, size in
            let diagonal = size.width + size.height
            var x: CGFloat = -size.height
            while x < diagonal {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                ctx.stroke(p, with: .color(strokeColor), lineWidth: 1)
                x += pitch
            }
        }
        .allowsHitTesting(false)
    }
}
```

Apply it as the background of `surface/page`, never of cards.

---

## 4. Layout & Grid (mobile)

### 4.1 Page padding

- **Outer page padding**: `20pt` left + right at base, scaled per device.
- **Top safe-area inset**: first content (page chrome row) sits at `20pt` below the system status bar.
- **Vertical rhythm between major blocks**: `space/5` (24pt) at base.
- **Bottom action bar**: pinned area sits `space/5` above the home indicator; buttons span the inner width with `space/3` gap between BACK and CONTINUE.

### 4.2 Vertical spec (top → bottom, base canvas)

| Block | Top margin (base, regular height) | Top margin (compact height) |
|---|---|---|
| Page chrome | 20 pt below status bar | 16 pt below status bar |
| Route + code row | space/5 (24) | space/4 (16) |
| Headline | space/4 (16) | space/3 (12) → 10 |
| Sub-paragraph | space/3 (12) | space/2 (8) |
| Module mock card | space/5 (24) | space/3 (12) |
| Paginator | space/5 (24) | space/4 (16) |
| Action bar | space/5 (24) | space/4 (16) |
| Home indicator | space/5 (24) | space/4 (16) |

All values multiply by `scale` at render time.

---

## 5. Component Specs (mobile)

The components below are the mobile-specific anatomy and pixel layout. Foundations they consume (color, type, spacing, radius) are defined in §0.

### 5.1 Page chrome

- **Left cluster**: 16×16 logo mark (`accent/600` filled, `radius/sm`) + two stacked lines:
  - Line 1: `OPENSPACE` — `mono/md`, 600 weight, `ink/primary`.
  - Line 2: `AI ASSISTANCE` — `mono/sm`, 500 weight, `ink/muted`.
- **Right cluster**: `PG.02 / 05` in `mono/md`, current page number in `ink/primary`, rest in `ink/secondary`. Followed by a **SKIP** pill.
- **SKIP pill**: 1px `border/hairline`, transparent fill, `radius/md`, padding `6pt × 14pt`, `label/md`, `ink/primary`.
- Logo→text gap: `space/3`. Pagination→SKIP gap: `space/3`. Bottom margin: `space/5`.

### 5.2 Route chip + code badge

- **Route chip** (left): pill, fill `surface/card`, no border, padding `8pt × 14pt`. Contents: 6pt `accent/600` dot · 14pt outline icon · `mono/md` label.
- **Code badge** (right): pill, fill `accent/100`, 1px `accent/300` border, padding `6pt × 12pt`, `mono/md` text in `accent/ink`, em-dash (`AI–02`, `RUN–03`, `THK–04`).
- Same row, opposite ends. Bottom margin: `space/4`.

### 5.3 Module mock card

- Background `surface/card`, `radius/xl`, padding `space/5`. **No shadow. No border. No nested outer wrapper.**
- **Inner header row**:
  - Three accent dots: `accent/600`, `accent/300`, `border/hairline`.
  - Mono uppercase label (`MODEL STUDIO`, `LIVE QUEUE`, `THINK BUDGET`).
  - Right-aligned breadcrumb: `AGENTS / PROMPTS / MODELS / REVIEW` in `mono/sm`, `ink/muted`, `/` with `space/1` margins.
- **Inner body**: page-specific widget. Hairline dividers between subsections only when stacking distinct subsections. **No nested rounded sub-cards.**
- **Footer chip pair**: two icon-tile chips, equal width, `space/3` gap.

### 5.4 Icon-tile chip

- Container: `surface/raised`, 1px `border/hairline`, `radius/lg`, padding `12pt × 14pt`.
- Left: 28×28 icon tile, `radius/sm`, fill `accent/100`, accent-tinted glyph inside.
- Right (stacked, `space/1` gap):
  - Title — `mono/md`, 600, `ink/primary`, UPPERCASE.
  - Sub — `body/md`, `ink/muted`, sentence case.
- Width: each chip = `(card inner width - space/3) / 2`.

### 5.5 Action bar

- **BACK** (secondary): transparent fill, 1px `border/hairline`, `radius/lg`, height 52pt at base, ~38% width.
- **CONTINUE** (primary): `surface/inverse` fill, no border, `radius/lg`, height 52pt at base, ~58% width.
- Both buttons: `label/md`, leading/trailing icon 14pt, `space/2` from label.
- Gap between buttons: `space/3`.

### 5.6 Paginator

- 5 elements, left-aligned, `space/2` between.
- Inactive: 6pt circle, `status/idle`.
- Active: stretched pill, 22pt × 4pt, `radius/full`, `status/active`.
- Past steps: same as inactive (no separate "completed" state in v1).
- Bottom margin to action bar: `space/5`.

---

## 6. Page-Specific Widgets (mobile)

These widgets live inside the module mock card. Their pixel anatomy is described here in full.

### 6.1 Segmented control + prompt block (PG.02)

- **Segmented control**: 3 equal segments, total height 44pt at base. Container: `surface/raised`, 1px `border/hairline`, `radius/md`.
- **Active segment**: fill `surface/inverse`, label `ink/onInverse`, `label/md`.
- **Inactive segment**: transparent, label `ink/primary`, `label/md`.
- **Prompt block** (below control):
  - `radius/lg`, fill `surface/card` (use a 2% lighter wash than the module body if needed).
  - `>` glyph in `accent/600`, mono prompt text in `ink/primary`.
  - Three loading ghost lines below the prompt: heights 6pt, `radius/full`, fill `accent/100`, widths 100% / 78% / 62%, `space/3` between.

### 6.2 Queue list (PG.03)

- Each row: `surface/raised`, 1px `border/hairline`, `radius/lg`, padding `14pt × 16pt`.
- Vertical gap between rows: `space/3`.
- Row contents:
  - 6pt status dot at far left.
  - Two-line stacked content, `space/1` gap:
    - Line 1: mono UPPERCASE tag (`RUNNING`, `NEXT`, `QUEUED`) + space + body title in `ink/primary`, `body/md`, 600.
    - Line 2: helper in `ink/muted`, `body/md`, 400.
  - Trailing 16pt icon at far right in `ink/muted`.
- **ADD FOLLOW-UP bar**: full width, height 44pt, `radius/lg`, fill `accent/300` (optional `accent/300 → accent/100` vertical gradient). Left: `+` glyph in `accent/ink` + mono UPPERCASE `ADD FOLLOW-UP`. Right: `⌘↵` in mono `accent/ink`, 12pt.

### 6.3 Reasoning dial (PG.04)

- **Ring readout** (left or top on small screens):
  - 96pt diameter, 8pt stroke, color `accent/600`. Remainder stroke `border/hairline`.
  - Center label: `90%` in `mono/numeric`.
- **Label block** (right of ring on iPad, below ring on smaller iPhones if needed):
  - Title: `DEEP REASONING` in `mono/md`, `accent/600`.
  - Sub: `Set thinking before run.` in `body/md`, `ink/secondary`.
- **Slider** (full inner width):
  - Track height 6pt, `radius/full`.
  - Filled: `accent/500`. Unfilled: `border/hairline`.
  - Thumb: 20pt white circle (`surface/raised`), 1px `border/hairline`, soft outer glow `accent/300 @ 30%`, 12pt blur.
- **Segmented control** below the slider: 3 segments (`FAST`, `BALANCED`, `DEEP`). DEEP active per reference screen.
- **Bar histogram** below the segmented control: 8 bars, equal width, `space/2` gap, heights `[24, 28, 34, 40, 46, 52, 58, 58]` pt at base. Bars 1–7 fill `accent/500`, bar 8 fills `border/hairline`. All `radius/sm`.

---

## 7. Page Templates (mobile)

Every onboarding page follows the same five-zone skeleton (§0.9).

```
┌──────────────────────────────────────────────┐
│  [status bar — OS]                           │
│                                              │
│  [LOGO]  OPENSPACE          PG.02 / 05  SKIP │  ← page chrome
│          AI ASSISTANCE                       │
│                                              │
│  ● MODEL WORKSPACE                    AI–02  │  ← route + code
│                                              │
│  Ask questions, write, and                   │  ← display headline
│  explore ideas with AI models                │
│                                              │
│  OpenSpace turns prompts into a focused      │  ← sub-paragraph
│  working surface for drafting, refactoring,  │
│  research, and interface decisions.          │
│                                              │
│  ┌────────────────────────────────────────┐  │  ← module mock card
│  │ ●●●  MODEL STUDIO   AGENTS / … / REVIEW│  │
│  │                                        │  │
│  │  [ ASK ] [ WRITE ] [ EXPLORE ]         │  │
│  │                                        │  │
│  │  ┌──────────────────────────────────┐  │  │
│  │  │ > How should I structure the…    │  │  │
│  │  │   ━━━━━━━━━━━━━━━━━━━━━━━━━━━    │  │  │
│  │  │   ━━━━━━━━━━━━━━━━━━━            │  │  │
│  │  │   ━━━━━━━━━━━━━━                 │  │  │
│  │  └──────────────────────────────────┘  │  │
│  │                                        │  │
│  │  [▣ DESIGN CANVAS] [✦ AI ASSISTANCE]   │  │
│  │   Native cards     Structured sessions │  │
│  └────────────────────────────────────────┘  │
│                                              │
│   · · ▬ · ·                                  │  ← paginator
│                                              │
│  [ ← BACK ]    [ CONTINUE → ]                │  ← action bar
└──────────────────────────────────────────────┘
```

### Per-page configuration

| Page | Route chip | Code badge | Headline | Widget | Chip pair |
|---|---|---|---|---|---|
| 02 | `● ✦ MODEL WORKSPACE` | `AI–02` | Ask questions, write, and explore ideas with AI models | §6.1 Segmented + Prompt | DESIGN CANVAS · AI ASSISTANCE |
| 03 | `● ☰ QUEUE CONTROL` | `RUN–03` | Queue follow-up prompts while a turn is still running | §6.2 Queue List + Add bar | STATE ENGINE · RUN STEERING |
| 04 | `● ☰ REASONING DIAL` | `THK–04` | Reasoning controls to tune how much thinking AI model uses | §6.3 Dial + Slider + Bars | MODEL CONTROLS · HUMAN STEERING |

Pages 01 and 05 follow the same template; their widget content is open (see §11 Open Questions).

---

## 8. Touch & Accessibility

- **Minimum tap target**: 44 × 44 pt. Never scale below this even when `scale < 1`.
- **Hit areas** can extend beyond visible bounds via `.contentShape(Rectangle())` when a visible element is smaller than 44pt.
- **VoiceOver labels**: every interactive element (route chip, segmented control, slider, icon-tile chip, action buttons) has an explicit `accessibilityLabel`. Mono codes (`AI–02`) read as "A I oh two" not "A I dash zero two" — provide a custom accessibility label.
- **VoiceOver order**: chrome → route + code → headline → sub → module (header → widget → chip pair) → paginator → action bar.
- **Reduce Motion**: see §0.7. On iOS, gate animations behind `UIAccessibility.isReduceMotionEnabled` or SwiftUI's `accessibilityReduceMotion` environment.
- **Increase Contrast**: when `legibilityWeight == .bold` (Increase Contrast on iOS), bump body weight from 400 to 500 and add `border/strong` to inactive segments.

---

## 9. Performance Notes

- The diagonal hatch should be rendered once per theme into a cached `Image` and tiled, not redrawn every frame.
- The module mock card content is animated; gate the staggered float-up to **first appearance only** (`onAppear` with a state flag), not on every recompose.
- Avoid `GeometryReader` nesting beyond two levels. Compute `scale` once at the page root and pass it down.

---

## 10. Implementation Checklist (when build pass begins)

1. Token layer — translate §0.2–0.5 into a `Theme` struct + asset catalog with light/dark variants.
2. Scaling layer — implement `GeometryReader`-driven `scale`, `isCompactHeight`, `typeScaleMultiplier`, and the helper extensions in §2.
3. Primitive components — page chrome, route chip, code badge, icon-tile chip, action buttons, paginator, segmented control, slider, ring readout, bar histogram.
4. Module mock card — outer container + header row + chip pair footer.
5. Page templates — implement PG.02, PG.03, PG.04 verbatim against the reference screenshots.
6. Motion — apply staggered float-up on first appearance only, segmented swap on selection.
7. Visual QA — compare each page at 100% zoom on a 375pt artboard, then sweep all device sizes from iPhone SE → iPad Pro 12.9" landscape, in both light and dark.

---

---

## 11. Open Questions

Unresolved and need a design pass before implementation:

- **Page 01** of onboarding — entry page composition.
- **Page 05** of onboarding — closing recap composition.
- **Empty/error states** for the queue list, prompt block, and reasoning dial.
- **Localization line-length rules** — headlines tuned to English; Indonesian and other locales need a test pass before the 2-line headline rule is locked.
- **Theme-switch animation** — current spec is instant. Open whether to add a 180ms crossfade.

---

*End of mobile guide.*
