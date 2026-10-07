# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H8 Product On Purpose Deliver PRD Distillation Receipt

## Source Scope

- Source: `product-on-purpose-pm-skills` / `prd-delivery-family:prd`
- Commit: `2b0310d88b8e5918fd298ea4ab1f7969c9a0b8ef`
- Paths: `skills/deliver-prd/`, `commands/prd.md`
- Candidate local owner: future `product-management/skills/product-requirements/`
- Authority requirement: source process guidance only; local collection owns PRD artifact boundary
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H8-pop-deliver-prd`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| trigger boundary | PRD drafting after problem/solution alignment and before build | `product-requirements/SKILL.md` trigger | compressed | Strong timing and entry guidance | source evidence; local collection authority |
| PRD drafting recipe | Problem recap, goals, solution, requirements, scope, constraints, risks, and milestones | `product-requirements/SKILL.md` workflow and template | compressed | Coherent production flow | source evidence; local collection authority |
| metric rigor | Baselines and targets tied to problem outcomes | `product-requirements/references/template.md` and fixtures | compressed | High-value measurable behavior | source evidence; local collection authority |
| requirement quality | Testable and unambiguous requirement statements | `product-requirements/SKILL.md` and fixture checks | compressed | Essential spec quality bar | source evidence; local collection authority |
| scope partitioning | Separate in-scope, out-of-scope, and future work | `product-requirements/references/template.md` | compressed | Controls scope expansion | source evidence; local collection authority |
| constraints, dependencies, and risks | Document delivery constraints and mitigations | `product-requirements/references/template.md` | compressed | Preserves execution readiness context | source evidence; local collection authority |
| timeline and milestones | Schedule mechanics for delivery checkpoints | future product operations, roadmap, or planning owner | moved | Project management mechanics outside PRD core | local collection boundary |
| quality checklist | Final validation checks for clarity, metrics, scope, and risks | `product-requirements/references/eval-fixtures.md` | compressed | Directly reusable as acceptance checks | source evidence; local collection authority |
| template and completed example assets | Fill-in scaffold and realistic specimen | `product-requirements/references/template.md` and example | compressed | Strong bootstrapping assets | source evidence; local collection authority |
| command wrapper | Provider-specific invocation shim | none | non-capability | Not core capability | n/a |
| frontmatter framework tags and branding metadata | Packaging metadata | none | non-capability | No direct workflow behavior | n/a |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| When-to-use guardrail | `product-requirements` | Trigger and boundary contract | compressed | Keeps routing precision |
| PRD instruction recipe | `product-requirements` | Workflow section | compressed | Preserves progression logic |
| Quality checklist | `product-requirements` | Eval fixture checklist | compressed | Converts checklist into testable gates |
| Timeline and milestones expectation | future product operations or roadmap owner | Moved owner note | moved | Not first-wave PRD-core ownership |
| Command indirection pattern | none | none | non-capability | No reusable product-management behavior |

## Closeout

- Source item count: 11
- Ledger row count: 11
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Timeline and milestone mechanics could pull project management into PRD; mitigated by moved row.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: timeline and milestone mechanics moved to future product operations, roadmap, or planning owner.
- Authority gaps: none for process guidance
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 0
- Proposed local edits: Add PRD trigger timing, drafting flow, metric rigor, requirement quality, scope partitioning, risk/dependency handling, and template/example fixtures to `product-requirements`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
