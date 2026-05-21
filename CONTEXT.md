# OpenSpace — App-Level Glossary

This is the root context in a multi-context repository. Terms here are
cross-cutting; they apply in any feature. Feature-scoped terms live in the
feature's own `CONTEXT.md`. See [`CONTEXT-MAP.md`](CONTEXT-MAP.md) for the
full index.

Glossary entries are intentionally short. If a concept needs more than a
paragraph, it belongs in [`docs/architecture.md`](docs/architecture.md) or
an ADR under [`docs/adr/`](docs/adr/).

## Reserved vocabulary

The word **Agent** is reserved for AI coding agents that contribute to this
repository (see [`AGENTS.md`](AGENTS.md)). The user-facing AI helper inside
OpenSpace is the **Assistant**.

## Glossary

**Assistant.** The user-facing AI helper inside OpenSpace. The Assistant
holds the Conversation, replies in turns, and may invoke Capabilities.

**Capability.** A discrete action the Assistant can perform on the user's
behalf — sending a message, drafting a document, summarising a webpage.
Capabilities are declared in code and gated by user consent.

**Conversation.** An ordered sequence of Turns between the user and the
Assistant. Conversations are persisted locally and are the primary unit of
history.

**Turn.** A single round-trip in a Conversation: a user input plus the
Assistant's response. A Turn may include partial streamed output and one
or more Capability invocations.

**Provider.** The backend model service that produces Assistant replies.
Providers are abstracted behind a Client (see Architecture); the app does
not depend on any specific vendor.

**Client.** A protocol-with-implementations pattern used for I/O
boundaries. Each Client defines an Interface, a Live implementation that
performs real work, and a Test implementation used in unit tests. See
[`docs/architecture.md`](docs/architecture.md).

**Container Reducer.** The top-level reducer for a feature. It owns
sub-states and routes child actions, but does not perform business logic.

**Flow Reducer.** A scoped reducer inside a feature that owns a single
flow's state machine (e.g. an onboarding sequence). Composed under the
Container Reducer.

**Composition Root.** The single place in the app target where Clients,
reducers, and the SwiftData container are wired together — typically the
`App` type's initialiser.

**Progress Entity.** A persisted SwiftData model that records whether the
user has completed a one-time flow (such as Onboarding). Used to gate
navigation on launch.

## Anti-vocabulary

Avoid the words on the left when committing code, comments, commit
messages, or docs. Use the canonical term on the right.

| Avoid                       | Use instead         | Why                                                                  |
| --------------------------- | ------------------- | -------------------------------------------------------------------- |
| Agent (for the user-facing AI) | Assistant         | "Agent" is reserved for AI coding agents per [`AGENTS.md`](AGENTS.md). |
| Bot, chatbot                | Assistant           | Underestimates the scope; the Assistant invokes Capabilities, not just chat. |
| Skill (in code)             | Capability          | "Skill" collides with the AI coding agent skill system.              |
| Plugin                      | Capability          | Implies dynamic loading we do not support.                           |
| Backend, API                | Provider            | Names the abstraction at the right level.                            |
| Service (for I/O)           | Client              | "Service" is overloaded; "Client" makes the consumer relationship explicit. |
| Session (for chat)          | Conversation        | Reserve "session" for app-process lifecycle.                         |
| Message exchange            | Turn                | "Turn" is the named unit; one Turn may carry many wire messages.     |
