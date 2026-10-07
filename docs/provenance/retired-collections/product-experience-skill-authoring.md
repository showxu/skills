> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# Product Experience Skill Authoring

This document defines collection-level structure for `product-experience`
skills. Root `docs/skill-authoring.md` owns repository-wide trigger and manual
entry rules; this file adds product-side lifecycle placement rules.

## Purpose

Skills should be cheap to discover, precise to trigger, and deep only after
selection. A skill must let Codex or Claude decide whether to use it from a
small trigger contract, then load only the workflow, references, scripts,
templates, assets, or examples needed for the current task.

This collection covers product-side lifecycle work: discovery, requirements,
interaction modeling, UX interaction review, interface writing, platform
experience guidance, store/listing readiness, launch messaging, market
performance, organic search, paid acquisition, and store operations.

It does not cover source-level implementation, app architecture, build, test,
debugging, CI, signing, notarization, native API usage, or developer-tooling
work. Route those to engineering collections.

## Ownership Model

- `AGENTS.md` routes work inside this collection and points at durable docs.
- `README.md` indexes collection scope, lifecycle areas, published skills, and
  installation paths.
- `docs/*.md` owns collection-level skill design, review, lifecycle, and
  provenance rules.
- `skills/*/SKILL.md` owns the boundary, trigger contract, workflow,
  validation rules, and output format for one skill.
- `skills/*/references/` owns long-form methods, rubrics, source ledgers, and
  examples that should not live in `SKILL.md`.
- `skills/*/templates/` owns reusable output shapes or deliverable templates.
- `skills/*/assets/` owns reusable checked-in assets when they are
  license-safe and directly needed.
- `skills/*/scripts/` owns deterministic helpers only when repeatability makes
  them worth maintaining.
- `skills/*/agents/` is optional interface metadata for agent hosts. It is not
  the authoritative trigger or workflow source.

## Directory Shape

Every skill must have:

```text
skills/<skill>/
└── SKILL.md
```

Published skills should also have:

```text
skills/<skill>/
└── agents/
    └── openai.yaml
```

Use optional layers only when they have real content:

```text
skills/<skill>/
├── references/
├── templates/
├── assets/
├── examples/
├── scripts/
└── cli/
```

Do not create empty directories just to make every skill look identical. Do not
add lifecycle grouping folders under `skills/`.

## Lifecycle Categories

Classify a skill by its primary trigger and output, not only by a topic it
mentions.

| Category | Examples | Expected output |
|---|---|---|
| Discovery and direction | `product-discovery` | Problem, user/scenario, opportunity, assumption, tradeoff, and decision evidence. |
| Requirements | `product-requirements` | Product requirements / PRD source artifact, stories, acceptance criteria, metrics, risks, and traceability. |
| Interaction | `interaction-design` | Flow, state, action, feedback, recovery, permission handoff, prototype projection, and UX review. |
| Interface language and platform experience | `ux-writing`, `apple-hig`, `design-md-template`, `sfsymbols-export` | Interface copy, platform guidance, design-system templates, and local symbol assets. |
| Store, launch, and growth | `app-store-*`, `google-play-store-assets`, `market-*`, `organic-search`, `paid-acquisition` | Store/listing assets, release readiness, market copy, performance evidence, search readiness, and campaign preflight. |

## Split / Merge Rules

Create a separate skill when:

- the trigger can be stated precisely without relying on another skill
- the workflow, validation rules, or output format differs materially
- the skill needs its own references, templates, assets, examples, or scripts
- automatic selection would be useful and low-noise

Do not create a separate skill when:

- the content is only a small topic reference inside an existing workflow
- the trigger would overlap heavily with an existing skill
- the new skill would mostly duplicate another skill's `SKILL.md`
- the capability is a one-off checklist without stable reuse

When two skills could trigger, route to the more specific one first.

## Trigger Contract

The `description` frontmatter is a trigger contract, not a generic summary. It
should name:

- the task that should trigger the skill
- the product, interface, store, launch, or growth surface that should match
- the output or judgment the skill produces
- what should not trigger it
- whether private research, live tools, account state, or unreleased strategy
  need confirmation

## Required SKILL.md Shape

Prefer this section shape unless the skill has a clear reason to vary:

- Purpose
- When To Use
- When Not To Use
- Inputs To Inspect
- Workflow
- Reference Files To Consult
- Decision Rules
- Validation Rules
- Output Format
- Failure / Uncertainty Handling

`SKILL.md` should define reading order for deeper files. It should not require
loading every reference, example, or template for ordinary use.

## Source Authority

- Current product constraints, real user research, account evidence, and team
  decisions win over generic frameworks.
- Official platform guidance wins when the task depends on Apple, Google, web,
  accessibility, App Store, Google Play, advertising, search, or policy rules.
- Current official, product, account, or primary-source verification is a gate
  before mutable platform, accessibility, design-system, product-behavior,
  store, search, ads, or market-performance claims become local rules.
- Community examples can inform workflow shape, but should be rewritten into
  local boundaries.
- Do not retain license files, funding files, branding, contributor metadata,
  or unrelated setup material.

## Safety Rules

Stop and request explicit confirmation before:

- using private customer research, analytics, recordings, or unreleased
  strategy not already provided in the task
- editing live design-tool files or account state
- making live store, pricing, catalog, campaign, submission, or public listing
  changes
- making legal, accessibility compliance, medical, financial, or regulated
  claims
- presenting speculative user behavior as research-backed evidence
