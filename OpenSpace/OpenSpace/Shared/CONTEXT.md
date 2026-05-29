# Shared — Cross-Cutting Client Glossary

This context covers cross-cutting Client infrastructure under
`OpenSpace/OpenSpace/Shared/`. Read this before Shared/Provider work.
App-level product terms stay in the root [`CONTEXT.md`](../../../CONTEXT.md).

## Glossary

**Shared Client.** A Client whose Interface, Live implementation, and Test
implementation are reused across multiple features or Providers.

**Provider transport.** Shared networking code used by Provider Client Live
implementations before vendor-specific decoding. Transport stays vendor-neutral.

**SSE parser.** The internal server-sent events parser used by Provider Client
Live implementations to turn streaming HTTP bytes into `SSEEvent` values. The
canonical parser file is
`OpenSpace/OpenSpace/Shared/Networking/SSEParser.swift`.

**SSE record.** A vendor-neutral parsed SSE frame carrying `event`, `data`, and
optional `id`. Vendor codecs map `data` into Provider-specific payloads and then
into shared stream events.

## Placement decisions

- SSE parser code lives in `OpenSpace/OpenSpace/Shared/Networking/SSEParser.swift`.
- Supporting networking transport types for Provider streaming live alongside it
  in `OpenSpace/OpenSpace/Shared/Networking/` unless a future ADR narrows the
  placement further.
- Older planning language that names `OpenSpace/OpenSpace/Shared/Internal/SSE/`
  is superseded by ADR-0029 and by this context. Do not create that directory
  for the v1 SSE parser.
