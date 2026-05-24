# 0015. CI pipeline: build, Swift Testing unit tests, and SwiftLint on PR and main; UI smoke testing is manual

- Status: Accepted
- Date: 2026-05-22

## Context

OpenSpace runs as a public repository on GitHub. Pull requests come
from a single author today and from external contributors and AI
coding agents tomorrow. Continuous integration has to give a
reliable signal — green means the change compiles, the unit tests
pass, and the codebase still meets the lint baseline — without
becoming a Phase 0 time sink.

The state of the surrounding decisions:

- Swift Testing is the unit-testing framework (ADR-0005). Tests run
  via `swift test` for SwiftPM modules and via `xcodebuild test` for
  the iOS app target.
- SwiftLint is the linter the project has agreed to adopt; the
  configuration lands as part of the CI workflow setup.
- iOS 17.6 is the deployment floor (ADR-0004); CI must build against
  a matching SDK, which constrains us to GitHub-hosted macOS runners
  with the appropriate Xcode version (or a pinned action that
  selects it).
- UI tests are productive but too slow and flaky for hosted CI. They
  remain manual smoke tests performed by the user/developer on a
  simulator or device when relevant. Coverage gates, performance
  regressions, and security scanners are deferred deliberately.

## Decision

The v1 CI pipeline runs **three jobs** on every pull request and on
every push to `master`:

1. **Build.** `xcodebuild build` (or `swift build` for SwiftPM
   modules once they exist) against the iOS Simulator destination
   matching the deployment floor. Must compile cleanly under Swift
   strict-concurrency settings.
2. **Test.** `xcodebuild test -only-testing:OpenSpaceTests` (or
   `swift test`) running unit tests only. Failure on any `#expect` /
   `#require` fails the job. UI tests are intentionally not invoked
   by CI.
3. **Lint.** `swiftlint lint --strict`. Warnings fail the job in
   strict mode so style drift cannot accumulate quietly.

Workflow shape:

- A single GitHub Actions workflow file at `.github/workflows/ci.yml`
  with three jobs (`build`, `test`, `lint`) running in parallel.
- macOS runner pinned to the version that ships the Xcode required
  by ADR-0004. The Xcode version is selected explicitly (e.g. via a
  setup action) so a runner image bump cannot silently change the
  toolchain.
- Cache `~/Library/Developer/Xcode/DerivedData` and SwiftPM
  artifacts where it pays off; cache invalidation keys include the
  Xcode version and the lockfile hashes.
- Required-status checks on `master` enforce all three jobs; this
  is configured at the branch-protection layer and noted in
  `CONTRIBUTING.md`.

What is **manual or deferred**, with tracking issues filed as needed:

- **UI tests** (XCUITest target). The hooks are in the project
  (per ADR-0005), but no UI test runs in CI. They are slow, flaky
  on hosted runners, and produce more noise than signal. User or
  developer manual UI smoke testing covers this gap.
- **Code coverage gates.** Coverage is computed locally during
  development; CI does not enforce a threshold in v1. Phase 6 picks
  a baseline and a ratchet policy.
- **Performance benchmarks**, **security scanners** (Snyk, GitHub
  Advanced Security), and **release-build validation**. All three
  are valuable; none is a Phase 0 critical-path requirement.

## Consequences

What gets easier:

- Pull requests get a fast, three-signal answer: does it build,
  do the tests pass, is the style clean. Reviewers can trust that
  the bar is uniform.
- Branch protection on `master` keeps red builds out of the
  default branch without ceremony.
- Adding any future deferred jobs is additive: drop in a coverage-report
  step or other hardening job without restructuring the workflow. UI
  smoke testing remains a manual user/developer responsibility unless
  a later ADR explicitly reverses this decision.

What gets harder:

- Hosted macOS runners are slow and contended; CI minutes are
  finite. Caching helps; we will revisit if queue times become
  painful.
- Xcode-version pinning means the workflow needs an occasional
  bump as new versions ship. The bump is explicit and reviewable,
  which is a feature.
- `swiftlint --strict` failing on warnings is a sharp tool. A new
  rule that fires across the codebase blocks the pipeline. We
  mitigate by introducing rules with `severity: warning` first,
  proving them out, and only then promoting to error.

What we accept:

- We trade UI-test confidence for CI throughput. Manual UI smoke
  testing on simulator/device covers the gap and is performed by the
  user/developer when relevant.
- We trade coverage enforcement for v1 simplicity. Tests are still
  expected; the bar is "the change is tested," judged at review.
- A green CI is necessary, not sufficient. Reviewers still read
  the diff.

## Alternatives considered

- **CI = build only.** Rejected. Skipping the test job lets a
  failing test ship; skipping lint lets style drift accumulate.
  Both are cheap to run alongside the build and pay back
  immediately at review time.
- **Run UI tests in CI.** Rejected. XCUITest on hosted runners is the
  most flake-prone job in our toolbox and can stall PR feedback for
  little signal. Manual user/developer smoke testing is the accepted
  path.
- **Coverage gate at v1.** Rejected. Choosing a meaningful
  threshold without a baseline produces either a vacuous gate
  (everything passes) or a punitive one (everything fails). Phase
  6 sets the baseline against a real codebase.
- **Self-hosted macOS runner.** Rejected for v1. Operational
  overhead (provisioning, Xcode upgrades, security) outweighs
  the throughput gain at this scale. Re-openable if hosted-runner
  queue times become a sustained blocker.
- **Per-PR matrix across multiple Xcode versions.** Rejected.
  Multiplies CI time by the matrix size; a single pinned toolchain
  catches what we need to catch, and Phase 6 can re-evaluate.
