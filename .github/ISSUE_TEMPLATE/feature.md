---
name: Feature / PRD
about: Propose a feature or product change with a prose-first PRD body.
title: "PRD: <short title>"
labels: ["needs-triage"]
assignees: []
---

<!--
This template is the canonical body shape for feature work in OpenSpace.
The structure mirrors docs/agents/issue-tracker.md so that AI coding
agents and human contributors parse the body the same way.

Write each section as prose paragraphs. Keep bullet lists for genuinely
list-shaped content (acceptance criteria, user stories, scoped-out
items). Replace every guidance comment with the actual content.
-->

## Problem Statement

<!--
Describe the problem this issue solves. One or two paragraphs. Frame
the problem in product terms, not solution terms. If the problem is a
follow-up to a previous decision, link the parent issue or ADR here.
-->

## Solution

<!--
Describe the chosen solution at a level that a reviewer can hold in
their head. Capture the shape of the change, not the line-by-line
diff. Reference the locked design decisions or ADRs that the solution
relies on.
-->

## User Stories

<!--
Numbered user stories. Each story names a role and the value the role
gets from this change. Keep stories outcome-focused.
-->

1. As a <role>, I want <capability>, so that <value>.

## Implementation Decisions

<!--
The concrete decisions that turn the Solution into reviewable work.
File paths, module boundaries, type names, configuration keys, default
values. If a decision is deferred to a future ADR, say so explicitly.
-->

## Testing Decisions

<!--
What proves this change correct. Unit tests, UI tests, manual
verification, CI-as-test, schema migrations. If the change is process
or configuration work and has no test artefact, say so and explain how
the change will be validated.
-->

## Out of Scope

<!--
Items that are intentionally not covered by this issue. List them so a
reviewer does not request them and a follow-up author knows where to
pick up.
-->

## Further Notes

<!--
Anything else that does not fit a section above. Migration notes,
follow-up checklist items, references to related work, disclosures.
-->
