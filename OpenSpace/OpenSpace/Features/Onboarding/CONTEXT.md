# Onboarding Context

Feature-scoped glossary for the Onboarding module. Cross-cutting terms
(Assistant, Provider, BYOK) live in the root
[`CONTEXT.md`](../../../../CONTEXT.md).

## Glossary

| Term                       | Definition                                                                                                                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Progress Entity**        | The SwiftData record that gates whether Onboarding is re-shown. Persisted per-install. When `nil`, the app presents Onboarding.                                                           |
| **Reference Carousel**     | The 5-page introduction sequence shown on first launch. Replaces the legacy 3-slide “Welcome Flow”. Rendered by `OnboardingView` over `OnboardingFlow`.                                   |
| **Reference Page**         | One page of the Reference Carousel. Modeled by `OnboardingPageModel` and discriminated by `OnboardingPageType`. Five cases ship today: `encryptedPairing`, `ideaStudio`, `promptQueue`, `reasoningControl`, `workspaceReady`. |
| **Page Demo State**        | Per-page interactive state owned by `OnboardingPageDemo` (TCA reducer scoped under `OnboardingFlow`). Holds `selectedPromptIndex`, `queuedPromptCount`, `reasoningLevel`, `pairingConfirmed`. Drives the live demo widgets in each page. |
| **Visual Factory**         | `OnboardingPageVisualFactory.make(page:store:appeared:)` — main-actor entry point that returns the `View` matching `OnboardingPageType`. Keeps each page’s visual implementation isolated. |
| **Highlight**              | A small icon-plus-text fact strip rendered in a Reference Page footer. Modeled by `OnboardingFeatureHighlightModel`.                                                                      |
| **Prompt Option**          | A selectable example prompt rendered on the `ideaStudio` page. Modeled by `OnboardingPromptOptionModel`.                                                                                  |
| **Prompt Queue Item**      | A queued follow-up prompt rendered on the `promptQueue` page. Modeled by `OnboardingPromptQueueItemModel`.                                                                                |

## Reducer composition

```
OnboardingContainer        // persistence gate + completion side-effects
└── OnboardingFlow         // navigation across Reference Pages
    └── OnboardingPageDemo // per-page interactive demo state
```

`OnboardingContainer` reads `OnboardingProgressEntity` at launch via
`OnboardingStorageClient`; if completion is recorded, it short-circuits to
`.delegate(.onboardingCompleted)`. On `.flow(.finishTapped)` it writes the
completion record and emits the same delegate.
