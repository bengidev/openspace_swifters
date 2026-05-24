# OpenSpace

A native iOS AI assistant exploring The Composable Architecture, SwiftData, and
multi-vendor BYOK as a single, testable composition.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![iOS 17.6+](https://img.shields.io/badge/iOS-17.6%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![CI](https://github.com/bengidev/openspace_swifters/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/bengidev/openspace_swifters/actions/workflows/ci.yml)

Created and maintained by [@bengidev](https://github.com/bengidev). Community
contributors are credited via Git history and release notes.

OpenSpace is an iOS app that puts an AI assistant in the user's pocket so they
can get work done faster — drafting, summarising, planning, and acting on
information through natural conversation.

> **Status: Pre-release.** The app is in scaffolding. Quick-start commands
> below are aspirational until the project's package manifest and module
> structure land. See [`docs/roadmap.md`](docs/roadmap.md) for what is on
> deck and [`docs/architecture.md`](docs/architecture.md) for the intended
> shape.

## Why

Productivity assistants live inside other people's apps. OpenSpace is a
first-party iOS surface where the assistant respects the conventions of the
platform — Shortcuts, share sheets, focus modes, accessibility — and the
user's data stays under their control.

The goals that drive every architectural decision:

- **Native feel.** SwiftUI-first UI, system fonts, system gestures, full
  Dynamic Type and VoiceOver support.
- **Composable architecture.** Features ship as self-contained slices that
  can be pulled apart, tested in isolation, and assembled by the App
  composition root.
- **Provider-agnostic intelligence.** The Assistant talks to model providers
  through a thin abstraction so the app can swap backends without rewriting
  features.
- **Local-first persistence.** Conversations and user state live on-device
  by default; sync is opt-in and isolated behind a Client.

## Features

The first user-visible surface is a conversational Assistant capable of:

- Multi-turn chat with streaming responses.
- Tool-style capabilities the Assistant can invoke on the user's behalf
  (formerly known as "skills" in informal docs — the canonical term is
  **Capability**, see [`CONTEXT.md`](CONTEXT.md)).
- Local conversation history with search and pinning.
- Share-sheet entry point so any text from another app can be sent in.

Planned surfaces beyond v1 are listed in [`docs/roadmap.md`](docs/roadmap.md).

## Quick start

> The commands below assume the Xcode project and any future Swift packages
> have been set up. During Phase 0 of the roadmap they may not all work yet.

1. Clone the repository.
2. Open `OpenSpace/OpenSpace.xcodeproj` in Xcode 16 or later.
3. Select an iOS 17.6+ simulator and run the `OpenSpace` scheme.

For contributors:

- See [`CONTRIBUTING.md`](CONTRIBUTING.md) for branching, commits, and PR
  flow.
- See [`AGENTS.md`](AGENTS.md) and [`docs/agents/`](docs/agents/) for how AI
  coding agents are expected to operate in this repo.

## Repository layout

```
.
├── AGENTS.md                  AI coding agent guidance
├── CHANGELOG.md               Keep a Changelog history
├── CODE_OF_CONDUCT.md         Contributor Covenant 2.1
├── CONTEXT-MAP.md             Multi-context glossary index
├── CONTEXT.md                 App-level glossary (root context)
├── CONTRIBUTING.md            Contributor workflow and policies
├── LICENSE                    Project license
├── README.md                  This file
├── SECURITY.md                Vulnerability reporting policy
├── docs/
│   ├── adr/                   Architectural Decision Records
│   ├── agents/                AI coding agent playbooks
│   ├── architecture.md        Layered architecture sketch
│   └── roadmap.md             Phased delivery plan
└── OpenSpace/                 Xcode project root
    ├── OpenSpace.xcodeproj
    ├── OpenSpace/             App target sources
    ├── OpenSpaceTests/        Unit tests (Swift Testing)
    └── OpenSpaceUITests/      Manual UI smoke-test target (not run in CI)
```

## Documentation map

| If you want to…                            | Read                                                |
| ------------------------------------------ | --------------------------------------------------- |
| Understand the product                     | This README                                         |
| Learn the vocabulary                       | [`CONTEXT.md`](CONTEXT.md)                          |
| See the index of all glossaries            | [`CONTEXT-MAP.md`](CONTEXT-MAP.md)                  |
| Understand the layered design              | [`docs/architecture.md`](docs/architecture.md)      |
| See what is shipping when                  | [`docs/roadmap.md`](docs/roadmap.md)                |
| Read past architectural decisions          | [`docs/adr/README.md`](docs/adr/README.md)          |
| Contribute code                            | [`CONTRIBUTING.md`](CONTRIBUTING.md)                |
| Report a vulnerability                     | [`SECURITY.md`](SECURITY.md)                        |
| Find behavioural expectations              | [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)          |
| Track release-by-release changes           | [`CHANGELOG.md`](CHANGELOG.md)                      |
| Operate as an AI coding agent in this repo | [`AGENTS.md`](AGENTS.md), [`docs/agents/`](docs/agents/) |

## Translations

OpenSpace ships with a String Catalog scaffold so user-facing copy can be
translated without code changes. The catalog itself lands in a separate slice;
once it is in place, contributors can add a locale by opening the catalog in
Xcode, declaring the language, and translating the strings. Pull requests that
add or improve translations are welcome and reviewed alongside code changes.

## License

See [`LICENSE`](LICENSE).
