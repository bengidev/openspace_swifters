# Third-Party Dependencies

This file is the canonical disclosure of every third-party package the
OpenSpace iOS app depends on, whether vendored, fetched via Swift Package
Manager, or pulled in as a transitive dependency surfaced in our manifest.

## Policy

Adding, upgrading, or removing a third-party dependency requires updating
this file in the **same change** that touches the package manifest
(`Package.swift`, Xcode SPM resolution, or any future manifest format the
project adopts). A pull request that modifies dependency graph without a
corresponding `THIRD_PARTY.md` update is considered incomplete and will be
sent back for revision.

Each entry records license attribution and source-of-record metadata so
that:

- License obligations are preserved without re-deriving them from each
  upstream repository.
- A future maintainer or auditor can answer "what does this depend on,
  and why?" by reading a single file.
- Removing a dependency is a single-place edit.

When upgrading a pinned version, update the `Version` field in place and
note the upgrade in `CHANGELOG.md` under the relevant release.

## Entry template

Copy the block below verbatim when adding a new dependency. Keep entries
sorted alphabetically by `Name`. Leave the section heading at level `###`
so the file renders as a flat list under the **Entries** heading.

```markdown
### <Name>

- **Version**: <exact version or locked range, e.g. `1.2.3` or `from: "1.2.0"`>
- **License**: <SPDX identifier, e.g. `MIT`, `Apache-2.0`>
- **Source**: <canonical URL, typically the upstream repository>
- **Purpose**: <one-line description of why this project depends on it>
```

## Entries

<!--
No third-party dependencies are declared yet. The first dependency change
will fill in the first entry below using the template above.
-->

### swift-composable-architecture

- **Version**: 1.25.5 (upToNextMajorVersion from 1.25.5)
- **License**: MIT
- **Source**: https://github.com/pointfreeco/swift-composable-architecture
- **Purpose**: Unidirectional state management architecture for all feature modules.

### swift-dependencies

- **Version**: 1.12.0
- **License**: MIT
- **Source**: https://github.com/pointfreeco/swift-dependencies
- **Purpose**: Dependency injection runtime powering the Interface/Live/Test client pattern across features.

### swift-navigation

- **Version**: 2.8.0
- **License**: MIT
- **Source**: https://github.com/pointfreeco/swift-navigation
- **Purpose**: Navigation tools for TCA-driven feature flows (Stack, tree, enum-based routing).

### Point-Free transitive cluster

These libraries are transitive dependencies of the TCA ecosystem and are resolved
automatically by Swift Package Manager. They are listed here for license compliance.

- **combine-schedulers** 1.2.0 (MIT)
- **swift-case-paths** 1.7.3 (MIT)
- **swift-clocks** 1.0.6 (MIT)
- **swift-concurrency-extras** 1.3.2 (MIT)
- **swift-custom-dump** 1.5.0 (MIT)
- **swift-identified-collections** 1.1.1 (MIT)
- **swift-perception** 2.0.10 (MIT)
- **swift-sharing** 2.8.0 (MIT)
- **xctest-dynamic-overlay** 1.9.0 (MIT)

### swift-collections

- **Version**: 1.5.1
- **License**: Apache-2.0
- **Source**: https://github.com/apple/swift-collections
- **Purpose**: OrderedDictionary and Deque types used by TCA's navigation and case-path machinery.

### swift-syntax

- **Version**: 603.0.1
- **License**: Apache-2.0
- **Source**: https://github.com/swiftlang/swift-syntax
- **Purpose**: Macro expansion support for TCA's @Reducer and @CasePathable macros.
