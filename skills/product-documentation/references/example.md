# Product Documentation Package Example: Apple Native Saved Report Filters

## Header

- Feature or initiative: Saved Report Filters
- Package level: Feature
- Parent initiative or Epic: iPadOS reporting workflow improvements
- Package owner: Product
- Status: Draft
- Last updated: 2026-05-10
- Product documentation root: `Documentation/Product/` (single-product repo)
- Package path: `Documentation/Product/Features/saved-report-filters/Feature-Package.md`

## Objective

- Problem: Reporting users repeatedly rebuild the same filters for recurring
  analysis on iPad and Mac.
- Proposed product change: Let users save, reuse, and manage personal filter
  sets in the native reporting app.
- Target users: Analysts and team leads.
- Expected outcome: Faster repeat analysis and fewer setup errors.

## Current Product Boundary

### In Current Target

- Save current filters with a required name.
- Apply saved filters.
- Rename and delete saved filters.
- Support iPadOS as primary platform and macOS as secondary platform.

### Deliberately Out Of Current Target

- Team-shared filters.
- Report templates and scheduled delivery.
- Final visual design and concrete prototype rendering.

### Future Opportunities

- Team sharing and admin controls.

## Source Evidence

| Evidence | Source | Confidence | Notes |
| --- | --- | --- | --- |
| Users rebuild similar filters weekly | Support and interview notes | Medium | Needs baseline metric |
| Current setup takes multiple steps | Product walkthrough | High | Observed behavior |
| Shared views requested by team leads | Customer success notes | Medium | Future opportunity unless Product expands the current target |

## Stage Routing Status

| Stage | Owner | Status | Source link | Open dependencies |
| --- | --- | --- | --- | --- |
| Product discovery | `product-discovery` | Ready | `Discovery.md` | Baseline metric remains open |
| Requirements | `product-requirements` | Ready | `Requirements.md` | Apply behavior decision affects acceptance section |
| Interaction design | `interaction-design` | In progress | `Interaction-Design.md` | Merge vs replace decision |

## Package Reading Order

| Order | Artifact | Why this order matters |
| --- | --- | --- |
| 1 | Discovery | Confirms repeated user pain and records team sharing as outside the current target |
| 2 | Requirements | Defines current product boundary, stories, acceptance criteria, business rules, and feature metrics |
| 3 | Interaction design | Defines platform-aware flows, screens, states, transitions, and open decisions |
| 4 | Prototype verification | Confirms source alignment before downstream prototype artifact generation or review |

## Package Graph And Placement

| Node | Path / Reference | Owner | Notes |
| --- | --- | --- | --- |
| Product root | `Documentation/Product/` | `product-documentation` | Single-product repository root |
| Package summary | `Documentation/Product/Features/saved-report-filters/Feature-Package.md` | `product-documentation` | Package state, source graph, reading order, and coverage collection |
| Discovery artifact | `Documentation/Product/Features/saved-report-filters/Discovery.md` | `product-discovery` | Content owner only |
| Requirements artifact | `Documentation/Product/Features/saved-report-filters/Requirements.md` | `product-requirements` | Content owner only |
| Interaction-design artifact | `Documentation/Product/Features/saved-report-filters/Interaction-Design.md` | `interaction-design` | Content owner only |
| Prototype handoff | `Documentation/Product/Features/saved-report-filters/Prototype/prototype_artifact_brief.md` | `product-documentation` | Thin manifest; references source artifacts and model IDs only |
| Retained prototype source | `Documentation/Product/Features/saved-report-filters/Prototype/source/` | `product-documentation` | Current editable artifact source only when a generated prototype is retained |
| Prototype run snapshot | `.agent/product-prototype-runs/saved-report-filters/<run-id>/` | `product-documentation` | Optional auditable run evidence, outside Product Documentation reading order |

## Cross-Artifact Consistency Check

| Check | Result | Notes |
| --- | --- | --- |
| Current target boundary is explicit and not silently reduced | Pass | Personal saved filters are the current target |
| Discovery recommendation supports requirements boundary | Pass | Discovery supports personal saved filters and records sharing as future opportunity |
| Requirements include feature-level success metrics | Risk | Metric is defined, baseline remains open |
| Requirements stories and acceptance criteria trace to requirements | Pass | Requirements contain story and acceptance sections |
| Requirements business rules align with interaction behavior | Open | Apply behavior depends on merge vs replace decision |
| Interaction design traces to requirements | Pass | Interaction IDs reference requirements, stories, and acceptance criteria |
| Interaction-design open decisions include prototype generation / verification blocking semantics | Pass | Apply behavior blocks downstream prototype generation and verification |
| Rendered artifacts are treated as projections, not product truth | Pass | Rendering remains downstream |
| Evidence conflicts are labeled | Pass | Sharing demand kept as later scope |

## Decision Needed

| Decision | Options | Recommended option | Owner | Needed by |
| --- | --- | --- | --- | --- |
| Applying a saved filter replaces or merges current filters | Replace all, merge fields, or prompt user choice | Replace all for product consistency | Product | Before interaction-design approval |

## Risks And Dependencies

| Item | Type | Owner | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| Filter state persistence approach | Dependency | External build owner | Affects reliability and scope | Code/build design after product behavior is final |
| Missing baseline analytics | Risk | Product and data | Weak metric target confidence | Add event baseline as downstream evidence work |

## Prototype Generation Handoff

### Source Artifacts

- Discovery artifact: `Discovery.md`.
- Requirements artifact: `Requirements.md`.
- Interaction-design artifact: `Interaction-Design.md`.
- Optional `design.md`: Not supplied.

### Prototype Targets

- Figma product prototype: Available through downstream prototype artifact generation after `D-1` is resolved.
- HTML product prototype / review artifact: Available through downstream prototype artifact generation after `D-1` is resolved.
- Prototype review only: Available now if `D-1` is explicitly marked as an unresolved placeholder.

### Prototype Coverage Verification

- Required flows covered: Save, apply, rename, and delete saved filters.
- Required screens covered: Report filters, saved filter panel, save modal,
  rename confirmation, and delete confirmation.
- Required states covered: Default, loading, validation error, empty saved list,
  delete confirmation, apply failure, and permission-denied if scoped later.
- Unsupported or blocked items: Final apply behavior is not settled.
- Product constraints projections must preserve: Personal saved filters are the
  current target; team sharing is outside the current target unless Product
  changes that boundary.

### prototype_artifact_brief

```yaml
prototype_artifact_brief:
  target: html_product_prototype
  source_of_truth:
    discovery: Discovery.md
    requirements: Requirements.md
    interaction_design: Interaction-Design.md
    interaction_model: Interaction-Design.md#interaction_model
    product_prototype_contract: Interaction-Design.md#product_prototype_contract
    optional_design_md: null
  target_projection:
    audience: product_review
    platform_shell: browser_projection_of_ipados_native_app
    downstream_skills:
      visual_surface: frontend-design
      artifact_builder: web-artifacts-builder
      figma: null
      verification: webapp-testing_optional
  include_model_ids:
    flows: [F-save-filter, F-apply-filter, F-rename-filter, F-delete-filter]
    screens: [S-report-filters, S-saved-filter-panel, S-save-modal, S-rename-confirmation, S-delete-confirmation]
    states: [ST-default, ST-loading, ST-validation-error, ST-empty-saved-list, ST-apply-failure]
    actions: [A-save-filter, A-apply-filter, A-rename-filter, A-delete-filter]
    transitions: [T-open-save-modal, T-save-success, T-apply-filter, T-delete-confirm]
    acceptance_criteria: [AC-save-required-name, AC-apply-saved-filter, AC-rename-filter, AC-delete-filter]
    prototype_contract_items: [PC-required-screens, PC-required-click-paths, PC-required-validation-feedback]
  exclude_or_placeholder:
    - model_id: D-1
      reason: Apply behavior remains unresolved.
      allowed_placeholder: true
      blocks_generation: true
      blocks_verification: true
  output_expectations:
    artifact_reference: bundle.html or downstream artifact link
    retained_source_reference: Prototype/source/ when source is retained
    run_snapshot_reference: .agent/product-prototype-runs/saved-report-filters/<run-id>/ when retained
    represented_model_ids_report: required
    uncovered_model_ids_report: required
    unsupported_items_report: required
    assumptions_report: required
    blocker_report: required
```

This brief references source artifacts and model IDs only. The interaction
details stay in `Interaction-Design.md`; the brief is not a second product spec.

### Downstream Artifact Results

| Target | Owner | Artifact reference | Coverage result | Gaps / unsupported items | Blockers |
| --- | --- | --- | --- | --- | --- |
| HTML product prototype | `frontend-design` -> `web-artifacts-builder` | Not produced | Blocked | Apply behavior placeholder allowed only for review mode | `D-1` |

### Prototype Source Retention

| Item | Path / Reference | Retention decision | Notes |
| --- | --- | --- | --- |
| Current editable source | `Documentation/Product/Features/saved-report-filters/Prototype/source/` | Retain after generation | Owned by product-documentation; downstream artifact skills return source refs only |
| Rendered artifact | `Documentation/Product/Features/saved-report-filters/Prototype/artifacts/` | Retain after generation | Projection artifact, not product truth |
| Run snapshot | `.agent/product-prototype-runs/saved-report-filters/<run-id>/` | Optional | Keeps temporary generation evidence outside the reading order |

## Integrated Summary

- Product objective and current boundary are clear.
- Discovery supports proceeding with personal saved filters.
- Requirements include stories, acceptance criteria, business rules, and
  feature-level metrics.
- Interaction design is blocked by one apply-behavior decision.
- Prototype artifact generation remains a downstream projection dispatched from
  a thin `prototype_artifact_brief`.
- Cross-artifact prototype handoff is ready once merge vs replace is decided.

## Next Artifact Actions

| Action | Owner | Inputs needed | Output |
| --- | --- | --- | --- |
| Finalize filter apply behavior | Product | Decision checkpoint | Updated interaction-design source artifact |
| Align acceptance criteria with final apply behavior | Product | Final apply-behavior decision | Updated requirements acceptance section |
| Prepare `prototype_artifact_brief` | Product | Final apply-behavior decision and interaction-design source | Downstream prototype artifact dispatch and coverage/gap verification |

## Open Questions

| Question | Why it matters | Owner |
| --- | --- | --- |
| Should saved filters be report-specific or global? | Changes scope and information architecture | Product |
| Which baseline event already captures filter setup time? | Needed for measurable outcome tracking | Data |
