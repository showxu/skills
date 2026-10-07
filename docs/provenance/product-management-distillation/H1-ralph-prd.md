# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H1 Ralph PRD Distillation Receipt

## Source Scope

- Source: `snarktank-ralph-prd` / `prd-generator-skill`
- Commit: `6c53cb0b831ebe8739c6a003e22af14902d8b0b5`
- Paths: `skills/prd/SKILL.md`
- Candidate local owner: future `product-management/skills/product-requirements/`
- Authority requirement: source process guidance only; local collection owns product requirements boundary
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H1-ralph-prd`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| trigger cues | PRD and product spec requests should route to a requirements owner | `product-requirements/SKILL.md` trigger | compressed | Needed for first-wave routing, but local target does not exist yet | source evidence; local collection authority |
| clarification gate | Ask only high-impact clarifications and support fast-choice responses | `product-requirements/SKILL.md` and eval fixtures | compressed | Preserves decision quality while minimizing routine questioning | source evidence; local collection authority |
| PRD backbone | Structure requirements around problem, goals, requirements, scope, metrics, and open issues | `product-requirements/references/template.md` | compressed | Core artifact shape for first wave | source evidence; local collection authority |
| story and criteria quality bar | Stories should be small and acceptance checks concrete | `product-requirements/SKILL.md` plus handoff to stories and acceptance skills | compressed | Keeps useful quality rule without duplicating downstream owners | source evidence; local collection authority |
| non-implementation boundary | Produce requirements only and do not execute build work | `product-requirements/SKILL.md` boundary | compressed | Matches product-management ownership boundary | source evidence; local collection authority |
| UI and typecheck verification clause | Browser verification and code health checks after implementation | `software-engineering` owner | moved | QA and implementation mechanics are outside product-management scope | local collection boundary |
| output placement rule | Persist durable artifact with stable naming and path convention | `product-requirements/references/template.md` and output contract | compressed | Keeps durable output guidance while adapting local product package paths | source evidence; local collection authority |
| example and completion checklist | Worked sample and pre-delivery checks calibrate quality | `product-requirements/references/example.md` and eval fixtures | compressed | Useful for consistency and review | source evidence; local collection authority |
| frontmatter naming and style metadata | Upstream label and packaging details | none | non-capability | Not behavior-bearing for local skill | n/a |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Job flow from intake to clarification to draft | `product-requirements` | Requirements workflow block | compressed | Preserved in local style |
| Lettered clarification format | `product-requirements` | Clarification pattern and fixture | compressed | Preserves rapid-response mechanic |
| PRD section recipe | `product-requirements` | Requirements template | compressed | Direct structural carryover |
| No-implementation guardrail | `product-requirements` | Boundary rules in skill body | preserved | Exact local boundary need |
| UI verification guardrail | `software-engineering` | QA and verification owner handoff | moved | Outside product-management ownership |

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| UI verification clause | Browser-level UI confirmation and code health checks | Requires engineering toolchain and browser workflow | verification evidence tied to implementation tasks | Product-management skill must not claim implementation complete | Failure means unmet implementation check, not PRD defect | `software-engineering` acceptance or QA flow | `software-engineering` | out of scope for product-management | PRD story and criteria completion clause |

## Closeout

- Source item count: 9
- Ledger row count: 9
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: PRD skill could duplicate story or acceptance owners; mitigated by handoff wording.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: UI and code verification moved to `software-engineering`.
- Authority gaps: none for process guidance
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 1
- Proposed local edits: Add trigger, clarification, PRD structure, no-implementation boundary, output placement, and quality fixtures to `product-requirements`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
