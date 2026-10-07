# Decision Routing Matrix

## Artifact Routing

| User intent | Primary artifact | Route decision |
| --- | --- | --- |
| "Define the product direction, target user, positioning, promise, or current target boundary for this feature" | Discovery direction | Route to `product-discovery` |
| "Brainstorm this product idea" | Discovery direction | Route to `product-discovery` |
| "Validate this opportunity before we write a PRD" | Product discovery | Route to `product-discovery` |
| "Map assumptions, evidence strength, or proceed/pivot/stop decision" | Product discovery | Route to `product-discovery` |
| "Choose what this product should include now" | Current product boundary | Route to `product-discovery` or `product-requirements`; do not force minimum-scope cuts |
| "Write a PRD, feature spec, user stories, acceptance criteria, or feature success metrics" | Requirements / PRD | Route to `product-requirements` |
| "Define product behavior, flow, states, screens, wireframe semantics, or platform-aware interaction model" | Product interaction design | Route to `interaction-design` |
| "Plan what a rendered prototype should show" | Product prototype contract | Route to `interaction-design`; concrete rendering is downstream and outside the product source stage |
| "Create a concrete clickable HTML or frontend product prototype" | Downstream HTML/frontend prototype artifact generation | Stay in `product-documentation` long enough to verify product source readiness and package a thin `prototype_artifact_brief`; then dispatch to `frontend-design` for visual UI projection and `web-artifacts-builder` for shareable HTML artifact generation when available |
| "Create a Figma product prototype" | Downstream Figma prototype artifact generation | Stay in `product-documentation` long enough to verify product source readiness and package a thin `prototype_artifact_brief`; then dispatch to Figma plugin skills such as `figma-generate-design` with `figma-use` when available |
| "Verify this prototype covers the product behavior" | Downstream prototype artifact verification | Stay in `product-documentation` for coverage expectations and final verification; route browser/runtime checks to `webapp-testing`, Build Web Apps `frontend-testing-debugging`, Browser, or Playwright when available |
| "Organize this Epic or parent initiative into feature package artifacts" | Package hierarchy and routing state | Stay in `product-documentation` for parent context, reading order, artifact dependencies, and handoff notes |
| "Give me complete product package docs" | Integrated feature package | Stay in `product-documentation` for scheduling, package state, and cross-artifact verification |

## Boundary Routing

| Request shape | Owner decision |
| --- | --- |
| Full discovery content, revision, or review | Route to `product-discovery`; keep package state here |
| Full PRD / product spec content, revision, or review | Route to `product-requirements`; keep package state here |
| Full interaction-design content, revision, or review | Route to `interaction-design`; keep package state here |
| Complete product prototype package, source readiness review, downstream artifact dispatch, or prototype coverage verification | Stay in `product-documentation`; package `prototype_artifact_brief` only as a source-reference manifest and coverage index |
| Product direction, positioning, value proposition, or current target boundary | Route full direction content to `product-discovery`; keep only package links and status here |
| Feature-level success metrics | Route to `product-requirements`; keep only package links and status here |
| Technical design, real Web app implementation, architecture, code/build tasks, test code, or concrete renderer execution | Route to software-engineering owners such as `webapp-builder` by scope |
| UX interaction review, HIG interpretation, visual design systems, or UX writing | Route to `interaction-design`, platform guidance, design-system, or `ux-writing` owners by scope |
| Market launch copy, ASO, paid acquisition, store execution, or GTM performance | Route to product-experience store, launch, and growth owners |

## Downstream Prototype Routing

These skills are downstream projection owners, not product source-of-truth
owners. Use them only after requirements and interaction design are ready or
the missing inputs are explicitly listed as blockers.

| Prototype target | Preferred downstream owner when available | Contract |
| --- | --- | --- |
| HTML product prototype / frontend review artifact | `frontend-design` for visual UI projection; `web-artifacts-builder` for shareable HTML artifact generation | Use a creator-packaged `prototype_artifact_brief` that references requirements, `interaction_model`, `product_prototype_contract`, included model IDs, HTML notes, and optional `design.md`; preserve referenced behavior and report unsupported items |
| Figma product prototype | Figma plugin `figma-generate-design` plus `figma-use` | Use a creator-packaged `prototype_artifact_brief` that references requirements, `interaction_model`, `product_prototype_contract`, included model IDs, Figma notes, and optional `design.md`; do not treat Figma as product truth |
| Prototype artifact verification | `webapp-testing`, Build Web Apps `frontend-testing-debugging`, Browser, or Playwright | Verify rendered coverage against the `prototype_artifact_brief` and its referenced source artifacts; report gaps, unsupported states, and blocked open decisions |

The `prototype_artifact_brief` is not a product source artifact. It must
reference source artifacts and model IDs instead of copying flows, screens,
states, actions, transitions, validation rules, feedback behavior, or recovery
paths.

## Evidence Handling

| Evidence type | Treatment |
| --- | --- |
| Existing code | Observed build evidence; not product intent |
| Existing design artifacts | Evidence input only; not visual design authority |
| Stakeholder notes | Candidate product intent; verify conflicts |
| Analytics and support data | Product evidence with confidence labels |
| Rendered artifacts | Projection evidence only; not product source of truth |

## Conflict Resolution

When artifacts conflict:

1. Record conflict pair and exact claim in package state.
2. Identify decision owner and deadline.
3. Offer options and consequences.
4. Keep unresolved items visible in `Decision Needed`.

Do not silently pick one conflicting artifact unless the user explicitly decides
or a source-of-truth owner is clear.

## Sequence Overrides

Override default sequence when:

- Evidence is too weak to enter PRD-ready framing; run discovery before
  requirements.
- Product direction, positioning, value proposition, or current target boundary
  is unresolved; run discovery before requirements.
- Requirements are mostly complete and only interaction design is missing.
- Interaction behavior is settled but downstream prototype artifact generation
  is requested; keep product sources in product-experience and route concrete
  rendering outside the product source stage.
- User asks for a constrained package slice with strict deadline.

In overrides, still produce package-level routing state and open decisions.
