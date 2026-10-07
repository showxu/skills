---
name: paid-acquisition
description: Plan, audit, or preflight paid acquisition operations across Apple Ads, Google Ads, Meta ads, and similar paid channels, including campaign readiness, budget safety, targeting assumptions, keyword or audience structure, creative and landing-page consistency, conversion tracking, UTM conventions, policy risk, and launch/change confirmation. Use for paid channel execution reviews, not growth strategy. Do not use for organic SEO, App Store ASO, market messaging only, performance reporting only, live budget or campaign changes without explicit confirmation, or regulated advertising approval.
---

# Paid Acquisition

## Purpose

Prepare and review paid acquisition operations so campaigns can be launched,
changed, or analyzed with clear scope, tracking, budget safety, policy checks,
and explicit confirmation before live account actions.

This skill is operational. Strategy can be an input, but the output is a
campaign preflight, setup checklist, tracking review, policy-risk review, or
change plan.

## When To Use

- The user asks about paid acquisition, paid ads, Google Ads, Apple Ads,
  Apple Search Ads, Meta ads, paid search, paid social, campaign preflight,
  budget safety, targeting, keywords, creative consistency, UTM, conversion
  tracking, or ad policy checks.
- The task involves preparing a campaign, reviewing settings before launch,
  checking landing page and creative alignment, or planning a controlled
  campaign change.
- The user supplies campaign exports, account screenshots, ad copy, landing
  pages, tracking notes, budgets, keyword lists, audiences, or platform errors.

## When Not To Use

- Organic search readiness or SEO: use `organic-search`.
- App Store ASO, keywords, PPO, CPP, or listing optimization: use
  `app-store-aso`.
- Market-facing copy only: use `market-messaging`.
- Performance reporting only: use `market-performance`.
- Live budget changes, campaign launches, targeting changes, or account
  mutations without explicit confirmation.
- Legal approval for regulated advertising, privacy compliance, financial
  claims, medical claims, employment, housing, credit, gambling, alcohol, or
  pharmaceutical promotions.

## Inputs To Inspect

- Platform: Apple Ads, Google Ads, Meta ads, Microsoft Ads, TikTok Ads,
  LinkedIn Ads, or another paid channel.
- Objective, conversion event, landing page, audience, geography, language,
  device, schedule, budget, bid strategy, campaign/ad group structure, and
  creative assets.
- Tracking: UTM convention, conversion source, pixel/tag, SDK, server-side
  events, attribution window, consent requirements, and analytics destination.
- Policy context: app category, product category, restricted content,
  geography, claims, trademarks, pricing, offers, and landing page disclosures.
- Requested mode: preflight, setup plan, change review, tracking review,
  policy-risk scan, or launch checklist.

## Workflow

1. Classify the task: platform setup, launch preflight, change plan, budget
   safety check, tracking check, creative/landing-page consistency, or policy
   risk scan.
2. Read `references/source-authority.md` for platform authority hierarchy and
   current verification rules.
3. Read `references/campaign-preflight.md` for campaign structure, budget,
   targeting, and launch/change checklist.
4. Read `references/tracking-and-attribution.md` for UTM, conversion event,
   tag, pixel, SDK, and attribution checks.
5. Read `references/policy-and-claims.md` for advertising policy and claim
   risk handling.
6. Separate required fixes, budget/account risks, policy risks, tracking
   gaps, and advisory improvements. Ask for explicit confirmation before any
   live account change.

## Reference Files To Consult

- `references/source-authority.md`: official platform documentation and
  authority tiers.
- `references/campaign-preflight.md`: structure, budget, targeting, creative,
  landing page, and launch/change checks.
- `references/tracking-and-attribution.md`: UTM, conversion, tag, pixel, SDK,
  attribution, and validation checks.
- `references/policy-and-claims.md`: platform policies, restricted categories,
  claim review, and escalation rules.

## Safety / Confirmation Rules

- Stop for explicit confirmation before launching, pausing, editing, deleting,
  increasing budgets, changing targeting, changing bids, changing conversion
  goals, or publishing ads.
- Identify account, campaign, ad group, budget, schedule, geography, objective,
  and exact change before any live action.
- Do not request secrets or expose credentials. Use platform UI/API access
  only when the user has explicitly authorized the current task.
- Do not approve legal, regulated, privacy, trademark, or platform-policy
  compliance. Flag risks and require qualified review when needed.
- Treat third-party tactics, benchmark CPAs, and platform "hacks" as advisory.

## Decision Rules

- Budget safety comes before optimization.
- Conversion tracking must match the campaign objective before launch.
- Creative, ad copy, landing page, and store listing must make the same
  promise.
- Use separate structure only when it improves measurement, control, or budget
  safety.
- Separate discovery, exact intent, remarketing, and competitor terms when the
  platform and data support that separation.
- Prefer a small confirmed change with a measurement plan over broad live
  account edits.

## Output Format

```text
Paid Acquisition Preflight

Platform and account scope:
- ...

Campaign objective and conversion:
- ...

Budget / schedule risks:
- ...

Tracking readiness:
- ...

Creative and landing-page consistency:
- ...

Policy and claim risks:
- ...

Required fixes before launch/change:
- ...

Confirmation needed:
- ...
```

For change plans, include current value, proposed value, reason, expected
impact, rollback plan, and exact confirmation question.

## Failure / Uncertainty Handling

- If platform rules may have changed, verify official docs or live UI before
  treating settings as current.
- If tracking cannot be verified, mark the campaign as measurement-risky.
- If budget or account scope is ambiguous, stop before proposing a live
  account change.
- If the request is broad strategy, convert it into an operational preflight,
  tracking checklist, or controlled change plan.
