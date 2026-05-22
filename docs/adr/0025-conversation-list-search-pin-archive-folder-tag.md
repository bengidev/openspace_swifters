# 0025. Conversation list: search plus pin (max 5) plus archive plus folder plus tag (max 10); compound AND filter

- Status: Accepted
- Date: 2026-05-22

## Context

The Conversation list is the app's primary navigation surface. Once
a power user has accumulated dozens or hundreds of Conversations,
the bare chronological list collapses under its own weight: finding
a months-old thread on a niche topic becomes painful, and high-
value threads get buried under one-off questions.

A plain "search by title and content" bar covers part of this, but
not all. Users separately want:

- A small set of always-on-top threads (the recurring projects,
  the daily-driver assistants).
- A way to reduce visual noise from threads that are done but
  worth keeping.
- Coarse grouping by domain ("work", "personal", "research").
- Fine-grained labelling that crosses domains ("travel", "swift",
  "draft").

These are well-known organisation primitives but not all of them
need to exist, and the combination matters as much as the parts.
Pin without archive is half a system; folder plus tag without a
filter to combine them is decoration. The decision must answer:

- What organisation primitives ship in v1?
- What are their limits, if any?
- How do they compose in the filter bar?
- How does this interact with persistence (ADR-0017) and the
  cross-cutting Search Client?

## Decision

The v1 Conversation list ships **five organisation primitives**:

1. **Search.** Free-text search across Conversation title and
   message content. Implemented over the SwiftData store with the
   indexes declared in the persistence schema (ADR-0017). Result
   ordering is recency by default, with relevance ranking deferred
   to a later ADR.
2. **Pin.** Up to **five** Conversations may be pinned. Pinned
   Conversations render in a dedicated section at the top of the
   list, ordered by pin time descending. The five-cap is enforced
   in the reducer; attempting to pin a sixth opens a small chooser
   to displace one. The cap protects the section from becoming a
   second list.
3. **Archive.** A binary `archived: Bool` flag per Conversation.
   Archived Conversations are excluded from the default list and
   appear in a dedicated "Archived" view (and in search results
   regardless of archive status). Archive is reversible from the
   archived view.
4. **Folder.** Each Conversation belongs to **at most one** folder.
   Folders are user-created, named, and ordered. Conversations
   without a folder live in a default "Inbox" pseudo-folder that
   is implicit, not persisted as an entity. Folders themselves
   are persisted entities with a stable identifier.
5. **Tag.** Each Conversation may carry up to **ten** tags.
   Tags are user-created, lowercase by default (display-cased),
   and shared across Conversations. The ten-cap protects against
   tag explosion on a single thread; the global tag namespace is
   uncapped in v1 (revisitable).

The list's filter bar composes these primitives with a **compound
AND** rule: a Conversation appears when it satisfies every active
filter facet. The facets the bar exposes are folder selection,
tag chips (multi-select; AND across selected tags), archive
toggle, and the search query. There is no OR-mode in v1; users
who want OR semantics use the search bar with the relevant terms
or browse facets one at a time.

Pin is **orthogonal** to filters: pinned Conversations honour the
active filters too (a pinned Conversation in folder Foo does not
appear when filtering by folder Bar). Pinning is a presentation
hint, not an override of the filter set.

Persistence shape:

- `pinned: Bool` and `pinnedAt: Date?` on the Conversation entity;
  the cap is enforced at write time by the reducer.
- `archived: Bool` and `archivedAt: Date?` on the Conversation
  entity.
- `folderID: UUID?` on the Conversation entity, referencing a
  `FolderEntity` with `id`, `name`, `sortOrder`, `createdAt`.
- A many-to-many relationship between Conversation and `TagEntity`
  (`id`, `name`, `createdAt`), with the per-Conversation cap of
  ten enforced at the reducer layer.

These shapes extend the v1 schema declared in ADR-0017 and are
covered by the same `VersionedSchema` flow.

The list reducer follows the Container/Flow split: a
`ConversationListContainer` owns the persisted facets (folders,
tags, pin set) and a `ConversationListFlow` per-screen state owns
the current filter selection, search text, and result ordering.

## Consequences

What gets easier:

- Power users get a coherent organisation toolkit out of v1 without
  any one feature being half-built.
- Filter semantics are predictable: "everything I check must
  apply", not "any of the things I check might apply".
- The persistence shape is small and standard. Folder and tag
  entities give us hooks for future surfaces (e.g. a tag-cloud
  view) without rework.
- Reducer logic for pin/archive is local and well-tested; the
  caps are enforced in one place rather than at every mutation
  site.

What gets harder:

- Five primitives is more surface than the bare list. The empty-
  state UX must teach the primitives without becoming a tutorial.
- Compound AND is sometimes the wrong default. A user filtering
  by two tags expecting OR sees an empty list and must re-learn
  the model. We mitigate by labelling the chip behaviour
  explicitly.
- Tag and folder management requires its own management surface
  (rename, delete, merge). v1 ships a minimal CRUD surface;
  power features (bulk re-tag, folder colours) are deferred.
- Search ranking is recency-only in v1. Relevance ranking is a
  larger problem that touches indexing strategy and is out of
  scope here.

What we accept:

- The pin cap of 5 and tag cap of 10 are judgement calls. We
  prefer hard caps with a clear UX (displace a pin, drop a tag)
  to soft caps that erode over time.
- Folders are single-membership; a Conversation cannot be in two
  folders at once. Users who want overlap use tags. This trade-
  off is deliberate and matches familiar mental models.
- The "Inbox" pseudo-folder is implicit. Persisting it as a real
  entity would create a default-content migration question on
  every install for no user benefit.
- OR-mode and saved searches are not in v1. They are tracked as
  follow-ups, gated by usage signal.

## Alternatives considered

- **List + search only.** Rejected. The high-value organisation
  primitives (pin, archive) are cheap to ship and absent only
  out of false simplicity; users open dozens of threads.
- **Folders without tags.** Rejected. Single-membership folders
  cannot model cross-cutting attributes ("draft", "swift") that
  span domains; tags are the cheap fix.
- **Tags without folders.** Rejected. Tag-only systems do not
  give users a top-level mental container; folders provide the
  coarse grouping that maps to projects/contexts.
- **Unbounded pins / unbounded tags-per-thread.** Rejected. Both
  caps protect a UI affordance from degrading; soft caps with
  warnings train users to ignore the warning.
- **OR-mode by default in the filter bar.** Rejected. OR is the
  weaker constraint and tends to render the filter bar useless
  on large datasets; AND is the safer default and matches
  spreadsheet/finder conventions.
- **Multi-folder membership.** Rejected. Doubles the persistence
  shape (join table for what should be a single FK) and the
  conceptual surface; tags already cover the use case.
- **Smart folders / saved searches.** Deferred. Worth doing once
  the shape of search ranking and filter usage is observable;
  shipping it in v1 commits us to syntax we may not want to
  carry.
- **Archive as a tag.** Rejected. Archive has different list-
  visibility semantics (default-excluded) and warrants its own
  flag; collapsing it into a reserved tag adds a special case to
  the tag system.
