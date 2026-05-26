# Onboarding Context

Feature-scoped glossary for the Onboarding module. Cross-cutting terms
(Assistant, Provider, BYOK) live in the root
[`CONTEXT.md`](../../../../CONTEXT.md).

## Glossary

| Term              | Definition                                                                                                                        |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Progress Entity** | The SwiftData record that gates whether Onboarding is re-shown. Persisted per-install. When `nil`, the app presents Onboarding. |
| **Welcome Flow**  | The 3-slide introduction sequence. Distinct from Settings or Conversation flows. Rendered by `OnboardingView` with navigation.    |
