# Product Build Lifecycle Overlay

This document records the product build lifecycle across atomic root skills.
It is a workflow overlay, not a request to merge skill contents.

## Core Principle

Maintain atomic skills by the durable artifact they own, then compose them into
larger workflows through orchestrator skills and root lifecycle docs.

This differs from older human-role boundaries. The local model is:

- Product facts are structured source artifacts.
- Prototype and implementation outputs are projections or downstream
  realizations of those facts.
- Atomic skills remain reusable across workflows.
- Workflow skills and docs can stack those atomic skills without making any
  leaf skill lose its boundary.

## Main Product Prototype Chain

The product-side prototype workflow is:

1. `product-documentation`
2. `product-discovery`
3. `product-requirements`
4. `interaction-design`
5. `frontend-design`
6. `web-artifacts-builder`

Responsibilities:

| Step | Owner | Artifact |
| --- | --- | --- |
| Product Documentation orchestration | `product-documentation` | Product artifact routing, package status, source references, cross-artifact consistency, prototype readiness, and downstream artifact dispatch. |
| Discovery | `product-discovery` | Direction, user/scenario framing, opportunity framing, assumptions, risks, and PRD-ready decisions. |
| Requirements | `product-requirements` | PRD/product spec, scope, non-goals, stories, acceptance criteria, metrics, rules, risks, and traceability. |
| Interaction design | `interaction-design` | Interaction model, platform context, flows, screens, states, actions, transitions, validation, feedback, recovery, edge cases, and prototype contract. |
| Web UI projection | `frontend-design` | Visual UI projection, design-system extraction, interface expression, and UI surface quality. |
| HTML artifact projection | `web-artifacts-builder` | Shareable single-file HTML prototype/review artifact. |

Rendered prototype artifacts are projections, not product source-of-truth
artifacts. They must preserve upstream product behavior and report gaps instead
of inventing missing product decisions.

When a target repository has no product documentation convention, place product
source artifacts and prototype projection records under `Documentation/Product/*`.
This product subtree is separate from engineering architecture, proposal,
decision, migration, reference, and DocC documentation.

## Optional Downstream Workflows

These skills can be invoked by a workflow when their artifact is needed, but
they are not mandatory product prototype stages.

| Need | Owner | Notes |
| --- | --- | --- |
| Browser verification, screenshots, coverage, console evidence | `webapp-testing` | Optional verification/QA skill. It should not be treated as a default product package stage. |
| Real Web app implementation | `webapp-builder` | Separate downstream implementation workflow, not part of the product prototype endpoint. |
| Figma prototype or design artifact | Figma plugin skills / future design owner | Figma output is a projection, not product truth. |
| Native app implementation | Swift/iOS/macOS engineering skills | Source-level implementation and platform API work remain engineering-owned. |
| Store launch and growth | `go-to-market` marketplace group skills | Separate market lifecycle, not part of the product prototype chain. |

## Maintenance Domains

All local skills in this lifecycle live under root `skills/*`. Marketplace
plugin groups provide discovery views only; they do not change ownership.

The external Swift skill family remains source-owned in its own checkout.
Native implementation can participate in the lifecycle, but that linked
checkout keeps its own repository and marketplace.

## Current Gaps

Closed or mostly closed:

- Product source artifacts: discovery, requirements, interaction model.
- Web UI projection: `frontend-design`.
- HTML artifact projection: `web-artifacts-builder`.
- Real Web app implementation: `webapp-builder`.
- Web/browser verification: `webapp-testing`.

Open or intentionally delegated:

- Figma product prototype orchestration is delegated to Figma plugin skills or
  a future design/Figma owner.
- Visual design system / `design.md` generation is only partially covered.
- Brand, theme, and static canvas artifact skills are design-adjacent and not
  yet integrated into a product design lifecycle.
- Payment and database integration guidance remains outside generic Web core
  unless a concrete Web app implementation needs those integration surfaces.

## Change Policy

- Do not edit leaf skill contents when only the lifecycle overlay changes.
- Update root taxonomy and lifecycle docs first.
- Move local skills only after the overlay stabilizes and the physical move has
  clear validation, marketplace, and install implications.
- Keep marketplace paths stable until a migration plan explicitly changes them.
