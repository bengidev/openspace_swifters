# Contributing to OpenSpace

Thanks for taking the time to contribute. This document is the source of
truth for how changes land in OpenSpace — branching, commits, naming,
review, and the project's hard policies. Both human contributors and AI
coding agents are expected to follow it.

## Code of Conduct

Participation is governed by the [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
By contributing you agree to abide by it.

## Reporting issues

Bugs, feature requests, and product proposals live as GitHub Issues on
`bengidev/openspace_swifters`. Please search before filing to avoid
duplicates. Security reports are an exception — see
[`SECURITY.md`](SECURITY.md) and use the private channel.

For AI coding agents, the issue-tracker workflow (commands, label
conventions, PRD body shape) is documented in
[`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md) and
[`docs/agents/triage-labels.md`](docs/agents/triage-labels.md).

## Filing issues and PRs

GitHub provides templates that pre-fill the structure this project
expects. Use them rather than starting from a blank body.

- **Issues** —
  [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) hosts the bug
  report, feature request, and PRD templates. The picker appears when
  you click _New issue_ on GitHub; pick the template that matches the
  report.
- **Pull requests** —
  [`.github/pull_request_template.md`](.github/pull_request_template.md)
  is applied to every new PR. Fill every section before requesting
  review.

When a commit, PR, or issue references a tracked issue, link them with
the trailer convention documented under
[Trailers link commits to issues](#trailers-link-commits-to-issues):

- `Refs: #<N>` — work that relates to issue N without closing it.
- `Closes: #<N>` — work that resolves issue N when it merges.

## Branching

- The default branch is `master`.
- Work happens on topic branches off `master`.
- Topic branches that close a tracked issue use the form
  `feat/issue-<N>-<slug>`, where `<N>` is the issue number and `<slug>`
  is a short, hyphenated description. Replace `feat` with `fix`, `docs`,
  `refactor`, etc., as appropriate.
- Never push to `master` directly. Open a pull request.

## Commits

### Granular commits — one logical concern per commit

This is a hard project policy. A commit captures one cohesive change with
a clear, reviewable boundary. If a change touches unrelated concerns,
split it into separate commits.

- Stage explicitly: `git add <path>`. Avoid `git add .` and `git add -A`.
- Avoid `--amend` after pushing; prefer follow-up commits.
- Avoid destructive history rewrites (`reset --hard`, `clean -f`, force
  push) unless explicitly requested in review.

### No automatic commit-and-push

Commits land locally first. Wait for an explicit instruction before
running `git push`. AI coding agents must follow this rule strictly: a
session that commits and pushes in a single uninterrupted flow is a
policy violation.

### Conventional Commits

Commit messages follow [Conventional Commits 1.0.0][cc]. The accepted
types are:

| Type       | When to use                                                |
| ---------- | ---------------------------------------------------------- |
| `feat`     | A user-visible feature change                              |
| `fix`      | A bug fix                                                  |
| `docs`     | Documentation only                                         |
| `refactor` | Internal restructure with no behaviour change              |
| `perf`     | Performance improvement                                    |
| `test`     | Adding or restructuring tests                              |
| `build`    | Build system, dependencies, package manifest               |
| `ci`       | Continuous integration configuration                       |
| `chore`    | Repository maintenance that does not fit elsewhere         |

Subject line: imperative, no trailing period, ≤ 72 characters. Optional
scope in parentheses: `feat(onboarding): gate flow on ProgressEntity`.

### Adding a dependency

Adding, upgrading, or removing a third-party package is a single
atomic change that updates both the package manifest and the
disclosure file. Skipping the disclosure step is a policy violation,
not a follow-up task.

Checklist for any dependency change:

- [ ] Update the package manifest (Swift Package Manager via Xcode, or
      a future `Package.swift`) with an exact version or a locked
      range. Avoid open-ended ranges.
- [ ] Update [`THIRD_PARTY.md`](THIRD_PARTY.md) in the **same commit**
      using the entry template documented at the top of that file.
      Keep entries sorted alphabetically by `Name`.
- [ ] Confirm the upstream license is compatible with this project and
      record its SPDX identifier in the entry.
- [ ] Note any new transitive dependencies the change pulls in, if
      they are visible from the manifest resolution.
- [ ] On version upgrades, mention the bump in `CHANGELOG.md` under
      the relevant release.

A pull request that touches the package manifest without a matching
`THIRD_PARTY.md` update will be sent back for revision.

### Trailers link commits to issues

When a commit references a tracked issue, add one of the following
trailers in the message body:

- `Refs: #<N>` — work-in-progress on issue N.
- `Closes: #<N>` — completing the work for issue N.

Example:

```
feat(conversation): stream provider responses into the UI

Wires the Provider client's AsyncSequence output into the Conversation
reducer so partial replies render as they arrive.

Refs: #42
```

[cc]: https://www.conventionalcommits.org/en/v1.0.0/

## Pull requests

A PR description should answer four questions:

1. **What** changed.
2. **Why** it changed (link the issue).
3. **How** it was tested (Xcode unit tests, UI tests, manual verification
   on which simulator).
4. **What is out of scope** for this PR but follows up.

Keep PR titles ≤ 70 characters and use the same Conventional Commit
shape as commit subjects.

## Verification before opening a PR

For changes that touch app code:

- The `OpenSpace` scheme builds for an iOS 17.6 or later simulator.
- Unit tests in `OpenSpaceTests` pass with Swift Testing.
- UI tests in `OpenSpaceUITests` pass when relevant to the change.
- The change does not introduce new compiler warnings.

For docs-only changes, verify cross-links resolve.

## Project policies

These are non-negotiable across human and AI contributions.

### No third-party product names in committed artefacts

Code, comments, commit messages, ADRs, and docs must not name competitor
or reference products — even when those products inspired a design or
were named in chat. Use abstract phrasing instead.

| Avoid                                                | Use instead                                       |
| ---------------------------------------------------- | ------------------------------------------------- |
| "We follow the patterns from `<vendor product>`"     | "We follow patterns from best-in-class peers"     |
| "Inspired by `<competitor app>`"                     | "Inspired by industry-standard mobile assistants" |
| "Like `<chat product>` does"                         | "As is conventional for chat-style assistants"    |
| "We pulled this from the `<starter repo>` template"  | "We adapted this from a structural reference"     |

Legitimate exceptions: license attributions, third-party SDK
documentation, and external links where the product name is the URL.
When in doubt, omit the comparison.

Pre-commit self-check: search the diff for vendor names. If the change
mentions a product to make a point, rephrase to express the point
abstractly.

### Reserved vocabulary

The word "Agent" is reserved for AI coding agents that contribute to
this repository. The user-facing AI helper inside OpenSpace is the
**Assistant**. See [`CONTEXT.md`](CONTEXT.md) for the full glossary and
anti-vocabulary table.

### AI coding agent workflow

AI coding agents operate inside the boundaries set by
[`AGENTS.md`](AGENTS.md) and the playbooks under
[`docs/agents/`](docs/agents/). Those files codify the issue tracker,
triage labels, and domain doc layout. Do not bypass them.

## Verification checklist

Before requesting review:

- [ ] Branch named `<type>/issue-<N>-<slug>` (or comparable for untracked work).
- [ ] Commits are granular and use Conventional Commits.
- [ ] Commit trailers link the relevant issue with `Refs:` or `Closes:`.
- [ ] No third-party product names in the diff.
- [ ] Reserved vocabulary respected.
- [ ] Build, unit tests, and UI tests pass for the affected scheme.
- [ ] Docs cross-links resolve, if docs were touched.
- [ ] No `git push` was performed without explicit instruction.
