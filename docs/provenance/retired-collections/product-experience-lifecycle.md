> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# Product Experience Lifecycle

`product-experience` groups product, design, launch, and growth workflows by
the artifact or user/market-facing surface they shape.

For the cross-collection product build workflow that continues into Web
prototype projection, optional browser verification, or implementation, see
root `docs/product-build-lifecycle.md`. This collection owns the product-side
source artifacts in that overlay; downstream Web and engineering skills remain
in their own physical collections.

## Workflow Areas

| Area | Primary skills | Output |
|---|---|---|
| Discovery and direction | `product-feature-creator`, `product-discovery` | Product direction, user/scenario framing, opportunity framing, assumptions, tradeoffs, and package routing. |
| Requirements | `product-requirements` | Product requirements / PRD source artifact, scope, stories, acceptance criteria, metrics, risks, and traceability. |
| Interaction and product prototype contract | `interaction-design` | Interaction model, user flows, screens, screen anatomy, states, actions, transitions, feedback, recovery, permission handoff, product prototype contract, UX review, and prototype handoff. |
| Interface language and platform experience | `ux-writing`, `apple-hig`, `design-md-template`, `sfsymbols-export` | Interface copy, platform conventions, design-system files, and local symbol assets. |
| Store, launch, and growth | Store, market, search, and paid acquisition skills | Store metadata, screenshots, release readiness, commerce catalogs, launch messaging, search readiness, market performance, and campaign preflight. |

## Permission And System-Mediated Flows

Product-side skills own the user-visible interaction model for permissions:
what capability is needed, which object is being authorized, when the user
enters a blocked state, what handoff action is available, how the system
responds, and how success, denial, cancellation, fallback, and task resumption
work.

Platform-specific implementation remains outside this collection. For example,
a macOS screenshot-permission onboarding flow can be modeled here as product
interaction, while TCC API details, entitlements, System Settings targeting,
and Swift/AppKit implementation belong to engineering-side Apple platform
skills.

## Prototype Levels

Use these levels to avoid mixing responsibilities:

- Product prototype: proves flow, state, decision, requirement, interaction
  model, user-visible handoff behavior, and the product-owned prototype
  contract.
- Design prototype or review: evaluates information architecture, usability,
  control choice, copy, platform convention, visual-system fit, accessibility,
  and handoff quality.
- Engineering prototype: validates implementation feasibility, native API
  behavior, source-level architecture, build/test behavior, and runtime edge
  cases.

## Handoffs

- Route source code, app architecture, SwiftUI/AppKit, Xcode, CI, build, test,
  debugging, signing, notarization, and native API work to engineering.
- Route concrete HTML/frontend prototype projection to `frontend-design` and
  `web-artifacts-builder` after the product prototype contract exists.
- Route browser verification, screenshots, console evidence, and prototype
  coverage checks to `webapp-testing` only when that verification artifact is
  needed; it is not a default product package stage.
- Route real Web app implementation to `webapp-builder` when the requested
  endpoint is an implemented app rather than a product prototype artifact.
- Route concrete Figma prototype generation to Figma plugin skills or a future
  design/Figma owner, treating Figma output as a projection.
- Keep live store/account mutations behind the confirmation gates inside the
  relevant store-operation skills.
- Keep detailed workflow manuals inside skill-local references when they apply
  to only one skill.

## Migration Closeout

The former product, design/UX, and GTM collection plans were reviewed during
this consolidation:

- PM upstream absorption is complete and historical. Current product-side
  routing is represented by this collection's README and lifecycle docs.
- Market operations absorption is complete for the published skills. Current
  store, launch, and growth routing is represented by this collection's README.
- Historical PM distillation receipts moved from `product-management` to
  `product-experience/docs/provenance/product-management-distillation/` so old
  collection directories can be removed without breaking provenance.
- Root `.agent/skill-distillation/product-management/` receipts are historical
  provenance only. They are retained for auditability and must be mapped
  through current `product-experience` boundaries before influencing active
  skills.
- Engineering productivity intake remains locked / paused under
  `software-engineering/PLAN.md` and is not part of this product-side
  consolidation.
