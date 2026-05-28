# Context Map

OpenSpace uses a multi-context layout. This file is the index of every
glossary in the repository. Skills and contributors should start here, then
follow the link to the context relevant to the topic at hand.

## Active contexts

| Context        | Glossary                                                       | Scope                                                                          |
| -------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| App (root)     | [`CONTEXT.md`](CONTEXT.md)                                     | Cross-cutting product vocabulary used in any feature: Assistant, Provider, etc. |
| Onboarding     | [`OpenSpace/OpenSpace/Features/Onboarding/CONTEXT.md`](OpenSpace/OpenSpace/Features/Onboarding/CONTEXT.md) | Onboarding flow, progress gating, persisted entities. |
| Shared         | [`OpenSpace/OpenSpace/Shared/CONTEXT.md`](OpenSpace/OpenSpace/Shared/CONTEXT.md) | Cross-cutting Clients, Provider transport, SSE parser placement. |

## How to add a new context

When a feature module materialises under
`OpenSpace/OpenSpace/Features/<Feature>/`, register it in the table above
and create a feature-scoped `CONTEXT.md`. The glossary in that file should
only contain terms unique to that feature; cross-cutting terms stay in the
root [`CONTEXT.md`](CONTEXT.md).

Example future entries (commented for reference):

<!--
| Conversation   | OpenSpace/OpenSpace/Features/Conversation/CONTEXT.md   | Chat surface, message lifecycle, streaming state.     |
| Shared/Client  | OpenSpace/OpenSpace/Shared/CONTEXT.md                  | Cross-cutting Clients (Provider, Storage, Telemetry). |
-->

## Reading rules

- Always start at the root [`CONTEXT.md`](CONTEXT.md) for App-level terms.
- Open the feature-scoped glossary only for that feature's vocabulary.
- If a term appears in multiple feature glossaries with different
  meanings, that is a smell — promote it to the root or rename one.
- See [`docs/agents/domain.md`](docs/agents/domain.md) for the consumer
  rules an agent follows when reading these files.

## ADR locations

System-wide architectural decisions live at [`docs/adr/`](docs/adr/).
Feature-scoped decisions, when introduced, live at
`OpenSpace/OpenSpace/Features/<Feature>/docs/adr/` and cross-cutting
client decisions at `OpenSpace/OpenSpace/Shared/docs/adr/`. System-wide
Provider transport decisions currently include ADR-0029, which names the
canonical SSE parser file as `OpenSpace/OpenSpace/Shared/Networking/SSEParser.swift`.
