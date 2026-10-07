---
name: product-documentation
description: Create, revise, or review Product Documentation package orchestration across the canonical Discovery, Requirements / PRD, and product-owned Interaction Design workflow. Use for product artifact routing, sequencing, package state, source references, package readiness, source-of-truth validation, thin prototype_artifact_brief packaging, downstream prototype artifact dispatch, prototype coverage/gap verification, and cross-artifact consistency verification. Do not use to own full stage artifact content, generic repository documentation normalization, SwiftPM documentation structure, code/build planning, technical design, roadmap prioritization, UX craft, visual design, renderer execution, QA automation, GTM execution, or non-canonical product workflow stages.
---

# Product Documentation

## Purpose

Own Product Documentation package orchestration, placement strategy, package
graph, and package-level verification. This skill routes work across the three
canonical product-experience stage skills, sequences the package flow, tracks
package state, exposes unresolved decisions, and checks cross-artifact
consistency for product prototype package readiness.

The canonical package sequence is:

1. `product-discovery`
2. `product-requirements`
3. `interaction-design`
4. Prototype artifact generation / verification

This skill is a scheduler, router, placement owner, package verifier, and
prototype handoff packager. It does not own full stage artifact content and it
does not render HTML, Figma, native UI, or other artifacts. It may draft
package-level intake, status, reading order, source graph, package placement,
a thin `prototype_artifact_brief`, coverage/gap verification, downstream
artifact references, and summary content only.

## When To Use

- The user asks for a complete feature package instead of one isolated product
  artifact.
- The user asks for a complete Product Documentation package, product artifact
  reading order, source references, placement strategy, package graph, or
  package readiness review.
- The user has partial discovery, requirements, or interaction-design artifacts
  and needs sequencing, gap closure, and final package integration.
- The user asks which product artifact to produce first.
- The user asks to reconcile conflicts across discovery, requirements, and
  interaction-design artifacts.
- The user asks whether the package is ready for downstream prototype artifact
  generation or prototype review.
- The user asks to generate, route, or verify an HTML, Figma, or review
  prototype from product source artifacts.

## When Not To Use

- Single-stage requests that clearly belong to `product-discovery`,
  `product-requirements`, or `interaction-design`.
- Direct artifact requests that already have a complete non-product artifact
  brief and do not need product source validation.
- Non-canonical product workflow stages or redirects.
- Code/build plans, technical design, task breakdown, code changes, QA
  automation authoring, or test execution.
- UX craft, HIG interpretation, visual design systems, or interface writing.
- Generic repository documentation scaffolding, normalization, architecture
  docs, proposals, decisions, migrations, reference docs, DocC, or SwiftPM
  documentation structure.
- GTM execution such as launch messaging, ASO, SEO, paid acquisition, or store
  operations.

## Inputs To Inspect

- Existing product docs in the target repository.
- User-provided goals, evidence, constraints, risks, and deadlines.
- Existing package artifacts: discovery, requirements, and interaction-design
  sources.
- Parent initiative, Epic, feature, or package hierarchy docs when present.
- Repository conventions for where product docs should live.

## Workflow

1. Determine package mode: net-new package, partial package completion, or
   package review.
2. Build an intake summary with objective, current target product boundary,
   source evidence, and open decisions.
3. Determine the Product Documentation root and package path using the output
   rules below. Do not delegate placement decisions to leaf stage skills.
4. Route stage work by ownership using `references/decision-routing.md`.
5. Sequence work using `references/workflow.md`.
6. For each canonical stage artifact, record owner, status, dependency, source
   link, and required input. Draft directly only for package-level intake,
   status, reading order, `prototype_artifact_brief`, and summary sections.
7. Integrate artifact outputs into one package summary using
   `references/template.md`.
8. When downstream prototype artifacts are requested, package a thin
   `prototype_artifact_brief` that references source artifacts and model IDs
   instead of copying the `interaction_model` or redefining product behavior.
9. Verify discovery direction, requirements scope, interaction behavior,
   traceability, open decisions, prototype projection boundaries, prototype
   coverage, downstream artifact references, and downstream prototype readiness.

## Reference Files

- `references/template.md`: package-level integration template.
- `references/example.md`: completed package example.
- `references/workflow.md`: orchestration sequence and checkpoints.
- `references/decision-routing.md`: artifact routing matrix and boundary rules.
- `references/source-ledger.md`: receipt-backed source mapping and superseded
  provenance.
- `references/eval-fixtures.md`: durable behavior fixtures.

## Decision Rules

- State owned boundary first: this skill owns routing, sequencing, package
  state, Product Documentation placement strategy, package graph, source graph,
  reading order, source-of-truth validation, thin prototype artifact brief
  packaging, downstream dispatch, and cross-artifact verification.
- Own document placement centrally. `product-discovery`,
  `product-requirements`, and `interaction-design` own artifact content only;
  downstream `frontend-design` and `web-artifacts-builder` return artifact
  references plus coverage/gap information only.
- Own prototype artifact source retention centrally. When downstream artifact
  generation creates editable source files, this skill decides whether to keep
  the current source under `Prototype/source/` and whether to snapshot run
  workspaces under `.agent/product-prototype-runs/<product-slug>/<run-id>/`.
  Downstream artifact skills do not decide Product Documentation placement or
  run-retention policy.
- Route only to `product-discovery`, `product-requirements`, and
  `interaction-design` inside product-experience.
- Do not draft full stage artifacts as this skill's owned output.
- Use necessary orchestration only. Single-stage content requests should go
  directly to the owning stage skill; use this skill when work crosses
  artifacts, crosses skills, needs conflict handling, needs downstream
  prototype dispatch, or needs package-level verification.
- Treat discovery as direction discovery: problem framing, users/scenarios,
  opportunity framing, solution brainstorming, lightweight strategy, tradeoff
  and direction selection, risks, assumptions, and PRD-ready decision inputs.
- Treat requirements as the integrated product specification source:
  PRD/product spec, scope, non-goals, functional requirements, user stories,
  acceptance criteria, feature-level success metrics, business rules,
  constraints, risks, open questions, and traceability.
- Treat interaction design as the product behavior source: canonical
  `interaction_model`, `platform_context`, flows, screens, screen anatomy,
  wireframe semantics, states, actions, transitions, components, validation,
  feedback, recovery, edge cases, open decisions, product prototype contract,
  and prototype projection notes.
- Treat rendered artifacts as projections, not product sources of truth.
  Concrete Figma product prototypes, HTML product prototypes, visual design,
  and prototype review artifacts are downstream and outside the feature-package
  source stage.
- Treat `prototype_artifact_brief` as a routing manifest and coverage index,
  not as a second product spec. It may reference source artifacts,
  `interaction_model` IDs, product prototype contract IDs, target projection,
  placeholders, blockers, downstream owner choices, and expected artifact
  outputs. It must not copy flows, screens, states, actions, transitions,
  validation rules, feedback behavior, or other model facts.
- Dispatch HTML targets to `frontend-design` for visual UI projection and
  `web-artifacts-builder` for shareable HTML artifact generation when
  available. Dispatch Figma targets to Figma plugin skills when available.
  Dispatch review-only targets as a coverage/review packet. Use
  `webapp-testing` only when artifact verification is requested or needed.
- Treat product boundary work as current-target definition, not automatic
  reduction.
- Normalize accepted feedback into the current product contract. When an
  intermediate option is rejected, remove it from current stage artifacts and
  package wording instead of preserving the correction as a new label,
  qualifier, or explanation. Keep it as a non-goal only when exclusion is
  independently part of the current product boundary.
- Package status and unresolved decisions may describe current state. Authoring
  chronology and superseded content belong only in a source ledger or another
  artifact whose explicit role is provenance or history.
- Keep unresolved conflicts visible as `Decision Needed` items.
- Preserve traceability from each artifact to the package objective.
- Keep code/build detail out of product package content unless it is explicitly
  labeled as external evidence.

## Validation Rules

- The package contains or queues exactly three canonical stage artifacts:
  discovery, requirements, and interaction design.
- Package summary includes objective, current target boundary, assumptions,
  open decisions, artifact status, and source links.
- Discovery direction supports requirements scope, or the conflict is explicit.
- Requirements scope and business rules align with interaction behavior, or the
  conflict is explicit.
- Interaction-design open decisions state whether they block interaction
  design, downstream prototype generation, prototype verification, or neither.
- Accepted decisions are reflected directly in current artifacts; rejected
  intermediate options do not survive as correction narratives or residual
  package vocabulary unless they remain current non-goals or invariants.
- Feature-level success metrics live in requirements.
- Prototype handoff notes stay at product prototype contract, source-artifact,
  blocker, coverage, target dispatch, downstream artifact reference, and
  product constraint level.
- Product Documentation paths follow the single-product or multi-product
  convention below. Leaf stage artifacts do not decide their own package
  placement.
- `prototype_artifact_brief` references existing source artifacts and model
  IDs only; it does not duplicate or redefine interaction behavior.
- The result does not route through removed product skills, drift into
  code/build planning, render artifacts directly, or treat rendered artifacts
  as product truth.

## Output Format

Use the target repository's product docs convention when it exists. Otherwise
use `Documentation/Product/` as the product documentation root so product truth
stays separate from engineering architecture, proposal, decision, migration,
reference, and DocC documentation.

For a single-product repository, the product root is the package root:

```text
Documentation/Product/
  Product-Package.md
  Discovery.md
  Requirements.md
  Interaction-Design.md
  Prototype/
    prototype_artifact_brief.md
    coverage-report.md
    source/
      App.tsx
      index.css
      generation-notes.md
    artifacts/
  Features/<feature-slug>/
    Feature-Package.md
    Discovery.md
    Requirements.md
    Interaction-Design.md
    Prototype/
      prototype_artifact_brief.md
      coverage-report.md
      source/
      artifacts/
  Initiatives/<initiative-slug>/
    Initiative-Package.md
```

For a true multi-product repository or monorepo, add exactly one product slug
layer under `Documentation/Product/`:

```text
Documentation/Product/<product-slug>/
  Product-Package.md
  Discovery.md
  Requirements.md
  Interaction-Design.md
  Prototype/
    prototype_artifact_brief.md
    coverage-report.md
    source/
      App.tsx
      index.css
      generation-notes.md
    artifacts/
  Features/<feature-slug>/
    Feature-Package.md
    Discovery.md
    Requirements.md
    Interaction-Design.md
    Prototype/
      prototype_artifact_brief.md
      coverage-report.md
      artifacts/
  Initiatives/<initiative-slug>/
    Initiative-Package.md
```

Do not use `Documentation/Product/Products/<product-slug>/`. `Features/` is
always nested under the selected product root, whether that root is
`Documentation/Product/` for a single-product repo or
`Documentation/Product/<product-slug>/` for a multi-product repo. Do not
introduce `Surfaces/` by default; add it only if a repository has a proven
surface-level product documentation convention.

For chat-only output, return:

```text
Feature Package: <name>

Objective:
- ...

Artifact status:
- Parent context: Linked | Missing | Not needed
- Discovery: Ready | In progress | Missing | Not needed
- Requirements: Ready | In progress | Missing
- Interaction design: Ready | In progress | Missing

Cross-artifact verification:
- ...

Open decisions:
- ...

Prototype handoff:
- Target: Figma product prototype | HTML product prototype | prototype review
- Source artifacts:
- prototype_artifact_brief:
- Coverage gaps:
- Blockers:
- Downstream artifact refs:

Next artifact actions:
- ...
```

## Failure / Uncertainty Handling

- If artifact scope is ambiguous, return a routing decision with assumptions and
  open questions instead of fabricating full content.
- If artifacts conflict, keep conflict pairs explicit and request a product
  decision checkpoint.
- If the user asks for code/build details, preserve product constraints and
  route that work by responsibility.
