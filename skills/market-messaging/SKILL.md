---
name: market-messaging
description: Prepare, review, or adapt market-facing messaging for product positioning, value propositions, launch copy, store listing narrative, screenshot headlines, landing page sections, ad copy inputs, and channel-ready message consistency. Use when the task is about turning product facts, audience needs, proof points, or release changes into external messaging artifacts. Do not use for in-app interface microcopy, App Store field-limit validation, SEO technical audits, paid campaign setup, performance measurement, brand strategy decks, or legal/regulatory claim approval.
---

# Market Messaging

## Purpose

Turn product facts, audience context, and evidence into market-facing
messaging that is clear, supportable, channel-ready, and consistent across
store listings, launch surfaces, landing pages, screenshots, and ad inputs.

This skill is operational. Strategy can be an input, but the output is usable
copy, a message map, a copy review, or a channel adaptation plan.

## When To Use

- The user asks for positioning language, value proposition refinement,
  launch copy, product messaging, screenshot copy, store listing narrative,
  landing page messaging, ad copy inputs, or a message consistency review.
- The task involves translating features into user benefits, organizing proof
  points, clarifying a target audience, or adapting one message across store,
  web, screenshot, email, and ad contexts.
- The user supplies product facts, screenshots, feature lists, release notes,
  competitor framing, or rough copy and wants external-facing wording.

## When Not To Use

- In-app labels, alerts, empty states, settings copy, CLI output, or
  accessibility labels: use an interface-writing skill if available.
- App Store metadata limits, local metadata files, or App Store Connect sync:
  use `app-store-metadata`.
- App Store keyword or conversion optimization: use `app-store-aso`.
- Apple or Google Play screenshot asset production: use the store asset skill.
- Organic search audits, indexing, structured data, or SERP snippets:
  use `organic-search`.
- Paid campaign setup, budget checks, or live ad account planning: use
  `paid-acquisition`.
- Performance baselines, experiment logs, or analytics interpretation: use
  `market-performance`.

## Inputs To Inspect

- Product or feature facts, supported platforms, target audience, use cases,
  constraints, and strongest existing proof.
- Current messaging: app name, tagline, listing copy, screenshots, landing
  page sections, ads, email, social posts, release notes, or sales notes.
- Channel and locale constraints: store listing, landing page, screenshot,
  ad input, launch announcement, email, social, or partner page.
- Evidence level: shipped behavior, analytics, customer quotes, awards,
  certifications, screenshots, demos, or user-supplied claims.
- Requested mode: draft, rewrite, critique, consistency audit, localization
  adaptation, or channel pack.

## Workflow

1. Classify the output: message map, copy rewrite, channel pack, launch copy,
   screenshot copy, landing page section, ad input, or consistency audit.
2. Separate product facts from claims. If claims need proof, read
   `references/claims-and-proof.md` before drafting.
3. Define the message architecture. Read
   `references/message-architecture.md` when the task involves positioning,
   value proposition, audience, objections, or proof hierarchy.
4. Adapt by channel. Read `references/channel-copy.md` for store, screenshot,
   landing page, launch, and ad-input shapes.
5. For localization or non-English adaptation, read
   `references/localization-and-tone.md`.
6. Produce the smallest useful artifact and mark unsupported claims, missing
   proof, and channel-specific risks.

## Reference Files To Consult

- `references/message-architecture.md`: audience, problem, promise, proof,
  differentiators, objection handling, and message maps.
- `references/channel-copy.md`: store listings, screenshots, landing pages,
  launch posts, email, and ad-input adaptations.
- `references/claims-and-proof.md`: claim taxonomy, evidence requirements,
  and unsafe claim handling.
- `references/localization-and-tone.md`: tone, transcreation, locale review,
  and length expansion.

## Safety / Authority Rules

- Do not invent product behavior, customer outcomes, awards, certifications,
  compliance status, privacy promises, medical, financial, legal, or security
  claims.
- Mark comparative, superlative, regulated, time-sensitive, and outcome-based
  claims as requiring proof unless the user supplies credible evidence.
- Do not approve legal, regulatory, privacy, trademark, or platform-policy
  compliance. Identify risks and ask for qualified review when needed.
- Do not make live listing, website, email, or ad account changes without
  explicit confirmation.

## Decision Rules

- Prefer a concrete user outcome over an internal feature description.
- Use one primary message per surface. If a screenshot or section has multiple
  jobs, split it or choose the highest-value job.
- Keep proof close to the claim: shipped feature, visible UI, metric,
  customer quote, review, award, benchmark, or official certification.
- Preserve channel intent: store listing copy sells the app, screenshots
  explain moments, landing pages answer objections, ad inputs earn attention.
- Remove vague intensifiers unless they carry evidence or useful tone.
- Keep terminology consistent across store metadata, screenshots, web pages,
  ads, and release notes.

## Output Format

Use the shape that fits the task:

```text
Messaging Review

Audience and job:
- ...

Core message:
- ...

Proof available:
- ...

Copy changes:
- ...

Claims needing evidence:
- ...

Next safe action:
- ...
```

For channel packs, include the channel, goal, message, copy, required proof,
and risk notes for each surface.

## Failure / Uncertainty Handling

- If product facts are thin, create a questions list and a conservative draft
  based only on supplied evidence.
- If the user asks for broad strategy, convert it into operational artifacts:
  message map, copy variants, channel adaptation plan, or review checklist.
- If the task requires field limits, current platform policy, or account
  behavior, route to the relevant platform skill or verify official sources.
