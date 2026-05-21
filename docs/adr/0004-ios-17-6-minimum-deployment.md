# 0004. Target iOS 17.6 as the minimum deployment

- Status: Accepted
- Date: 2026-05-21

## Context

The deployment target sets a floor on which iOS versions OpenSpace will
run on. It influences:

- Which SwiftUI APIs are available without `if #available` shims.
- Which SwiftData features we can rely on (the framework was introduced
  with iOS 17 and gained refinements in subsequent point releases).
- The size of the addressable installed base.
- The cost of maintaining backwards-compatible code paths.

Lowering the floor too far means writing every feature twice — once
with modern APIs, once with fallbacks — and tying our hands when newer
APIs would simplify the code. Raising it too far excludes users on
slightly older devices and reduces the addressable base unnecessarily.

The relevant constraints for OpenSpace:

- We have committed to SwiftData (ADR-0003) as the persistence layer;
  it requires iOS 17 at minimum, and several of its refinements landed
  in 17.x point releases.
- We have committed to The Composable Architecture (ADR-0002), which
  uses Swift macros and modern concurrency features that are
  best-supported on recent OS releases.
- The product is in pre-release. We are not bound by an existing user
  base whose devices we must support.
- iOS 17.6 was a stable point release with broad device coverage by
  the time this decision was made.

## Decision

OpenSpace targets **iOS 17.6 as the minimum deployment target**.

This is encoded in the Xcode project's `IPHONEOS_DEPLOYMENT_TARGET`
setting and in any future Swift Package manifests added to the
repository.

We commit to:

- Avoiding `if #available` shims for any API present in 17.6 and later.
- Reviewing the floor when SwiftData or TCA introduces a feature gated
  on a higher OS that would materially simplify the code; raising the
  floor is a separate ADR.
- Not lowering the floor below 17.6 without an ADR documenting the
  user-base data and the engineering cost.

## Consequences

What gets easier:

- We can use modern SwiftUI navigation, observation, and animation APIs
  unconditionally.
- SwiftData refinements available from iOS 17.6 onwards are usable
  without compatibility shims.
- Build configurations are simpler; less conditional code paths to
  test.
- Compiler diagnostics and Swift macros work on a known-good baseline.

What gets harder:

- Users on iOS 17.0–17.5 cannot run OpenSpace until they update.
- Devices that cannot install iOS 17 at all (older iPhones, older
  iPads) are excluded.
- Support requests from users on unsupported OS versions will need a
  clear, friendly response template.

What we accept:

- The addressable base is smaller than a hypothetical iOS 16 floor,
  but the product is pre-release and the simplification benefits
  during the foundation phase outweigh the reach loss.
- Raising the floor (e.g. to iOS 18) in the future is an ADR away; we
  do not commit to staying at 17.6 forever.

## Alternatives considered

- **iOS 17.0.** Lowest floor that still admits SwiftData. Rejected
  because several SwiftData refinements that materially affect the
  Storage Client landed in 17.x point releases; supporting 17.0
  exactly would require either avoiding those refinements or carrying
  conditionals.
- **iOS 18+.** Rejected as too aggressive at this stage. iOS 18
  installation is still rolling out; choosing it as the floor would
  exclude users on 17.x for a benefit we do not yet need.
- **Lower floor (iOS 16 or earlier) with backports.** Rejected because
  it forces away from SwiftData and creates parallel persistence
  paths. The cost is not justified by reach for a pre-release product.
