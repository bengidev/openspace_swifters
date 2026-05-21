# Security Policy

OpenSpace is an AI assistant that handles user prompts, conversation
history, and credentials for upstream providers. We take vulnerability
reports seriously.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security problems.

Use one of the following private channels:

1. GitHub's private vulnerability reporting on the
   `bengidev/openspace_swifters` repository (Security tab → Report a
   vulnerability).
2. Email the maintainer listed in [`LICENSE`](LICENSE) with the subject
   line `OpenSpace security:` and a clear description.

When reporting, please include:

- A description of the issue and its impact.
- Steps to reproduce, or a proof of concept.
- The iOS version, device, and app build (commit SHA or release tag) you
  observed it on.
- Whether the issue is already public or still embargoed.

## What to expect

- Acknowledgement of receipt within 7 days.
- An initial assessment and severity classification within 14 days.
- Coordinated disclosure: we will agree on a public-disclosure date with
  the reporter, with credit unless anonymity is requested.

## Scope

In scope:

- The OpenSpace iOS application code in this repository.
- The Assistant's interaction with model providers, including credential
  handling and request construction.
- Local persistence of Conversations and user state on the device.
- Any first-party companion targets that may ship in the future
  (extensions, widgets, watchOS app).

Out of scope:

- Vulnerabilities in third-party services the Assistant talks to. Report
  those to the upstream maintainer.
- Issues that require an already-compromised device, jailbreak, or
  physical possession of the device.
- Findings that depend on user-installed malicious tooling.

## Hardening priorities

The areas we treat with the most care during review:

- **Credential storage.** Provider credentials live in the iOS Keychain
  with the most restrictive access policy that still lets the Assistant
  function. They are never written to disk in plaintext.
- **Capability consent.** Capabilities that perform side effects on the
  user's behalf require explicit, audited consent before invocation.
  Consent state is persisted and revocable from inside the app.
- **Local data at rest.** Conversation history persisted by SwiftData is
  protected by the system data-protection class appropriate to the
  sensitivity of the content.
- **Network egress.** All Provider traffic uses TLS via App Transport
  Security; no exceptions are added without documenting them in an ADR.
- **Logs.** Logs intended for debugging redact prompts, model responses,
  and credential values by default.

## Cryptography and dependencies

We prefer Apple-provided cryptographic primitives (`CryptoKit`,
`Security` framework, system Keychain). Third-party cryptography is
introduced only with strong justification and an ADR.

Dependencies are pinned to exact versions or version ranges with a known
floor and reviewed at update time. See [`CONTRIBUTING.md`](CONTRIBUTING.md)
for the contribution process.

## Disclosure

After a fix ships, the vulnerability will be summarised in
[`CHANGELOG.md`](CHANGELOG.md) under the appropriate release with credit
to the reporter (unless anonymity was requested).
