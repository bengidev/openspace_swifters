# 0014. Multimodal v1 scope: text, image, PDF, audio with vendor-asymmetric capabilities

- Status: Accepted
- Date: 2026-05-22

## Context

OpenSpace's v1 vendors (ADR-0007) disagree on what they accept as
input. OpenAI-compatible chat completions take text and image content
parts; their PDF and audio handling varies by model and endpoint.
Anthropic Messages accept text, image, and PDF content blocks
natively, plus audio on a subset of models. OpenRouter forwards a
superset that depends on the upstream model.

A minimal multimodal surface (text plus image only) leaves the user
asking why a feature visible in the model card is not exposed here.
A maximal surface (every modality on every model) lies to the user
when the underlying vendor will reject the call.

Three forces shape the decision:

- **Capability is per-model, not per-vendor.** OpenAI's `gpt-4o`
  accepts images; `o1-mini` does not. Anthropic's `claude-3-5-sonnet`
  accepts PDFs; older Claude variants do not. The matrix is dense and
  changes faster than our release cadence.
- **OpenRouter exposes a `/models` endpoint** with a per-model
  capabilities array (input modalities, max context, etc.). Vendors
  that we hit directly do not; we have to maintain their capabilities
  ourselves.
- **The composer must not let the user attach what the chosen model
  cannot consume.** Catching this at submit time is too late: the user
  has already done the work of selecting and recording the
  attachment.

## Decision

The v1 multimodal scope is **text plus image plus PDF plus audio**,
gated by a per-model capability matrix that is consulted at compose
time.

The capability matrix is a **3-tier resolution** mirroring ADR-0011's
catalog tiers:

1. **Dynamic OpenRouter override.** When the active `ProviderConfig`
   targets OpenRouter, the Live Provider's `/models` response wins.
   Capabilities are extracted from the upstream model entry and cached
   alongside the catalog snapshot.
2. **Curated fallback.** A static, in-repo capability table covers
   every model that appears in the curated catalog (ADR-0011),
   keyed by vendor and model id. This is the source of truth for
   OpenAI direct, Anthropic direct, and OpenRouter models the dynamic
   feed does not annotate.
3. **Free-form override.** When the user types a model id not present
   in either source (the free-form path of ADR-0011), the matrix
   reports `unknown` and the composer falls back to a permissive
   default of "text only" — no attachment surface is offered until the
   user upgrades to a known model.

Per-modality scope in v1:

- **Image.** Accepted on every model whose capability entry includes
  `image`. Encoded per vendor (ADR-0016) before submit.
- **PDF.** Accepted on every model whose capability entry includes
  `pdf`. For OpenAI direct, "PDF support" is a *local* capability:
  the Live Provider extracts text via PDFKit at submit and sends it as
  a text content part (ADR-0016). The user sees a single PDF affordance
  regardless of vendor.
- **Audio.** Accepted on every model whose capability entry includes
  `audio`. Encoded per vendor (m4a to wav for Anthropic, native m4a
  for OpenAI-compatible vendors that support it; ADR-0016).

Compose-time validation is the rule, not the exception:

- The composer receives a resolved `ModelCapabilities` value at
  Conversation creation and on model change. The attachment affordance
  is enabled per-modality from that value.
- A submit-time re-check exists as a safety net (model swapped between
  compose and submit by an external edit), but it is not the primary
  enforcement point.
- Capability mismatches surface as the composer disabling or hiding
  the offending affordance with a one-line explanation, never as a
  silent failure or a runtime exception.

We accept **vendor asymmetry** as part of the contract:

- A user pinning a config (ADR-0009) to a model without image support
  will not see the image affordance at all on that Conversation.
- Switching the default `ProviderConfig` does not retroactively change
  what an existing pinned Conversation can attach.
- The capability matrix is the single source of truth for what the
  composer offers; reducers do not branch on vendor identity.

## Consequences

What gets easier:

- The composer is one piece of UI driven by one value
  (`ModelCapabilities`). No vendor-specific composer code.
- Users see exactly the affordances their chosen model supports — no
  ghost buttons that fail at submit.
- Adding a fourth vendor in a later phase is a matter of populating
  its rows in the curated table plus, if applicable, hooking its
  `/models` equivalent into the dynamic tier.

What gets harder:

- The curated table needs maintenance. Vendor model rosters move; we
  will refresh the table per release cadence and accept some drift in
  between (the dynamic override on OpenRouter mitigates this for
  aggregator users).
- "PDF on OpenAI" and "PDF on Anthropic" mean different things at the
  wire layer (text-extraction versus native PDF block). The product
  surface hides this; the Live implementations carry the asymmetry.

What we accept:

- A model whose vendor adds a new modality between releases will not
  expose that modality until the curated table catches up. This is a
  deliberate freshness / safety trade-off.
- Free-form model ids without curated capability data degrade to
  text-only. The user sees a clear note; they can switch to a curated
  model to unlock attachments.
- Audio support on OpenAI-compatible vendors is narrower than on
  Anthropic at v1; the matrix will report that honestly rather than
  pretend parity.

## Alternatives considered

- **Text plus image only, defer PDF and audio.** Rejected. Both PDF
  and audio are first-class on at least one v1 vendor. Shipping
  without them tells the user OpenSpace is less capable than the
  underlying models.
- **Maximal surface, validate only at submit.** Rejected. The user has
  already invested effort by the time submit fails; the failure mode
  is unkind and erodes trust in the model picker.
- **Vendor-keyed capability switch in the composer.** Rejected.
  Couples UI to vendor identity and breaks the abstraction set up in
  ADR-0006. The matrix keyed by `(vendor, model)` lets us add or
  remove vendors without touching the composer.
- **Skip the curated table; rely on dynamic feeds only.** Rejected.
  OpenAI and Anthropic direct have no equivalent to OpenRouter's
  `/models` capability annotations. Dynamic-only would silently
  degrade direct-vendor users to text-only.
- **Per-vendor sub-modalities (e.g. image-with-OCR vs image-without).**
  Rejected for v1. Adds branches the user does not need. Revisitable
  if a future vendor exposes a meaningfully different sub-modality.
