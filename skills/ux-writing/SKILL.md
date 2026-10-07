---
name: ux-writing
description: >-
  Write, rewrite, or review product-facing UX writing in design artifacts: UI
  copy, microcopy, button labels, headings, empty/loading/error/success states,
  alerts, confirmations, onboarding, permission rationale, settings
  descriptions, tooltips, inline help, notification text, and terminology in
  flows, wireframes, screenshots, prototypes, or design handoff. Use for
  design-stage wording, voice and tone, clarity, actionability, state-aware
  copy, and implementation handoff notes when copy creates localization or
  accessibility-label risks. Do not use as the sole skill for source-string
  implementation, CLI output, String Catalogs, localization wiring,
  accessibility behavior, marketing copy, App Store listings, legal policy
  authoring, frontend implementation, or broad interaction design without a
  writing task.
---

# UX Writing

## Purpose

Use this skill to write and review the words users read while completing a
product task. Focus on clarity, actionability, state fit, terminology
consistency, and a voice that supports the moment. Keep implementation and
localization mechanics in engineering skills.

Use the product-owned source first when flow behavior, user state, or a product
decision is unclear. Use `interaction-design` when an existing prototype or
surface needs design-side UX review, and use `apple-hig` when Apple platform
wording or component convention matters. This skill can overlap with
implementation-side interface writing:
`ux-writing` shapes the product-facing wording, while implementation-side
writing checks source strings, accessibility labels, localization risk, CLI
output, and terminology drift.

## When To Use

- Writing or rewriting product-facing text in wireframes, screenshots,
  prototypes, specs, or design handoff notes.
- Reviewing buttons, headings, empty states, loading states, errors, success
  messages, alerts, confirmations, onboarding, permissions, settings text,
  tooltips, inline help, and notification text.
- Choosing terminology for user-facing concepts inside a flow.
- Checking whether copy is clear, actionable, consistent, honest, and matched
  to the user's state.
- Turning interaction placeholders into polished product copy after the flow is
  sufficiently defined.

## When Not To Use

- Source-string placement, SwiftUI `Text`, CLI output, string catalogs,
  localization resource wiring, translator files, pseudolocalization, or RTL
  engineering checks as the sole task. Pair with implementation-side writing or
  localization skills when design copy needs that handoff.
- VoiceOver behavior, accessibility traits, reading order, assistive
  technology testing, or accessibility implementation.
- Market messaging, App Store listings, screenshot marketing copy, ads,
  landing pages, blog posts, press copy, or brand-guide creation.
- Legal, privacy, medical, financial, safety, billing, or support commitments
  unless the user provides the factual source of truth.
- Product interaction requirements, product prototype generation, or broad
  interaction review with no writing task.

## Inputs To Inspect

- Flow, wireframe, screenshot, prototype, design brief, or handoff document.
- User goal, audience, state, risk level, and next action.
- Existing product voice, terminology, nearby UI copy, and style guidance.
- Platform or component context when wording depends on UI behavior.
- Space constraints, localization expectations, and tone constraints when
  provided.

## Workflow

1. Identify the user state, task, and next action the copy must support.
2. Classify the copy surface: action, status, error, empty state, onboarding,
   permission, setting, tooltip, notification, or terminology.
3. Read only the matching reference when the task needs pattern depth.
4. Apply the precedence chain: clarity, truth, actionability, voice, polish.
5. Preserve product facts and commitments. Use placeholders or flag unknowns
   instead of inventing capabilities, policies, dates, pricing, or guarantees.
6. Rewrite element by element. Keep primary actions specific and reversible
   consequences explicit.
7. Add handoff notes for engineering only when wording creates localization,
   accessibility-label, truncation, or state-coverage risks.

## Reference Files To Consult

- `references/_index.md`: routing index for writing references.
- `references/copy-patterns.md`: surface-specific copy rules for actions,
  alerts, empty states, errors, onboarding, permissions, settings, tooltips,
  and notifications.
- `references/voice-and-terminology.md`: voice, tone, terminology, and word
  list guidance.

## Decision Rules

- Headings and actions should communicate the main point even if body text is
  skipped.
- Button labels should name the action, not generic confirmation.
- Error copy should say what happened and what the user can do next.
- Empty states should say what belongs there and how to make progress.
- Destructive copy should name the object and consequence.
- Settings copy should explain the enabled behavior, not both states unless the
  disabled state is surprising.
- Voice can add character, but clarity wins when the user is blocked, making a
  risky choice, or handling privacy, money, safety, or data loss.
- Keep copy localizable: avoid idioms, fragile jokes, fixed word order, and
  text that assumes short English strings.

## Validation Rules

- The target surface and user state are named.
- Rewrites preserve the underlying product behavior and commitments.
- Important actions are understandable without surrounding paragraphs.
- Terminology matches nearby product copy or the deviation is called out.
- Localization, accessibility, or implementation risks are handed off instead
  of silently solved in this skill.

## Output Format

For reviews, prefer:

```text
UX Writing Review

Surface:
- ...

Findings:
- Issue:
  Impact:
  Rewrite:
  Rationale:

Terminology:
- ...

Handoff notes:
- ...
```

For direct writing tasks, prefer:

```text
Proposed Copy

Primary:
- ...

Alternatives:
- ...

Assumptions:
- ...

Handoff notes:
- ...
```

## Failure / Uncertainty Handling

- If product behavior is unclear, state the assumed user state and route the
  behavior question to the product-owned source of truth.
- If voice is unclear, infer a working voice from nearby product copy and mark
  it as an assumption.
- If copy depends on unprovided facts or regulated commitments, use placeholders
  or mark the line for owner review.
