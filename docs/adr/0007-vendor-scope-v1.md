# 0007. Vendor scope v1: OpenRouter, OpenAI BYOK, Anthropic BYOK; two dialects

- Status: Accepted
- Date: 2026-05-22

## Context

ADR-0006 establishes one shared Provider Interface with N Live
implementations behind it. That decision says nothing about *which* N
to ship in v1. Picking too many vendors fragments engineering effort
across implementations that are not yet exercised; picking too few
leaves the abstraction unproven and risks shaping it around a single
vendor's wire format.

Two further constraints apply:

- OpenSpace is a Bring-Your-Own-Key (BYOK) product for direct vendor
  access. The user supplies their own API key, stored per ADR-0010,
  and we make the call from device.
- The market splits into a handful of API *dialects* even though there
  are many vendor *brands*. OpenAI's chat completions API is the de
  facto reference dialect; many aggregators (including OpenRouter)
  expose an OpenAI-compatible endpoint. Anthropic's Messages API is
  the second mainstream dialect with a meaningfully different shape
  (system prompt out-of-band, content blocks, distinct stop reasons).

## Decision

The v1 vendor scope is exactly three Provider Configs against two API
dialects:

1. **OpenRouter** as the aggregator entry point (OpenAI-compatible
   dialect, OpenRouter base URL and headers).
2. **OpenAI** direct, BYOK (OpenAI-compatible dialect, OpenAI base
   URL).
3. **Anthropic** direct, BYOK (Anthropic Messages dialect).

The implementation reflects the dialect split, not the brand split.
Two dialect Live implementations live under
`Shared/Provider/Live/`:

- `OpenAICompatibleLiveProvider`, parameterised by base URL, default
  headers, and any vendor-specific quirks (model id formats, optional
  fields). OpenRouter and OpenAI direct are constructed from this
  single implementation with different parameters.
- `AnthropicLiveProvider`, implementing the Anthropic Messages dialect
  end to end.

The user-facing `ProviderConfig` (ADR-0009) carries a `vendor` value
identifying one of the three configs above; the Composition Root maps
that value to the correct dialect implementation plus base
configuration.

## Consequences

What gets easier:

- The dialect split is honest: two pieces of wire-format code rather
  than three, with a clean parameterisation for OpenAI-compatible
  vendors. Future OpenAI-compatible aggregators slot in by config, not
  by code.
- The feature layer sees one shared Interface and three named vendors,
  no dialect leakage.
- BYOK keeps OpenSpace out of the path of vendor-side billing,
  privacy, and tenancy concerns; the user owns their account.

What gets harder:

- The OpenAI-compatible parameterisation must be careful about
  vendor-specific deviations (some aggregators enforce model id
  prefixes, some require extra headers). We hold those deviations as
  configuration, not as forks of the implementation.
- BYOK means onboarding asks the user for a key. Friction is real
  but unavoidable given the privacy posture.
- Anthropic-only behaviours (e.g. specific stop reasons, content
  blocks) have to be mapped into the shared streaming event type
  (ADR-0008) without losing fidelity for the reducer.

What we accept:

- We do not ship Google, Mistral, Cohere, or any other vendor in v1.
  Each will be added as a deliberate scope expansion; some will reuse
  the OpenAI-compatible dialect, others will need new dialect code.
- The aggregator (OpenRouter) and the direct vendor (OpenAI) overlap
  for the user — both reach OpenAI models. We expose both because the
  trade-offs (price, billing, model coverage) are real and the user
  should choose.

## Alternatives considered

- **OpenRouter only.** Rejected. Aggregators introduce an extra hop,
  pricing surcharge, and policy layer; some users prefer direct
  vendor access. Scoping to one aggregator also leaves the
  abstraction shaped by a single dialect.
- **OpenAI only.** Rejected. Locks the product to one vendor and
  leaves the second-dialect risk (Anthropic) undiscovered until v2.
- **Five or more vendors at v1.** Rejected. Each new dialect or
  vendor adds wire fixtures, error mappings, and rate-limit
  handling. Three configs over two dialects is the smallest set that
  proves the abstraction without spreading effort thin.
- **Server-side proxy instead of BYOK.** Rejected. Inserts our
  infrastructure into every request, takes on liability for vendor
  keys, and conflicts with the local-first product posture.
