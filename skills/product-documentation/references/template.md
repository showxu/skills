# Product Documentation Package Template

## Header

- Product, feature, or initiative:
- Package level: Product / Initiative / Epic / Feature / Package
- Parent initiative or Epic:
- Package owner:
- Status: Draft | In review | Approved | Superseded
- Last updated:
- Product documentation root:
- Package path:

## Objective

- Problem:
- Proposed product change:
- Target users:
- Expected outcome:

## Current Product Boundary

State the accepted current boundary directly. Do not list a discarded
intermediate request under **Deliberately Out Of Current Target** unless its
exclusion remains a meaningful current product decision.

### In Current Target

- ...

### Deliberately Out Of Current Target

- ...

### Future Opportunities

- ...

## Source Evidence

| Evidence | Source | Confidence | Notes |
| --- | --- | --- | --- |
|  |  | High / Medium / Low |  |

## Stage Routing Status

| Stage | Owner | Status | Source link | Open dependencies |
| --- | --- | --- | --- | --- |
| Product discovery | `product-discovery` | Ready / In progress / Missing / Not needed |  |  |
| Requirements | `product-requirements` | Ready / In progress / Missing |  |  |
| Interaction design | `interaction-design` | Ready / In progress / Missing |  |  |

## Package Reading Order

| Order | Artifact | Why this order matters |
| --- | --- | --- |
| 1 | Discovery |  |
| 2 | Requirements |  |
| 3 | Interaction design |  |
| 4 | Prototype artifact generation / verification |  |

## Package Graph And Placement

`product-documentation` owns placement strategy, package graph, source graph,
reading order, prototype handoff placement, and downstream coverage/gap
collection. Stage skills own artifact content only.

| Node | Path / Reference | Owner | Notes |
| --- | --- | --- | --- |
| Product root |  | `product-documentation` | Single product: `Documentation/Product/`; multi-product: `Documentation/Product/<product-slug>/` |
| Package summary |  | `product-documentation` |  |
| Discovery artifact |  | `product-discovery` | Content owner only |
| Requirements artifact |  | `product-requirements` | Content owner only |
| Interaction-design artifact |  | `interaction-design` | Content owner only |
| Prototype handoff |  | `product-documentation` | Thin `prototype_artifact_brief` and coverage index |
| Retained prototype source |  | `product-documentation` | Current editable source only, when retained |
| Prototype run snapshot |  | `product-documentation` | `.agent/product-prototype-runs/<product-slug>/<run-id>/`, when retained |
| Downstream prototype artifact refs |  | Downstream artifact skills | Return refs, coverage, gaps, assumptions, and blockers only |

## Cross-Artifact Consistency Check

| Check | Result | Notes |
| --- | --- | --- |
| Current target boundary is explicit and not silently reduced | Pass / Risk / Open |  |
| Discovery recommendation supports requirements boundary | Pass / Risk / Open |  |
| Requirements include feature-level success metrics | Pass / Risk / Open |  |
| Requirements stories and acceptance criteria trace to requirements | Pass / Risk / Open |  |
| Requirements business rules align with interaction behavior | Pass / Risk / Open |  |
| Interaction design traces to requirements | Pass / Risk / Open |  |
| Interaction-design open decisions include prototype generation / verification blocking semantics | Pass / Risk / Open |  |
| Rendered artifacts are treated as projections, not product truth | Pass / Risk / Open |  |
| Evidence conflicts are labeled | Pass / Risk / Open |  |

## Decision Needed

| Decision | Options | Recommended option | Owner | Needed by |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Risks And Dependencies

| Item | Type | Owner | Impact | Mitigation |
| --- | --- | --- | --- | --- |
|  | Dependency / Risk |  |  |  |

## Prototype Generation Handoff

### Source Artifacts

- Discovery artifact:
- Requirements artifact:
- Interaction-design artifact:
- Product prototype contract from interaction design:
- Optional `design.md`:

### Prototype Targets

- Figma product prototype: Available / Unavailable / Not needed
  - Downstream owner when available: Figma plugin `figma-generate-design` plus `figma-use`
- HTML product prototype / review artifact: Available / Unavailable / Not needed
  - Downstream owner when available: `frontend-design` for visual UI projection; `web-artifacts-builder` for shareable HTML artifact generation
- Prototype coverage verification: Available / Unavailable / Not needed
  - Downstream owner when available: `webapp-testing`, Build Web Apps `frontend-testing-debugging`, Browser, or Playwright
- Prototype review only: Available / Unavailable / Not needed

### Prototype Coverage Verification

- Required flows covered:
- Required screens covered:
- Required states covered:
- Required actions and transitions covered:
- Product prototype contract coverage:
- Unsupported or blocked items:
- Product constraints projections must preserve:

### prototype_artifact_brief

This is a thin routing manifest and coverage index. It must reference source
artifacts and model IDs only; do not copy or redefine flows, screens, states,
actions, transitions, validation, feedback, recovery, or edge-case behavior.

```yaml
prototype_artifact_brief:
  target: html_product_prototype | figma_product_prototype | prototype_review | other
  source_of_truth:
    discovery:
    requirements:
    interaction_design:
    interaction_model:
    product_prototype_contract:
    optional_design_md:
  target_projection:
    audience: product_review | design_review | stakeholder_review | other
    platform_shell:
    downstream_skills:
      visual_surface:
      artifact_builder:
      figma:
      verification:
  include_model_ids:
    flows: []
    screens: []
    states: []
    actions: []
    transitions: []
    acceptance_criteria: []
    prototype_contract_items: []
  exclude_or_placeholder:
    - model_id:
      reason:
      allowed_placeholder: false
      blocks_generation: false
      blocks_verification: false
  output_expectations:
    artifact_reference:
    retained_source_reference:
    run_snapshot_reference:
    represented_model_ids_report: required | not_needed
    uncovered_model_ids_report: required | not_needed
    unsupported_items_report: required | not_needed
    assumptions_report: required | not_needed
    blocker_report: required | not_needed
```

### Downstream Artifact Results

| Target | Owner | Artifact reference | Coverage result | Gaps / unsupported items | Blockers |
| --- | --- | --- | --- | --- | --- |
| HTML / Figma / Review |  |  | Covered / Partial / Blocked / Not produced |  |  |

### Prototype Source Retention

`product-documentation` decides whether artifact source and run evidence are
retained. Downstream artifact skills return references only.

| Item | Path / Reference | Retention decision | Notes |
| --- | --- | --- | --- |
| Current editable source | `Prototype/source/` | Retain / Do not retain | Keep only source needed to regenerate the current reviewed artifact. |
| Rendered artifact | `Prototype/artifacts/` | Retain / Do not retain | Projection artifact, not product truth. |
| Run snapshot | `.agent/product-prototype-runs/<product-slug>/<run-id>/` | Retain / Do not retain | Temporary generation workspace evidence; not part of the reading order. |
| Discarded temporary files |  | Discarded |  |

### Downstream Handoff Rules

- The brief packages existing source facts for downstream projection; it does
  not become a second product spec.
- Downstream skills must preserve referenced product behavior, report missing
  or unsupported behavior, and never silently resolve open product decisions.
- Rendered artifacts remain projections and never become product truth.

## Recommended Product Documentation Paths

Use the target repository's existing product documentation convention when it
exists. Otherwise use:

Single-product repository:

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

True multi-product repository or monorepo:

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

Do not use `Documentation/Product/Products/<product-slug>/`.
`Features/<feature-slug>/` always lives under the selected product root. Do not
introduce `Surfaces/` by default.

`Documentation/Product/*` is Product Documentation truth and projection
history. It is separate from engineering `Documentation/Architecture`,
`Documentation/Proposals`, `Documentation/Decisions`,
`Documentation/Migrations`, `Documentation/Reference`, and target DocC catalogs.

## Integrated Summary

Summarize the package in 5-10 bullets:

- ...

## Next Artifact Actions

| Action | Owner | Inputs needed | Output |
| --- | --- | --- | --- |
|  |  |  |  |

## Open Questions

| Question | Why it matters | Owner |
| --- | --- | --- |
|  |  |  |
