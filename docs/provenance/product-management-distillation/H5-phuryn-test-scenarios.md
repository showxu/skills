# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H5 Phuryn Test Scenarios Distillation Receipt

## Source Scope

- Source: `phuryn-pm-skills` / `prd-to-execution-family:test-scenarios`
- Commit: `020ee82501d9c09f9b989517c4cf9641bad057ff`
- Paths: `pm-execution/skills/test-scenarios/`
- Candidate local owner: future `product-management/skills/product-acceptance-criteria/`; future standalone test-scenarios owner deferred
- Authority requirement: source process guidance only; product-management owns criteria, not QA execution
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H5-phuryn-test-scenarios`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| trigger and use cases | Convert story context into explicit, testable behavior checks | `product-acceptance-criteria/SKILL.md` trigger and source ledger | compressed | Keeps product testability intent while normalizing away QA-team phrasing | source evidence; local collection authority |
| input contract | Require story slice, product context, assumptions, and constraints before drafting checks | `product-acceptance-criteria/references/template.md` and eval fixtures | compressed | Preserves required context without upstream argument syntax | source evidence; local collection authority |
| workflow recipe | Review story, define objective, set preconditions, identify roles, actions, outcomes, and edge cases | `product-acceptance-criteria/SKILL.md` workflow | compressed | Preserves decision sequence and maps it into acceptance-criteria authoring | source evidence; local collection authority |
| scenario structure | Objective, starting conditions, actor, actions, and expected outcomes | `product-acceptance-criteria/references/template.md` | compressed | Maps cleanly to Given/When/Then and pass/fail observability | source evidence; local collection authority |
| worked example | Concrete behavior checks with exclusions and latency expectations | `product-acceptance-criteria/references/eval-fixtures.md` | compressed | Useful as fixture archetype, not copied scenario text | source evidence; local collection authority |
| deliverable quality expectations | Cover criteria, observable outcomes, edge/error behavior, and clear result checks | `product-acceptance-criteria/SKILL.md` quality checklist | compressed | Product-owned testability guidance is in scope | source evidence; local collection authority |
| QA execution-ready framing | Preparing executable test scenarios and QA run mechanics | future standalone test-scenarios or QA owner | deferred | Product-management keeps pass/fail criteria; QA execution mechanics are outside first wave | ownership boundary |
| upstream metadata and branding | Naming, packaging, and repo prose | none | non-capability | Does not add reusable behavior | n/a |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Description and use cases | `product-acceptance-criteria` | Acceptance/testability trigger contract | compressed | Keeps trigger value and drops QA ownership wording |
| Arguments block | `product-acceptance-criteria` | Context prerequisites in template header | compressed | Same intent in local format |
| Step-by-step process | `product-acceptance-criteria` | Drafting workflow and checklist | compressed | Preserves ordering and validation intent |
| Scenario template | `product-acceptance-criteria` | Given/When/Then plus context and expected outcomes | compressed | Equivalent observable structure |
| Example scenario | `product-acceptance-criteria` | Eval fixture example | compressed | Preserves pattern without source wording |
| QA execution-ready output claim | future test-scenarios owner | Deferred ownership note | deferred | Execution procedures are outside first-wave product-management boundary |
| Repo and frontmatter metadata | none | none | non-capability | Not behavioral guidance |

## Closeout

- Source item count: 8
- Ledger row count: 8
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Acceptance criteria could drift into QA execution; mitigated by deferred QA execution row.
- Deferred rows with owner/reason: QA execution-ready scenario mechanics deferred to future standalone test-scenarios or QA owner.
- Moved rows with destination/evidence: none
- Authority gaps: none for process guidance
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 0
- Proposed local edits: Add testability, scenario context, expected outcomes, and edge/error coverage to `product-acceptance-criteria`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
