# 0016. Repository metadata: Contributors copyright, THIRD_PARTY.md, detailed CONTRIBUTING.md, standard badge set, architecture-emphasised tagline

- Status: Accepted
- Date: 2026-05-22

## Context

A public repository carries metadata beyond its source: the
copyright holder in `LICENSE`, a disclosure file for third-party
dependencies, a contributor guide, README badges, and a tagline. In
single-author or single-vendor projects these are afterthoughts.
OpenSpace is positioned as a community-friendly, AI-agent-friendly
codebase whose architecture is its product, so the metadata has to
match that positioning from day one — not be retrofitted before
the first external PR.

The relevant constraints already on the table:

- ADR-0010 commits to BYOK and on-device data handling, which leans
  the licensing posture toward permissive open source.
- AGENTS.md and the `docs/agents/*` skill docs already declare the
  AI-coding-agent contract; CONTRIBUTING.md must consume that, not
  duplicate it.
- The project's naming policy (no third-party project names in
  committed text — see `CONTEXT.md`'s anti-vocabulary) constrains
  both the README copy and the badge labels.

## Decision

The repository's metadata follows four rules:

### 1. Copyright holder is "the OpenSpace Contributors"

`LICENSE` and any per-file copyright header use:

```
Copyright (c) <year> The OpenSpace Contributors
```

Not a single author name, not a corporate entity. Contributions
flow under the project's chosen permissive licence (see `LICENSE`
for the licence body); the holder line credits the collective so
that adding a contributor does not require touching every file.

### 2. THIRD_PARTY.md is the canonical dependency disclosure

`THIRD_PARTY.md` at the repository root lists every third-party
package OpenSpace depends on (vendored, SPM, or transitive surfaced
in the manifest). Each entry records package name, version, source
URL, licence, and a one-line "why" explaining what the dependency
buys us. Adding, upgrading, or removing a dependency requires
updating `THIRD_PARTY.md` in the same change; a manifest-touching
PR without the corresponding update is sent back at review.

### 3. CONTRIBUTING.md is detailed, not minimal

`CONTRIBUTING.md` is the source of truth for branching, commits,
naming, review, and project policy. It is comprehensive enough to
onboard a new human contributor or AI coding agent without a
side-channel conversation, and it explicitly references:

- the Code of Conduct,
- the issue-tracker workflow (`docs/agents/issue-tracker.md`),
- the triage label vocabulary (`docs/agents/triage-labels.md`),
- the granular-commit policy,
- the dependency disclosure rule above,
- the branch-naming convention (`feat/issue-N-slug`),
- the no-direct-push-to-master rule,
- the third-party-name policy from `CONTEXT.md`.

Any deviation from CONTRIBUTING.md in review (e.g. an exception to
granular commits) is recorded in the PR description, not in side
channels.

### 4. README ships the standard badge set and an architecture-emphasised tagline

The README header carries badges in a fixed order:

1. Build status (GitHub Actions, the workflow from ADR-0031).
2. Latest release (or "pre-release" until v1 ships).
3. Licence.
4. Minimum iOS deployment (`iOS 17.6+`, per ADR-0004).
5. Swift toolchain (`Swift 6` once strict concurrency is enabled).

Badges link to their canonical source. None reference third-party
analytics or tracking endpoints.

The tagline below the badges describes the project by its
**architecture posture**, not by its feature list or by comparison
to peer products. Concretely it emphasises:

- native iOS (SwiftUI / SwiftData / TCA),
- provider-agnostic via a thin Client abstraction,
- local-first persistence,
- BYOK with on-device credentials.

It does **not** name peer or competitor products. The naming policy
applies to the README copy as much as to source comments.

## Consequences

What gets easier:

- A single source of truth for each metadata concern. New
  contributors and agents know where to look (`LICENSE`,
  `THIRD_PARTY.md`, `CONTRIBUTING.md`, README badges).
- Adding a contributor does not require a global file edit; the
  copyright line already covers them.
- The dependency-update workflow has one extra mandatory file edit
  but a clear one, enforceable at review.

What gets harder:

- The "no peer-product names" rule constrains README copy and
  badge labels. We accept slightly drier copy for consistency with
  the in-repo naming policy.
- Detailed CONTRIBUTING.md is more text to keep current. We treat
  CONTRIBUTING.md as a living document and review it on every
  policy-touching PR.
- The badge set is standard but the runtime constraints (Build,
  Release, Licence, iOS, Swift) couple the README to CI and
  release plumbing. A workflow rename or release-tagging change
  has to update the badge URLs as well.

What we accept:

- The collective copyright line is unconventional outside community
  open source, but it is the right shape for a repository that
  expects external PRs and AI-agent contributions.
- THIRD_PARTY.md duplicates information that lives in package
  manifests. The duplication is the feature: licences and "why"
  are not in the manifest, and the audit story benefits from one
  human-readable file.
- The architecture-emphasised tagline is a niche framing. We are
  comfortable being read as an architecture project; that posture
  attracts the contributors we want.

## Alternatives considered

- **Single-author copyright in LICENSE.** Rejected. Forces a
  per-file rewrite each time a new contributor lands; misrepresents
  the contribution model the project is moving toward.
- **THIRD_PARTY.md generated from the manifest.** Rejected for v1.
  Generation strips the "why" column and the licence body, which
  are the parts that justify the file's existence. Re-openable
  with a generator that preserves these fields.
- **Minimal CONTRIBUTING.md ("see AGENTS.md").** Rejected. Pushes
  human contributors through an agent-shaped doc and leaves
  branching, commit, and review policy implicit. CONTRIBUTING is
  the right home for human-oriented policy; AGENTS.md and
  `docs/agents/*` remain authoritative for agent-specific
  workflows.
- **Tagline-by-features ("an AI assistant for iOS").** Rejected.
  The product line lives in the README body and the roadmap; the
  tagline's job is to declare the technical posture so the right
  contributors self-select.
- **Tagline-by-comparison ("a peer to App X / App Y").** Rejected
  outright by the naming policy in `CONTEXT.md`.
- **No badges / minimalist README.** Rejected. Badges are a
  density-of-signal device; their absence reads as either neglect
  or anti-marketing posture, neither of which we want.
