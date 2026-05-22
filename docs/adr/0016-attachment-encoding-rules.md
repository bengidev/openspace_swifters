# 0016. Attachment encoding: per-vendor normalisation with PDFKit text extraction for OpenAI

- Status: Accepted
- Date: 2026-05-22

## Context

Vendors disagree on attachment wire formats. ADR-0014 surfaces a
single product affordance per modality; ADR-0015 stores the bytes
once. The bridge between "user dropped a file" and "model received a
content block" is encoding, and it is not symmetric:

- **Audio.** Anthropic Messages accept `audio/wav` and `audio/mp3`
  but not `audio/mp4` (m4a). OpenAI-compatible audio support varies
  by model and endpoint; some accept m4a, some do not.
- **Image.** Most v1 models accept JPEG and PNG. Maximum dimensions,
  size caps, and base64 size limits differ. HEIC arrives commonly
  from iOS photos and is rarely accepted as-is.
- **PDF.** Anthropic accepts native PDF blocks on supported models.
  OpenAI direct does *not* accept PDF as an input modality on the
  chat completions endpoint at v1. OpenRouter's PDF support depends
  on the upstream model.

A separate concern is **when** to encode. Encoding at attach time
means the user's chosen model is not yet known at full fidelity;
encoding at submit time means the audit hash (ADR-0015) corresponds
to bytes the user never saw a confirmation for. The two have
different failure modes — early encoding wastes work on attachments
that get removed; late encoding races against rapid-submit users.

## Decision

Encoding runs at **submit time, after the composer's compose-time
capability gate (ADR-0014) has passed**. The submit path is
synchronous from the user's perspective: encode, hash, persist
(ADR-0015), call provider. Encoding rules are per modality and per
vendor dialect.

### Audio

- **m4a to wav at submit.** When the active dialect cannot accept
  the recorded m4a (Anthropic always; OpenAI-compatible
  conditionally), the encoder transcodes m4a to PCM wav before
  hashing. The transcode uses `AVAssetExportSession` with the
  `AVAssetExportPresetPassthrough` family where possible and a wav
  preset otherwise; we do not invent codec parameters.
- The encoded wav is the persisted payload (ADR-0015's `data`); the
  m4a's hash is recorded as `sourceSha256`.
- Vendors that accept m4a natively skip the transcode; the hash
  pair collapses (`sourceSha256` is `nil`).

### Image

- **Normalise-at-encode per vendor.** A single normaliser computes
  the target format and dimensions from the active vendor's
  per-modality limits (curated table; ADR-0014):
    - HEIC, HEIF, and other non-mainstream formats convert to JPEG.
    - Images exceeding the vendor's max dimension downsample with
      `vImage` / `CGImage` to the largest supported dimension that
      preserves aspect ratio.
    - Images exceeding a vendor's byte cap recompress at decreasing
      quality steps until the cap is met or quality 0.6 is reached;
      if the cap is still exceeded the encoder fails with a
      structured error that the composer surfaces (the user is
      asked to choose a smaller image).
- Native JPEG and PNG within limits pass through unchanged.
- The normalised bytes are persisted; the original's hash, mime, and
  byte count populate the source provenance fields.

### PDF

- **Preflight at attach.** Page count, page sizes, and password
  protection are inspected via PDFKit when the user attaches the
  file. Locked or zero-page PDFs are rejected at attach time with a
  composer-level explanation.
- **Native PDF block on Anthropic.** When the dialect is Anthropic
  and the model's capability entry includes `pdf`, the bytes pass
  through to a `document` content block; the persisted payload is
  the original PDF.
- **OpenAI PDF via local PDFKit text extraction.** When the dialect
  is OpenAI-compatible (OpenAI direct, or OpenRouter routing to an
  OpenAI-compatible model whose capability entry does not include
  native `pdf`), the encoder runs PDFKit text extraction on device
  and submits the extracted text as a labelled text content part
  (`[document: <filename>] <extracted text>`). The persisted payload
  is the **extracted text**, encoded as UTF-8; `sourceSha256`
  records the original PDF's hash. The user sees a one-line note in
  the composer that the PDF was sent as extracted text.
- A PDF whose extraction yields no text (image-only scans without
  OCR) fails with a structured error pointing the user at OCR
  workflows that are out of v1 scope.

### Hashing and audit

- The hash recorded in `MessageAttachmentEntity.sha256` (ADR-0015)
  is over the bytes the encoder produced — the wav, the normalised
  image, the original PDF for Anthropic, or the extracted UTF-8
  text for OpenAI.
- The audit log entry the Live Provider writes (ADR-0009) references
  the post-encode hash. Reproducibility refers to "what was sent",
  not "what the user originally selected".

### Failure surface

- Encoder failures bubble up as structured errors, not exceptions.
  The composer disables submit and shows a one-line message
  identifying which attachment failed and why.
- Partial submits are forbidden: an encoder failure on attachment N
  cancels the whole submit; the user sees nothing half-sent.

## Consequences

What gets easier:

- The Live Providers receive content in formats they accept by
  construction. No vendor-specific exception paths inside the
  request builder.
- Reproducibility is honest: the persisted bytes are the wire
  bytes, and the hash chain (`sourceSha256` → `sha256`) preserves
  provenance for diagnostics.
- The composer's preflight (PDF) catches the largest class of
  user-fixable errors at attach time, when fixing is cheap.

What gets harder:

- Adding a new vendor dialect requires populating its image limits,
  its accepted audio formats, and its PDF stance in the capability
  table. The encoder is one switch keyed by dialect.
- Extracted-text PDFs lose visual layout. Tables, forms, and
  figure-heavy documents will look different to the model than they
  do to the user. We will document this clearly in the composer's
  one-line note.
- Audio transcoding takes wall-clock time on long recordings. The
  composer surfaces a progress affordance during submit; cancelling
  a submit cancels the encode.

What we accept:

- Lossy image recompression is a feature, not a bug — the
  alternative is rejecting the attachment outright on a vendor's
  byte cap. Users who care about pixel-perfect images will use
  vendors with higher caps.
- "PDF support" means different things across vendors. The composer
  hides this by offering one PDF affordance; the encoder's behaviour
  is the asymmetry that ADR-0014 promised we would accept.

## Alternatives considered

- **Encode at attach time.** Rejected. The user changes their mind
  often during compose; encoding wastes CPU and time on attachments
  that get removed. Encoding is also dialect-aware, and the dialect
  is the active `ProviderConfig`'s vendor at submit, not at attach.
- **Server-side transcoding / extraction proxy.** Rejected. Conflicts
  with the BYOK / local-first posture (ADR-0007). Adds infrastructure
  liability for a workflow we can run on device.
- **Reject HEIC at attach with an "export from Photos" message.**
  Rejected. The conversion is fast and well-supported; pushing it
  onto the user is a poor experience.
- **Submit OpenAI PDFs as base64 anyway.** Rejected. The endpoint
  rejects the request; we would surface a vendor error after the
  user has waited. Local extraction succeeds locally, fast, with a
  clear product story.
- **Run on-device OCR for image-only PDFs.** Rejected for v1. Vision-
  framework OCR is feasible but adds a third PDF code path and
  shifts the failure surface from "explain politely and stop" to
  "try OCR, sometimes succeed, sometimes produce nonsense". A
  deliberate later ADR can add it.
- **Per-attachment per-turn override of the encoder.** Rejected. No
  product motivation in v1; the dialect-driven encoder is the
  smaller and more testable surface.
