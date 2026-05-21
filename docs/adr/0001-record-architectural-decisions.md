# 0001. Record architectural decisions

- Status: Accepted
- Date: 2026-05-21

## Context

OpenSpace is in its earliest phase. Architectural choices made now —
state-management library, persistence stack, deployment target, testing
framework — will shape the codebase for a long time. Without a record,
those choices erode into "tribal knowledge" that is rediscovered, and
sometimes reversed, by future contributors who lack the original
reasoning.

The repository will be worked on by a mix of human contributors and AI
coding agents. AI coding agents in particular benefit from explicit,
machine-readable rationale because they have no continuity of memory
across sessions.

## Decision

We record significant architectural decisions as Architectural Decision
Records (ADRs) following the format introduced by Michael Nygard, kept
lightweight: Context, Decision, Consequences, Alternatives considered.

System-wide ADRs live at `docs/adr/`. Feature-scoped and cross-cutting
Client ADRs live alongside their respective contexts in
`OpenSpace/OpenSpace/Features/<Feature>/docs/adr/` and
`OpenSpace/OpenSpace/Shared/docs/adr/` — consistent with the
multi-context layout described in `CONTEXT-MAP.md`.

The full process — when to write one, when to update one, status
values, file naming — is documented in
[`docs/adr/README.md`](README.md).

## Consequences

What gets easier:

- A new contributor can understand the *why* of a non-obvious choice
  without archaeology through pull requests.
- Reversing a decision is structured: write a new ADR with `Supersedes`
  and flip the old one's status. The thread of reasoning is preserved.
- Reviews can call out missing ADRs ("this changes our persistence
  story without an ADR") as a concrete, actionable comment.

What gets harder:

- A small overhead per non-obvious decision: drafting the ADR.
- Discipline is required to keep ADRs current. A stale ADR is worse
  than none because it misleads.

What we accept:

- ADRs are not a substitute for code documentation. Inline docs
  explain *what* the code does; ADRs explain *why* it was chosen.
- Some decisions will be made informally and only retroactively
  recorded. That is acceptable as long as the record lands before the
  decision becomes load-bearing.

## Alternatives considered

- **No formal record.** The default. Rejected because the project
  expects multi-session AI coding agent contributions, where lack of
  written rationale is especially harmful.
- **Inline comments only.** Comments answer "what" well but not
  "why we did not do X instead". Rejected for non-obvious decisions.
- **A single `DECISIONS.md` log.** Workable for small projects but
  collapses under merge conflicts and offers no per-decision URL.
  Rejected.
