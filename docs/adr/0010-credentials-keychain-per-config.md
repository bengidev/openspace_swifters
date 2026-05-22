# 0010. Credentials: one Keychain entry per ProviderConfig UUID; cascade delete

- Status: Accepted
- Date: 2026-05-22

## Context

ADR-0007 commits OpenSpace to Bring-Your-Own-Key for direct vendor
access. ADR-0009 commits to multiple `ProviderConfig` records living
side by side. Each config that targets a real vendor needs its own
secret — an API key, sometimes a header token, occasionally a tuple
(key + organisation id). These secrets must:

- Survive app launches.
- Be invisible to backups and logs.
- Be removable cleanly when the user deletes the config that owns
  them.
- Be unambiguous when several configs use the same vendor (e.g. two
  OpenAI configs with two distinct keys).

The platform answer is the iOS Keychain. The open question is the
shape of the binding between a `ProviderConfig` and its secret.

## Decision

Each `ProviderConfig` owns **exactly one Keychain entry**, keyed by
the config's UUID. Concretely:

- The Keychain item's `kSecAttrAccount` is set to the config UUID
  string. The `kSecAttrService` is a fixed constant
  (`com.openspace.providerCredential`) shared across all configs.
- The accessibility class is
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Credentials are
  not synced via iCloud Keychain.
- The stored payload is a small JSON blob describing the credential
  shape (e.g. `{"apiKey":"…"}`, `{"apiKey":"…","organization":"…"}`).
  The blob shape is versioned so future credential schemes can grow.
- Reading and writing go through a `Credentials` Client triplet under
  `Shared/Credentials/`. Reducers never call Keychain APIs directly.

Lifecycle is **cascade**:

- Creating a `ProviderConfig` does not implicitly write a Keychain
  entry. The user is asked for the secret in the same flow and the
  entry is written before the config is persisted, so a
  successfully-stored `ProviderConfig` always has a credential.
- Editing a config's secret rewrites the Keychain entry under the
  same UUID; the `ProviderConfig` row does not change.
- Deleting a `ProviderConfig` deletes its Keychain entry in the same
  transaction. The `Credentials` Client exposes a `purge(configId:)`
  method called from the Storage Client's delete path; the deletion
  succeeds even if the Keychain entry is already missing
  (idempotent).

If a Live Provider attempts to read a missing credential at request
time (e.g. Keychain corruption, manual deletion via another tool), it
returns `ProviderError.credentialMissing(configId:)` and the
Conversation surfaces a "re-enter your key" prompt without losing
history.

## Consequences

What gets easier:

- The binding `ProviderConfig.id ↔ Keychain.kSecAttrAccount` is
  trivial to reason about: one config, one entry, same UUID. No
  string-mangling key formats.
- Cascade deletion prevents orphaned secrets accumulating in the
  Keychain when the user churns through configs.
- Two configs against the same vendor with two distinct keys are
  unambiguous because the entry is keyed by config UUID, not by
  vendor.
- Tests inject a Test `Credentials` Client backed by a dictionary;
  no Keychain access is required to exercise reducers.

What gets harder:

- The "create config" flow is two-step under the hood (write
  credential, then write config). The Storage / Credentials Clients
  must coordinate so a partial failure leaves no orphan in either
  store. We do this by writing the credential first; if config
  persistence fails, we delete the just-written credential before
  surfacing the error.
- Migrating to a different credential storage backend (e.g. moving
  to a server-side proxy in the future) requires walking every
  config UUID. We accept this; the abstraction at the Client edge
  contains the change.

What we accept:

- Credentials do not roam between devices. iCloud Keychain sync is
  off by design; users with multiple devices re-enter their keys
  per device. The trade-off favours blast-radius containment over
  convenience.
- We never log credential values, never include them in error
  messages, and never serialise them into exports. Diagnostics may
  reference the config UUID but not the key.

## Alternatives considered

- **One global Keychain entry holding all credentials in JSON.**
  Rejected. Forces every read/write to round-trip the whole blob and
  risks subtle concurrency bugs when two configs are edited at once.
- **Per-vendor Keychain entry shared across configs.** Rejected.
  Breaks the multi-config-per-vendor case and forces users with two
  OpenAI accounts to choose only one.
- **Storing credentials in SwiftData with field-level encryption.**
  Rejected. Re-implements a problem the Keychain solves correctly,
  ties credential availability to the SwiftData store's lifecycle,
  and complicates secure-erase.
- **iCloud Keychain sync on by default.** Rejected at this stage.
  Sync expands the blast radius of a single compromised device or
  Apple ID and conflicts with the "device-local secret" posture.
  Revisitable in a later ADR if user demand is consistent.
