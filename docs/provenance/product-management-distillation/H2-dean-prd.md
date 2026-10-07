# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H2 Dean Peters PRD Development Distillation Receipt

## Source Scope

- Source: `deanpeters-product-manager-skills-prd` / `prd-development-workflow`
- Commit: `d68d280f215959fac21bb7599c3fa356a11a488e`
- Paths: `skills/prd-development/`
- Candidate local owner: future `product-management/skills/product-requirements/`
- Authority requirement: source process guidance only; local collection owns PRD artifact boundary
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H2-dean-prd`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| use and do-not-use boundaries | Major-initiative PRD fit and overkill cases | `product-requirements/SKILL.md` trigger and boundaries | compressed | Strong trigger hygiene for local skill | source evidence; local collection authority |
| PRD question model | Problem, users, why now, solution, metrics, requirements, non-goals, and open questions | `product-requirements/SKILL.md` and template | compressed | Core requirements reasoning | source evidence; local collection authority |
| ten-section template | Stable PRD schema for source-of-truth artifact | `product-requirements/references/template.md` | compressed | Primary structural value | source evidence; local collection authority |
| evidence-first framing | Require customer or data evidence instead of opinion-only specs | `product-requirements/SKILL.md` and eval fixtures | compressed | High-signal quality bar | source evidence; local collection authority |
| metrics model | Primary, secondary, and guardrail metrics with baseline-to-target framing | `product-requirements/references/template.md` and fixtures | compressed | Needed for measurable PRDs | source evidence; local collection authority |
| scope, risks, dependencies, and questions | Make uncertainty and delivery constraints explicit | `product-requirements/references/template.md` | compressed | Prevents ambiguity and scope drift | source evidence; local collection authority |
| anti-patterns and pitfalls | Avoid isolated writing, missing metrics, weak scope, and unsupported decisions | `product-requirements/references/eval-fixtures.md` | compressed | Valuable review checks | source evidence; local collection authority |
| multi-phase orchestration references | PRD depends on discovery, personas, sizing, story split, and related artifacts | `product-feature-creator` plus future PM skills | deferred | Keep value, but not all downstream owners exist in first wave | pending future owner |
| facilitation protocol delegation | Conversation-turn protocol delegated to another skill | future orchestration owner | moved | Interaction protocol is not core PRD artifact behavior | local scope boundary |
| day-by-day sequencing and approval cadence | Calendarized execution mechanics | future roadmap/product-ops or project planning owner | moved | Project/program mechanics out of target PRD boundary | local scope boundary |
| external reading list and placeholders | Bibliography and contextual links | source ledger only | non-capability | Not direct executable behavior and unverified as local authority | unverified source evidence |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Key concepts and PRD definition | `product-requirements` | Workflow intro and template rationale | compressed | Preserve logic without upstream phrasing |
| Eight-phase PRD recipe | `product-requirements` | Condensed creation sequence | compressed | Keep flow and remove timeline mechanics |
| Anti-pattern guardrails | `product-requirements` | Review checklist and eval fixtures | compressed | Converts warnings into checks |
| Facilitation source-of-truth linkage | future orchestration owner | Router-level interaction protocol note | moved | Not core PRD artifact behavior |
| Cross-skill dependency matrix | future PM skill family | Source-ledger deferred map | deferred | Owner paths not all created yet |

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| referenced component PM skills | Problem framing, personas, sizing, and story decomposition feed PRD sections | Requires those skills or equivalent source material to exist and be routed | inputs feeding PRD sections | Do not fabricate missing upstream skill outputs | Missing dependency should be deferred or routed, not hallucinated | future PM skill set | `product-feature-creator` and future PM owners | pending future owner | related-skill list in source scope |
| facilitation protocol skill | Guided one-question conversation behavior | Requires facilitation runtime capability | turn-by-turn session protocol | Must not be silently mixed into PRD content rules | Failure is protocol drift, not PRD schema failure | orchestration layer | future router owner | pending future owner | facilitation section in source |

## Closeout

- Source item count: 11
- Ledger row count: 11
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Broad orchestration dependencies could over-expand `product-requirements`; mitigated by deferred and moved rows.
- Deferred rows with owner/reason: multi-phase dependency matrix deferred to future PM skill family.
- Moved rows with destination/evidence: facilitation protocol and calendarized sequencing moved to future orchestration/product-ops or planning owners.
- Authority gaps: external references are non-authoritative unless locally verified.
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 2
- Proposed local edits: Add PRD boundary, evidence-first problem framing, metrics, scope/risk/dependency/open-question sections, and anti-pattern fixtures to `product-requirements`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
