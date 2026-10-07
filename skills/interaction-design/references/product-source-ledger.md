# Interaction Design Product Source Ledger

## Accepted Receipts

| Source | Source slice | Local use |
| --- | --- | --- |
| Product-management first-wave routing provenance | First-wave routing and product interaction ownership decision | Historical provenance, superseded by hard three-stage consolidation |
| Product feature kickoff provenance | Multi-artifact sequencing for feature kickoff | Historical sequencing evidence; local consolidation now places interaction design after integrated requirements |
| Code-to-product evidence provenance | Evidence extraction and uncertainty handling | Guidance for treating code observations as evidence, not intent |
| Product package-readiness distillation | Edge-case catalog and package readiness | Confirms edge states, boundary conditions, and recovery paths belong in interaction design and requirements acceptance sections, not QA automation |
| Interaction and wireframe upstream distillation | Interaction, wireframe, Apple-platform, renderer-boundary, Figma handoff, and prototype-validation upstream segments | Adds state-machine, wireframe semantics, product prototype contract, projection coverage, target handoff, projection gap, validation evidence, and richer open-decision semantics while moving renderer execution, Figma operations, app rendering, visual design, and review authority out |

## Local Decisions

- `interaction-design` is the only public interaction-design entrypoint after
  product-experience consolidation.
- It owns product behavior, flow requirements, screen anatomy, wireframe
  semantics, platform-aware interaction intent, product prototype contracts,
  downstream projection notes, and UX interaction-quality review.
- Visual design authority, final HIG interpretation, polished copy, and
  code/build mechanics remain out of scope.
- Interaction output should be traceable to requirements and usable by
  requirements refinements, downstream projection, and prototype coverage
  verification.
- Evidence from code or design is allowed, but conflicting behavior must be
  surfaced as a product decision checkpoint.
- Product prototype contracts, projection coverage, projection target notes,
  and projection gaps are product-owned constraints derived from
  `interaction_model`; they do not choose or implement downstream renderers.
- Actions describe user or system triggers and intent. Transitions describe
  screen or state changes caused by actions.

## Conservation Notes

- Because no dedicated upstream interaction skill was pinned for first wave,
  this skill is local-first and anchored to collection routing decisions.
- Source evidence from kickoff, code-to-product, interaction, wireframe,
  renderer-boundary, Figma handoff, and prototype-validation receipts was
  compressed into product-experience workflow language.
