# Shared Networking

Canonical home for shared Provider transport code.

- SSE parser: `SSEParser.swift`
- Parsed record type: `SSEEvent`
- Vendor-specific decoding stays in each Provider Live implementation.

Do not create `OpenSpace/OpenSpace/Shared/Internal/SSE/` for the v1 SSE parser; ADR-0029 supersedes that older planning path.
