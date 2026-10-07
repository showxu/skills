# Product Requirements Source Ledger

## Accepted Receipts

| Receipt | Source slice | Local use |
| --- | --- | --- |
| `product-experience/docs/provenance/product-management-distillation/H1-ralph-prd.md` | Minimal PRD generator baseline | Clarification discipline, PRD backbone, no-build-boundary |
| `product-experience/docs/provenance/product-management-distillation/H2-dean-prd.md` | PRD development workflow | Evidence-first framing, metrics, scope, risks, dependencies, anti-patterns |
| `product-experience/docs/provenance/product-management-distillation/H3-phuryn-create-prd.md` | Create PRD workflow | Context intake, pre-write reasoning, clear stakeholder wording |
| `product-experience/docs/provenance/product-management-distillation/H6-alireza-toolkit.md` | Product manager toolkit PRD subset | Template mode selection, PRD lifecycle, pitfalls, metrics prompts |
| `product-experience/docs/provenance/product-management-distillation/H8-pop-deliver-prd.md` | Deliver PRD workflow | PRD timing, metric rigor, scope partitioning, quality checklist |
| `.agent/skill-distillation/product-management/divikwu-product-requirement-craft__requirement-writer-chain__receipt.md` | Problem Framing -> SRD -> PRD chain | Material-decision clarification, conditional PRD sections, readiness scoring, PM/backend split |
| `.agent/skill-distillation/product-management/skills/product-requirements/jamesrochabrun-skills-prd-generator__prd-generator-checklist__receipt.md` | Minimal PRD checklist | Context checklist, readiness checks, metric prompts, placeholder/TBD discipline |
| `.agent/skill-distillation/product-management/github-awesome-copilot-product-prd__prd-and-breakdown-skills__receipt.md` | PRD and Epic/Feature breakdown rows | Downstream-consumable readiness, anti-vague requirements, and technical boundary evidence |

## Local Decisions

- `product-requirements` owns the integrated product specification source of
  truth: PRD, requirements, user stories, acceptance criteria, feature-level
  success metrics, business rules, constraints, risks, open questions, and
  traceability.
- User stories and acceptance criteria are sections of this requirements source,
  not separate public product-experience skills.
- Discovery, prioritization, metrics frameworks, GTM execution, and project
  management mechanics are retained as deferred or moved rows, not absorbed into
  this skill.
- Sprint calendars, milestone schedules, and timeline commitments remain outside
  this skill and are treated as planning-owner concerns.
- Technical design, task breakdown, code/build work, and QA automation route
  outside `product-experience`.
- Design artifacts may be cited as evidence, but visual design authority stays
  outside this skill.
- Optional PRD sections are conditional. Include them when the project context
  warrants them, not as boilerplate.
- Requirements readiness is a product quality check; it does not authorize
  code/build task breakdown or project schedules.

## Conservation Notes

- Most source rows are `compressed` because the local skill did not exist before
  this first-wave authoring pass.
- Source examples seed `references/example.md` and `references/eval-fixtures.md`
  but are not copied as local prose.
- Upstream cursor movement is owned by `any-to-skill` closeout, not this
  skill.
