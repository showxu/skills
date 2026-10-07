# Product Documentation Source Ledger

## Accepted Receipts

| Receipt | Source slice | Local use |
| --- | --- | --- |
| `docs/provenance/product-management-distillation/H11-pop-utility-feature-kickoff.md` | Feature kickoff sequencing and multi-artifact workflow | Historical sequencing evidence, compressed into the current three-stage orchestrator |
| `docs/provenance/product-management-distillation/B1-product-doc-first-wave-routing.md` | First-wave routing and ownership split | Historical provenance; superseded by hard three-stage consolidation |
| `.agent/skill-distillation/product-management/product-on-purpose-pm-skills__pm-taxonomy-commands-and-workflows__receipt.md` | PM taxonomy and workflow orchestration | Preserves skills-versus-workflows boundary and non-PM route boundaries |
| `.agent/skill-distillation/product-management/github-awesome-copilot-product-prd__prd-and-breakdown-skills__receipt.md` | Epic and Feature PRD breakdown rows | Preserves parent context, Epic-to-feature traceability, package readiness, and non-owned technical architecture boundary |
| `.agent/skill-distillation/product-management/alirezarezvani-claude-skills-product-prd__product-discovery__receipt.md` | Product Discovery | Routes direction discovery, assumption mapping, evidence strength, and proceed/pivot/stop decisions as the first canonical stage when needed |
| `.agent/skill-distillation/product-management/snarktank-ralph-prd__prd-to-executable-item-boundary__receipt.md` | PRD-to-executable boundary | Preserves package-level readiness, blocker, dependency, and verifiable-criteria signals without execution mechanics |
| `.agent/skill-distillation/product-management/wave5-discovery-strategy__receipt.md` | Strategy and discovery expansion | Compresses feature-level positioning and value proposition into discovery and requirements while keeping macro strategy out of the default package flow |
| `.agent/skill-distillation/product-management/wave5-prioritization-package-readiness__receipt.md` | Prioritization, edge cases, and package readiness | Preserves package readiness, blocker, dependency, current-boundary checks, and defers multi-candidate roadmap prioritization out of the default feature flow |

## Local Decisions

- `product-documentation` is a Product Documentation package orchestrator. It
  owns routing state, package readiness, source references, source-of-truth
  validation, product documentation path guidance, and package integration
  verification, not full stage artifact detail or generic repository
  documentation normalization.
- Feature-package routing is limited to `product-discovery`,
  `product-requirements`, and `interaction-design`.
- Superseded product-stage evidence is provenance only. It does not define
  routing or redirects.
- Product discovery is the direction-discovery stage.
- Product requirements is the integrated product specification stage.
- Product interaction design is the behavior and interaction source stage.
- Rendered artifacts are downstream projections, not product sources of truth.
- Downstream prototype artifact generation is routed to existing non-PM owners
  when available: `frontend-design` for visual UI projection,
  `web-artifacts-builder` for shareable HTML prototype artifacts, Figma plugin
  `figma-generate-design` plus `figma-use` for Figma product prototypes, and
  `webapp-testing` or Build Web Apps `frontend-testing-debugging` for
  prototype coverage verification.
- Anthropic `webapp-testing` is integrated locally as the same-name
  `webapp-testing` generic Web skill. Anthropic `frontend-design` and
  `web-artifacts-builder` are installed as root generic Web skills; real Web
  app implementation is handled by `webapp-builder`.
- Code/build planning, technical design, UX craft, visual design, QA
  automation, concrete renderer execution, and GTM execution remain outside
  this skill.
- Parent initiative or Epic context is package traceability and reading-order
  metadata, not leaf PRD ownership.
- Prototype generation handoff notes are source indexes, blockers, coverage
  expectations, gaps, and product constraints. They are not design specs,
  technical designs, code/build plans, QA automation, or launch execution.

## Conservation Notes

- Source workflow guidance was compressed into local, collection-scoped product
  language.
- Upstream command mechanics were intentionally not preserved.
- Historical source names in distillation receipts are provenance only and do
  not define active routing.
