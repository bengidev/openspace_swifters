# 0015. Attachment storage: SwiftData external storage with SHA-256 hash field

- Status: Accepted
- Date: 2026-05-22

## Context

Multimodal Conversations (ADR-0014) accept image, PDF, and audio
attachments. These payloads are large relative to a chat message:
typical images are hundreds of kilobytes, PDFs reach low single-digit
megabytes, audio recordings can run longer. Storing them inline in the
SwiftData store has two failure modes:

- The store balloons. SwiftData (over Core Data) keeps the SQLite
  store in a single file by default; large blobs slow indexing and
  inflate backup, iCloud, and migration costs.
- Reading the row pulls the blob into memory unnecessarily. List
  views, search, and deletion only need metadata.

A second concern is **deduplication and integrity**. The same
attachment may be referenced by multiple turns within a Conversation
(re-asking about the same screenshot) or across Conversations
(comparing the same PDF against two models). Storing the bytes once
and referencing them by content hash avoids waste; the hash also
gives us a cheap integrity check at read time.

A third concern is the **Provider audit trail** described in
ADR-0009 / ADR-0012 / ADR-0013. The audit log records what the user
sent at request time. If we mutate or re-encode an attachment between
attach and submit (ADR-0016), the audit must reference the version
that actually went on the wire, not an earlier or later one.

## Decision

Attachments persist as a dedicated `MessageAttachmentEntity` whose
binary payload is stored via SwiftData's external-storage attribute,
keyed and identified by a content hash.

Schema shape (the canonical declaration lives in ADR-0017's schema):

```
@Model
final class MessageAttachmentEntity {
    @Attribute(.unique) var id: UUID
    var messageId: UUID                 // owning message
    var kind: AttachmentKind            // image | pdf | audio
    var mimeType: String                // post-encode mime
    var byteCount: Int
    var sha256: String                  // 64 hex chars, post-encode
    var createdAt: Date

    // Original-source provenance (pre-encode; nil if no transform)
    var sourceMimeType: String?
    var sourceByteCount: Int?
    var sourceSha256: String?

    @Attribute(.externalStorage) var data: Data
}
```

Rules:

- **External storage is mandatory** for the `data` blob. SwiftData
  spills it to a sibling file under the store; the row carries only
  the metadata.
- **The `sha256` field is over the bytes that go on the wire**, not
  the user's original file. Encoding (ADR-0016) runs first; the hash
  records what the model actually saw. The Live Provider's audit log
  references this hash.
- **`sourceSha256` (and the matching `sourceMimeType` /
  `sourceByteCount`) is populated when encoding transformed the
  payload** — for example, m4a-to-wav for Anthropic, image
  normalisation, or PDF text extraction. When no transform runs, the
  three source fields are `nil`. The pair `(sha256, sourceSha256?)`
  is enough to reconstruct provenance without re-running the encoder.
- **Deduplication is intra-Conversation only in v1.** Within one
  Conversation, two attachment entities with equal `sha256` may share
  the same external blob through SwiftData's natural row-per-entity
  storage; we do not write a global content-addressed store on top.
  Cross-Conversation dedup is a future ADR if disk pressure proves
  it worthwhile.
- **Integrity check on read.** When the Live Provider loads a payload
  to send, it recomputes `sha256` and compares. A mismatch is a hard
  error reported through the streaming `messageStop` /
  vendor-specific channel; the call does not proceed with corrupted
  bytes.
- **Cascade on message delete.** Deleting a `MessageEntity` deletes
  every `MessageAttachmentEntity` whose `messageId` matches, which in
  turn frees the external blob via SwiftData's lifecycle. We do not
  rely on application-level cleanup.

The Storage Client (ADR-0003) exposes domain operations for
attachments — `save(MessageAttachmentDraft) -> MessageAttachmentEntity`,
`load(id:) -> MessageAttachmentEntity?`, `delete(id:)` — so reducers
never touch SwiftData attachment APIs directly.

## Consequences

What gets easier:

- The store stays compact. List views and search read rows with a
  bounded cost regardless of payload size.
- Audit and reproducibility are straightforward. Given an audit log
  entry, the exact bytes the model saw can be retrieved by hash and
  byte-compared.
- Deletion is automatic. Removing a message cleans up its blobs; we
  do not maintain a parallel garbage collector.
- Hash collisions on real-world payloads are negligible; the
  `(sha256, byteCount)` pair makes accidental confusion vanishingly
  unlikely.

What gets harder:

- Migrations must move both the row and the external blob if we ever
  rename or relocate the attachment entity. ADR-0017's `VersionedSchema`
  posture makes this disciplined; the cost is real but bounded.
- Power users curious about disk usage will see two stores (the
  SQLite file plus the external-storage directory). We will document
  this in user-facing storage explainers when they exist.

What we accept:

- Inter-Conversation duplicates cost extra disk in v1. The product
  surface for managing this (a global "attachments" view) does not
  exist yet; we are not optimising for a workflow we have not built.
- Attachments live on device. iCloud sync, export, and import are
  separate decisions and will get their own ADRs when scoped.

## Alternatives considered

- **Inline blobs on the row.** Rejected. The SwiftData row balloons,
  list-view performance degrades, and migrations rewrite gigabytes
  for a column-rename.
- **Files in the app's Documents directory, with a path string on the
  row.** Rejected. We re-implement what `@Attribute(.externalStorage)`
  already gives us, including lifecycle, atomic writes, and backup
  policy.
- **Content-addressed global blob store.** Rejected for v1. Useful
  for cross-Conversation dedup but adds a separate lifecycle, a
  reference-count discipline, and a custom GC. Worth a future ADR if
  measurements demand it.
- **Hash of the original (pre-encode) bytes only.** Rejected. The
  audit posture (ADR-0009) needs the bytes that actually went on the
  wire; recording only the source hash lets a re-encode go undetected.
- **SHA-1 or MD5 instead of SHA-256.** Rejected. Both are weak; the
  cost of SHA-256 on attachment-sized payloads is irrelevant on
  modern devices, and a strong hash is easier to defend in any future
  security review.
