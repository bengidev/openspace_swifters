# 0005. Use Swift Testing as the unit-testing framework

- Status: Accepted
- Date: 2026-05-21

## Context

OpenSpace needs a unit-testing framework to validate reducers,
domain types, infrastructure adapters, and Client behaviour. The
choices on Apple platforms today:

- **XCTest.** The historical default. Mature, widely understood,
  bundled with Xcode. Test cases are subclasses of `XCTestCase`;
  assertions are `XCTAssert*`; parameterisation, async, and
  parallelism work but show their age.
- **Swift Testing.** Apple's modern testing framework, introduced at
  WWDC 2024, available from Xcode 16. Test cases are functions
  annotated with `@Test`; assertions use `#expect` and `#require`
  macros; parameterisation is first-class via `arguments:`; async
  and concurrency-friendly by design.

The state-management decision in ADR-0002 commits us to TCA, whose
test ergonomics (`TestStore`) work with both frameworks. The
persistence decision in ADR-0003 commits us to SwiftData, which is
straightforward to test against an in-memory `ModelContainer` from
either framework.

The minimum deployment target in ADR-0004 (iOS 17.6) and our
toolchain floor (Xcode 16+) put both frameworks well within reach.

## Decision

We use **Swift Testing** as the unit-testing framework for OpenSpace.

Concretely:

- The `OpenSpaceTests` target is a Swift Testing target. New unit
  tests are written using `@Test`, `#expect`, and `#require`.
- Parameterised tests use `@Test(arguments:)` rather than data-driven
  loops with `XCTAssert*`.
- Async tests use `async` test functions directly; we do not use
  expectation-based async patterns.
- The `OpenSpaceUITests` target remains XCUITest-based, as Swift
  Testing is not a UI-testing framework.
- Any legacy XCTest cases that get added (e.g. by template or import)
  are migrated to Swift Testing before merging.

## Consequences

What gets easier:

- Test code is shorter and reads more like ordinary Swift. Less
  ceremony per case.
- Parameterised tests are first-class, which matters for reducers
  that step through several states under varying inputs.
- Suites and tags allow sharper organisation than `XCTestCase`
  inheritance hierarchies.
- Async/await is the default rather than an afterthought, matching
  the rest of the codebase.

What gets harder:

- Contributors familiar only with XCTest face a (small) learning
  curve. Swift Testing is similar enough that the ramp is mild.
- Some XCTest-only affordances (e.g. specific concurrency tooling,
  certain Xcode integrations that lag) may need workarounds. We will
  record them as they are encountered.
- Integration with code-coverage and CI tooling is mature on XCTest;
  Swift Testing is supported but newer. We will validate the CI
  pipeline (when set up) outputs the metrics we want.

What we accept:

- Mixing Swift Testing for unit tests and XCTest (XCUITest) for UI
  tests is fine and Apple-supported. We do not attempt to unify them.
- If a Swift Testing limitation blocks a critical test, we may write
  that single test in XCTest and document the reason inline. The
  default remains Swift Testing.

## Alternatives considered

- **XCTest only.** Rejected. Mature but verbose; we would write more
  test code for less expressive results, and miss out on first-class
  parameterisation and async ergonomics.
- **Both frameworks freely mixed in `OpenSpaceTests`.** Rejected.
  Mixing inside a single target produces inconsistent test code,
  duplicated patterns, and reviewer fatigue. We pick one default and
  use the other only as a documented exception.
- **A third-party assertion library on top of XCTest.** Rejected.
  Adds a dependency to solve a problem Swift Testing solves at the
  language level.
