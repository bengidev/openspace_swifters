# 0014. Localization: String Catalog scaffolding; ship English only in v1; community translations post-v1

- Status: Accepted
- Date: 2026-05-22

## Context

OpenSpace targets a global audience eventually but a single-author
foundation phase now. Localization is cheap to plan for and expensive
to retrofit: every user-visible string that bypasses the catalog
becomes a future migration task, and every locale we ship in v1 we
must keep in sync forever.

Apple's modern answer is the **String Catalog** (`.xcstrings`),
introduced with Xcode 15. It supersedes `Localizable.strings` /
`.stringsdict`, generates entries from `String(localized:)` call
sites, supports pluralisation and variants, and round-trips through
`xcloc` for translators. Adopting it on day one costs nothing
beyond using `String(localized:)` in code; deferring it forces a
later sweep through every literal.

The product also has a vocabulary problem. Domain terms (`Conversation`,
`ProviderConfig`, `Capability`, see `CONTEXT.md`) are intentionally
English to keep the codebase, ADRs, GitHub Issues, and PR review
in one register. Translating those terms inside the app risks
drifting from the canonical vocabulary the architecture documents
rely on.

## Decision

OpenSpace ships **English (en) only** in v1.

Concretely:

- The Xcode project includes a single `Localizable.xcstrings` String
  Catalog with `en` as the development language. No additional
  locales are added in v1.
- All user-visible strings go through `String(localized:)` (or
  `LocalizedStringKey` in SwiftUI) from the first feature slice. No
  string literal reaches the UI without flowing through the catalog.
- The catalog is **scaffolded but unfilled** for non-English locales.
  No placeholder translations, no machine-translated stubs.
- Translations are accepted **post-v1, community-driven**, via pull
  request. `CONTRIBUTING.md` documents the workflow when the policy
  opens; until then, translation PRs are politely declined with a
  pointer to the roadmap.
- **Domain vocabulary stays English** even when locales are added.
  Terms that appear in `CONTEXT.md`, ADRs, and developer-facing
  diagnostics (`Conversation`, `ProviderConfig`, `Capability`,
  `Tool`, etc.) are not translated. Translators may localise the
  surrounding sentence; the term itself remains English so the
  app, the codebase, and the documentation share one ontology.

## Consequences

What gets easier:

- The v1 release is one locale. No translator coordination, no
  per-locale QA, no string-freeze choreography.
- Adopting `String(localized:)` from day one means any future locale
  is purely additive: open the catalog, fill the column, ship.
- Keeping domain vocabulary English avoids the cross-document drift
  that plagues localised technical products (the docs say
  `ProviderConfig`; the German UI says something else; new
  contributors hunt for the link).

What gets harder:

- Non-English users see English UI in v1. We will be explicit about
  this in store metadata and release notes.
- Some translators will object to the "domain terms stay English"
  rule. We document the reason (architecture-vocabulary parity) so
  the policy can be defended consistently in code review.
- Phase 6 hardening will need a sweep to confirm no string literal
  slipped past the catalog. Linting can catch most of these; the
  remainder is a manual audit.

What we accept:

- The "English only at launch" choice is a product-readiness
  decision, not a stance on accessibility. Localisation is on the
  roadmap; it is not on the v1 critical path.
- Community translations have variable quality. We will gate them
  behind a maintainer review with a translation-quality checklist
  rather than auto-merging.
- A future locale that genuinely needs to translate a domain term
  (because the English term is offensive or unintelligible in that
  language) opens a fresh ADR; the rule is a default, not a
  prohibition.

## Alternatives considered

- **Skip the catalog entirely; use raw string literals.** Rejected.
  Forces a later mass migration of every UI string through
  `String(localized:)`. The tooling cost today is zero.
- **Ship English plus one or two flagship locales at v1.** Rejected.
  Doubles or triples the release-readiness surface for a foundation
  phase whose goal is to prove the architecture, not the localisation
  pipeline. Adds translator-coordination work the project does not
  have capacity for.
- **Translate domain vocabulary per locale.** Rejected as the
  default. Decouples the app from the architecture documents and
  forces every ADR or `CONTEXT.md` reader to mentally back-translate
  to follow the code. Re-openable per term if a locale needs it.
- **Use `Localizable.strings` instead of String Catalog.** Rejected.
  The catalog is the path Apple is investing in; the older format
  is supported but no longer the recommended target for new apps on
  Xcode 16+ and our deployment floor.
