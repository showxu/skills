# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H4 Phuryn User And Job Stories Distillation Receipt

## Source Scope

- Source: `phuryn-pm-skills` / `prd-to-execution-family:stories`
- Commit: `020ee82501d9c09f9b989517c4cf9641bad057ff`
- Paths: `pm-execution/skills/user-stories/`, `pm-execution/skills/job-stories/`
- Candidate local owner: future `product-management/skills/product-user-stories/`
- Authority requirement: source process guidance only; local collection owns story boundary
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H4-phuryn-stories`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| persona-story trigger | Break a feature or spec into persona-based user stories | `product-user-stories/SKILL.md` trigger | compressed | Same capability narrowed to product-scope routing | source evidence; local collection authority |
| job-story trigger | Break context into situation, motivation, and outcome stories | `product-user-stories/SKILL.md` mode selection | compressed | Preserves alternate JTBD mode in one local owner | source evidence; local collection authority |
| input arguments | Require feature context, assumptions, constraints, and design references | `product-user-stories/references/template.md` input preflight | compressed | Keeps reusable intake fields without upstream variable syntax | source evidence; local collection authority |
| persona process rules | Apply 3C, INVEST, readable phrasing, role/journey decomposition, and value-first slicing | `product-user-stories/SKILL.md` workflow and eval fixtures | compressed | Core quality mechanics retained | source evidence; local collection authority |
| JTBD process rules | Use situation, motivation, and expected outcome to avoid shallow role stories | `product-user-stories/SKILL.md` workflow branch and fixtures | compressed | Retains JTBD-specific reasoning path | source evidence; local collection authority |
| story statement templates | Support persona and JTBD statement forms | `product-user-stories/references/template.md` | compressed | Keeps output-shape flexibility | source evidence; local collection authority |
| acceptance-depth guidance | Detailed acceptance criteria counts, edge cases, performance, and integration checks | `product-acceptance-criteria/SKILL.md` with handoff note | moved | Acceptance detail belongs to acceptance owner, not story owner | local collection boundary |
| design-link expectations | Story outputs may reference design artifacts | `product-user-stories/SKILL.md` guardrail and template references | compressed | Keep references as evidence only, not design authority | local collection boundary |
| example artifacts | Persona and JTBD examples calibrate output shape | `product-user-stories/references/example.md` and eval fixtures | compressed | Useful for local examples and fixture seeds | source evidence; local collection authority |
| deliverable constraints | Stories should be independent, small, valuable, and traceable | `product-user-stories/SKILL.md` quality checklist | compressed | Preserves slicing quality without sprint-mechanics ownership | source evidence; local collection authority |
| external reading links | Off-repo educational links | none | non-capability | Not required for local capability execution | n/a |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Use cases for both modes | `product-user-stories` | Trigger contract with persona and JTBD entry cues | compressed | One local skill supports both modes |
| Arguments | `product-user-stories` | Input checklist in template/reference | compressed | Keep intent, remove source-specific argument surface |
| Persona workflow | `product-user-stories` | Workflow rules plus 3C and INVEST checks | compressed | Behavior preserved with shorter local wording |
| JTBD workflow | `product-user-stories` | JTBD-specific workflow branch | compressed | Keeps situation/outcome framing |
| Story templates | `product-user-stories` | Unified template with two statement variants | compressed | Avoid duplicate templates while preserving both forms |
| Acceptance-depth instructions | `product-acceptance-criteria` | Acceptance skill ownership and handoff note | moved | Boundary split per collection scope |
| Further reading links | none | none | non-capability | Reference-only material |

## Closeout

- Source item count: 11
- Ledger row count: 11
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Acceptance guidance could duplicate acceptance skill; mitigated by moved row.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: acceptance-depth guidance moved to `product-acceptance-criteria`.
- Authority gaps: none for process guidance
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 0
- Proposed local edits: Add persona and JTBD modes, input preflight, 3C/INVEST checks, design-reference boundary, and example fixtures to `product-user-stories`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
