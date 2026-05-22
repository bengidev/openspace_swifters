# 0028. Markdown rendering: third-party renderer with limited scope and 100 ms throttle

- Status: Accepted
- Date: 2026-05-22

## Context

The Assistant produces Markdown. Users expect headings, lists, code
blocks with monospace font, inline code, bold/italic, and links to
render natively in the chat transcript. The shared streaming type
(ADR-0008) delivers `textDelta` events at vendor cadence; on a fast
model that is dozens of fragments per second.

Three forces apply:

- **Rendering quality.** SwiftUI's `Text(_:)` parses a narrow,
  Apple-defined Markdown subset (`AttributedString` with
  `MarkdownParsingOptions`). Code blocks, fenced syntax, tables,
  and task lists fall outside that subset and render as literal
  characters. A serious chat UI cannot ship without code-block
  support — code is the dominant payload.
- **Streaming cost.** Re-parsing the full assistant message on
  every `textDelta` is quadratic in message length and visibly
  janky on long replies. Throttling parses to a coarse cadence
  preserves liveness without burning the main thread.
- **Dependency posture.** OpenSpace minimises third-party
  dependencies; each one is a future audit, license review, and
  update vector. The render path is one of the few places where
  the dependency cost is plausibly justified, but the renderer
  itself is selected in a follow-up ADR (`Package selection
  deferred`) once shortlist evaluation is done.

## Decision

Markdown rendering uses a **single third-party renderer**, chosen
in a dedicated package-selection ADR at implementation time. This
ADR fixes the *contract* the renderer must satisfy and the
*operational rules* around its use; it does **not** name the
package.

**Scope of supported Markdown — limited subset.**

Supported in v1:

- Inline: bold, italic, inline code, links (rendered with
  underline; tap opens via `OpenURLAction`).
- Block: paragraphs, ATX headings (`#` … `######`), unordered and
  ordered lists with one level of nesting, fenced code blocks
  with a language hint, blockquotes.
- Code blocks render in a monospace stack (`SF Mono`/`Menlo`
  fallback) with horizontal scroll for over-wide lines. Syntax
  highlighting is **out of scope for v1** — code blocks render
  as plain monospace text.

Explicitly out of scope in v1:

- Tables, task lists, footnotes, definition lists, autolinks
  beyond `<scheme://...>`, image embedding (the assistant does
  not return images), HTML pass-through (any inline HTML is
  rendered as escaped text).
- Mermaid, KaTeX, MathJax, or any extension that requires a
  WebView.

**Renderer contract.**

The package selected in the deferred ADR must:

- Be MIT, Apache-2.0, BSD, or comparable permissive license.
- Compile cleanly on iOS 17.6 (ADR-0004) without bridged JS.
- Produce SwiftUI views or `AttributedString` values directly;
  no `WKWebView`-backed rendering.
- Accept partial Markdown without crashing or producing garbage
  output (the streamed buffer mid-message frequently contains
  unclosed fences).

The Live implementation lives behind a small protocol,
`MarkdownRenderer`, in `OpenSpace/OpenSpace/Shared/Markdown/`,
following the Client triplet pattern (Interface/Live/Test).
Reducers and views depend on the Interface; tests use the Test
implementation, which renders deterministic structural output.

**Throttle — 100 ms.**

Re-rendering on every `textDelta` is rejected. Instead:

- The view layer holds a `@State` debounced buffer that updates
  the rendered output at most **once every 100 ms**.
- The buffer flushes immediately when the stream emits
  `messageStop` (ADR-0008) so the final state is never delayed.
- Code blocks render with their unfinished closing fence treated
  as virtually closed during streaming; the heuristic is
  documented in the Live implementation alongside its tests.

**Failure handling.**

- A renderer failure (thrown exception, panic, or output that
  fails a sanity check) falls back to plain `Text` rendering of
  the raw Markdown string. The fallback is logged as a
  `clientWarning` in the telemetry ring buffer (ADR-0026).
- The fallback is per-message, not per-app. One bad message does
  not switch the whole conversation to plain text.

## Consequences

What gets easier:

- The Assistant feature renders the Markdown formats users
  actually produce (paragraphs, lists, code) without us writing a
  parser.
- The 100 ms throttle bounds rendering cost regardless of
  streaming speed; main-thread time stays predictable.
- The Client triplet keeps the renderer behind a seam, so
  swapping packages later is a Live-implementation change, not a
  call-site refactor.

What gets harder:

- The supported subset will leave gaps. Some users will paste
  tables or task lists into a follow-up message and expect them
  to render; we accept that and document the supported set.
- Streaming through a Markdown parser is sensitive to partial
  input. The Live implementation must defensively handle
  unclosed fences, dangling links, and truncated headings.
- Picking the renderer is an unmade decision; a slipping
  package-selection ADR blocks the Markdown-dependent UI work.
  We accept that as a deliberate sequencing choice — the
  evaluation is small and bounded.

What we accept:

- No syntax highlighting in v1. Adding it later is a
  Live-implementation extension and a possible new
  `MarkdownRenderer` capability, not a re-architecture.
- The 100 ms throttle introduces a small perceptible "step" to
  the streaming text. Anything tighter (16 ms / 60 fps) makes
  the renderer the bottleneck on long messages; anything looser
  feels laggy. 100 ms is the empirical sweet spot we'll revisit
  if user reports show otherwise.

## Alternatives considered

- **Hand-rolled Markdown parser.** Rejected. The grammar is
  deceptively gnarly; CommonMark plus the small extensions users
  expect would consume engineering time better spent on the
  Assistant itself.
- **`AttributedString` only.** Rejected. The Apple-supported
  subset omits fenced code blocks and headings, which are the
  two formats whose absence users notice immediately.
- **`WKWebView` rendering with a JS Markdown library.** Rejected.
  Heavyweight, awkward to size to fit content, blocks
  accessibility tooling, and complicates the privacy posture
  (web content process boundary).
- **Render synchronously on every delta.** Rejected. Quadratic
  cost on long replies, jank on the main thread, no path to
  graceful degradation.
- **Pre-pick the renderer in this ADR.** Rejected. The renderer
  shortlist evaluation depends on hands-on prototyping
  (streaming-tolerance behaviour, AttributedString round-trip
  fidelity). Forcing the choice into this ADR couples a strategic
  decision to a tactical evaluation that is best done as its own
  record.
