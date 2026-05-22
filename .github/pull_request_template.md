<!--
Pull request template for OpenSpace.

Replace each guidance comment with the actual content. Keep prose
paragraphs for the Summary; bullet lists are appropriate for the
Tests and ADRs sections when several items apply.

Project policies that apply to every PR are recorded in
CONTRIBUTING.md. The most-violated ones to double-check before
requesting review:

- Granular commits, one logical concern per commit.
- Conventional Commit subjects.
- No third-party product names anywhere in the diff.
- No `git push` performed without explicit instruction.
-->

## Summary

<!--
One paragraph naming what changed and why. Frame the change in
product or architectural terms, not as a line-by-line diff.
-->

## Linked issue

<!--
Use the trailer convention from CONTRIBUTING.md so the issue is
linked from the merged commit, not only from the PR description.

- `Refs: #<N>` for partial work on issue N.
- `Closes: #<N>` for a PR that completes issue N.
-->

Closes: #

## Tests

<!--
The tests added or updated by this PR. If the change is process or
configuration work with no test artefact, say so and explain how the
change was validated (CI run, manual verification, schema migration
dry-run, etc.).
-->

## ADRs

<!--
Architectural decisions recorded by this PR. Add a new ADR under
docs/adr/ when the PR locks a decision that future contributors need
to recover from the repo. Reference the ADR number here. If no ADR is
added or updated, write "None" so a reviewer does not have to infer.
-->
