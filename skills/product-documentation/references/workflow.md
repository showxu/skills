# Product Documentation Workflow

## 1. Intake

Capture:

- Package level and parent context, such as initiative, Epic, feature, or
  package hierarchy when supplied.
- Feature objective and expected outcome.
- Current target product boundary: what the user wants this product or feature
  to become now.
- Current canonical artifact availability.
- Evidence sources and confidence.
- Measurement assumptions when present.
- Time constraints and decision deadlines as risks or dependencies, not
  delivery schedules.

If objective or current product boundary is missing, create a draft intake and
mark assumptions. Do not shrink the requested target just because it is large.
If the missing objective, boundary, package level, or parent context would
materially change placement, stage routing, downstream dispatch, or package
readiness, stop at intake, surface the decision needed, and ask before routing
leaf artifact work or writing the final package graph.

## 2. Placement And Package Graph

Determine the Product Documentation root before routing leaf artifact work.
This skill owns placement strategy, package graph, source graph, and reading
order; stage skills own artifact content only.

Default path rules:

- Use an existing repository product documentation convention when one is
  already established.
- Otherwise, a single-product repository uses `Documentation/Product/` as the
  product root.
- A true multi-product repository or monorepo adds exactly one slug layer:
  `Documentation/Product/<product-slug>/`.
- `Features/<feature-slug>/` always lives under the selected product root.
- Do not use `Documentation/Product/Products/<product-slug>/`.
- Do not introduce `Surfaces/` by default; add it only when the repository has
  a proven surface-level product documentation convention.

Record the package graph with:

- Product root.
- Package path.
- Source artifact paths.
- Prototype handoff path.
- Retained prototype source path when editable artifact source is worth keeping.
- `.agent/product-prototype-runs/<product-slug>/<run-id>/` snapshot path when a
  generated run should be auditable but not part of canonical Product
  Documentation.
- Downstream artifact refs and returned coverage/gap reports when they exist.

Do not ask `product-discovery`, `product-requirements`, `interaction-design`,
`frontend-design`, or `web-artifacts-builder` to decide where Product
Documentation files should live.

When a downstream HTML/Figma/review artifact workflow creates intermediate
source files, keep placement decisions here:

- Keep the current editable source for a retained prototype under
  `Prototype/source/` beside the brief, coverage report, and rendered artifact.
- Keep run snapshots and temporary generation evidence under
  `.agent/product-prototype-runs/<product-slug>/<run-id>/`.
- Do not place run histories under `Documentation/Product/Prototype/runs/`.
- Downstream artifact skills return artifact refs, source refs, coverage, gaps,
  assumptions, and blockers; they do not decide retention policy.

## 3. Artifact Routing

Route only to the three canonical product-experience stage skills:

- Product direction discovery, including problem framing, users/scenarios,
  opportunity framing, solution brainstorming, lightweight strategy, tradeoffs,
  direction selection, risks, assumptions, evidence strength, and PRD-ready
  decision inputs -> `product-discovery`
- Product specification, including PRD, scope, non-goals, functional
  requirements, user stories, acceptance criteria, feature-level success
  metrics, business rules, constraints, risks, open questions, and traceability
  -> `product-requirements`
- Product interaction design, including canonical `interaction_model`,
  `platform_context`, flows, screens, screen anatomy, wireframe semantics,
  states, actions, transitions, components, validation, feedback, recovery,
  edge cases, open decisions, platform-aware interaction semantics, and
  product prototype contract and downstream prototype projection notes ->
  `interaction-design`

Stay in `product-documentation` for parent initiative context, package
reading order, routing state, source-of-truth validation, package readiness,
thin `prototype_artifact_brief` packaging, downstream prototype dispatch, and
final consistency verification.

Route non-feature-package work outside this stage flow:

- UX interaction review, HIG interpretation, visual design, UX writing, and
  design systems -> `interaction-design`, platform guidance, `ux-writing`, or
  design-system owners by scope.
- HTML/frontend product prototype artifact generation -> first package a thin
  `prototype_artifact_brief` from ready product sources, then dispatch to
  `frontend-design` for visual UI projection and `web-artifacts-builder` for
  shareable HTML artifact generation when available.
- Figma product prototype artifact generation -> first package a thin
  `prototype_artifact_brief` from ready product sources, then dispatch to
  Figma plugin skills such as `figma-generate-design` plus `figma-use` when
  available, with Figma treated as a projection.
- Prototype artifact verification -> `webapp-testing`, Build Web Apps
  `frontend-testing-debugging`, Browser, or Playwright when available, with
  coverage checked against the `prototype_artifact_brief` and its referenced
  source artifacts.
- Technical design, real Web app implementation, code/build tasks, QA
  automation, test code, CI, and app architecture -> software-engineering
  owners such as `webapp-builder` by scope.
- Market launch, ASO, SEO, paid acquisition, and channel performance ->
  product-experience store, launch, and growth owners.

If only one canonical stage artifact is requested, hand off directly to that
stage instead of forcing full package integration.

## 4. Sequencing

Default sequence:

1. Product discovery, marked `Ready` or `Not needed`.
2. Product requirements / PRD.
3. Product interaction design.
4. Prototype artifact generation and verification.

Sequence can change when the user starts from an existing artifact, but final
package verification still checks all three stage boundaries.

Discovery is required before requirements when the package needs direction
selection, evidence strength, assumption mapping, problem validation, solution
validation, or a proceed/pivot/stop decision. Mark it `Not needed` only when
the direction is already validated or the user explicitly scopes discovery out.

Feature-level success metrics are part of requirements. Deeper analytics,
instrumentation, experiments, dashboards, and result reviews are outside the
feature-package stage flow in this consolidation.

## 5. Necessary Orchestration

Use this skill only where orchestration adds package value:

- Single-stage content requests go directly to the owning leaf skill.
- Cross-artifact work, conflict handling, prototype readiness, downstream
  artifact dispatch, and final coverage verification stay here.
- HTML, Figma, and review artifact generation are dispatched from here based on
  product source readiness; this skill does not render those artifacts.
- Downstream artifact results return here as artifact references, coverage
  results, unsupported items, assumptions, and blockers.

## 6. Stage Boundary

Stage skills own create, revise, and review for their own artifacts. This skill
owns package intake, routing state, reading order, thin handoff manifest
structure, placement strategy, package graph, downstream dispatch decisions,
and final consistency verification.

This skill may draft package-level intake, status, summary, and handoff notes.
It must not produce full discovery, requirements, or interaction-design
artifacts as its owned output.

## 7. Prototype Artifact Brief

When downstream prototype artifact generation is requested, produce a thin
`prototype_artifact_brief`. It is a routing manifest and coverage index, not a
second product spec.

The brief may include:

- Source-of-truth references: discovery, requirements, interaction design,
  `interaction_model`, `product_prototype_contract`, and optional `design.md`.
- Target projection: HTML product prototype, Figma product prototype,
  prototype review, or another explicitly requested target.
- Downstream dispatch: visual UI projection owner, artifact builder owner,
  Figma owner when available, and optional verification owner.
- Included model IDs: flows, screens, states, actions, transitions, acceptance
  criteria, or prototype-contract IDs that must be represented.
- Excluded, placeholder, or blocked IDs with reason and whether a placeholder is
  allowed.
- Output expectations: artifact path/reference, represented IDs, uncovered IDs,
  unsupported behavior, assumptions, blockers, and verification result.
- Source retention: current editable source path if retained, run snapshot path
  if kept under `.agent`, and which generated files are intentionally discarded.

The brief must not copy or rewrite flows, screens, states, actions,
transitions, validation rules, feedback behavior, recovery paths, or other
facts owned by requirements or interaction design.

## 8. Decision Checkpoints

Create explicit checkpoints when:

- Discovery and requirements disagree on scope or target users.
- Requirements and interaction design disagree on behavior, business rules, or
  edge cases.
- Evidence quality is low.
- The current target product boundary is ambiguous or internally inconsistent.
- A downstream prototype projection would require a product decision not yet
  represented in a structured source artifact.
- A requested `prototype_artifact_brief` would need to include, omit, or
  placeholder source model IDs without a clear product decision.

Checkpoint output should include options, consequences, owner, needed-by
artifact, and recommended current target decision when evidence or user intent
supports one.

## 9. Integration Pass

Use `references/template.md` to consolidate:

- Parent context, package level, and reading order.
- Product root, package path, source graph, and stage artifact paths.
- Discovery recommendation and evidence status.
- Current target product boundary and metrics readiness in requirements.
- Requirements scope, stories, acceptance criteria, business rules, and
  traceability.
- Interaction-design source status, open decisions, and prototype projection
  notes.
- Product prototype contract, including required screens, flows, click paths,
  states, validation, feedback, recovery, gaps, blockers, and verification
  expectations.
- Cross-artifact consistency checks.
- Open decisions, risks, and dependencies.
- `prototype_artifact_brief` as source-artifact links, target projection,
  included model IDs, excluded/placeholder IDs, blocker indexes, coverage
  expectations, downstream owner choices, and expected artifact outputs.
- Downstream prototype target availability and owner selection when known.
- Downstream artifact references and returned coverage/gap reports when
  artifacts already exist.
- Retained prototype source references and `.agent` run snapshots when source or
  generation evidence should remain auditable.
- Next artifact actions.

Keep output at product decision and routing level. Do not add code/build tasks,
visual design specs, UX craft critique, QA automation, concrete renderer
execution, or launch execution.

## 10. Final Validation

Before final output:

- Confirm Product Documentation placement follows the repository convention or
  the default single-product / multi-product rules.
- Confirm no active package path uses
  `Documentation/Product/Products/<product-slug>/`.
- Confirm stage and downstream skills were not asked to own placement strategy.
- Confirm retained editable prototype source, if any, lives under
  `Prototype/source/`, and run snapshots, if any, live under `.agent` rather
  than Product Documentation.
- Confirm each missing canonical artifact is explicitly queued with stage
  owner, status, dependency, and required input.
- Confirm discovery is routed to `product-discovery` when direction discovery
  is needed.
- Confirm requirements include feature-level success metrics and traceability.
- Confirm interaction design uses `interaction-design` as the behavior
  source.
- Confirm rendered artifacts are projections, not visual design, app build
  claims, product sources of truth, or product-stage source artifacts.
- Confirm parent initiative or Epic context remains package traceability, not
  leaf PRD ownership.
- Confirm `prototype_artifact_brief` is a thin manifest that references source
  artifacts and model IDs without duplicating the `interaction_model` or
  redefining behavior.
- Confirm prototype handoff notes are product prototype contract links, source
  indexes, target dispatch, coverage expectations, downstream artifact refs,
  and blockers, not technical design or visual design artifacts.
- Confirm accepted feedback has been normalized into the current contract and
  rejected intermediate options leave no residual labels, explanations, or
  duplicated rules unless they remain explicit current non-goals or
  invariants.
- Confirm non-owned domains are routed by responsibility.
