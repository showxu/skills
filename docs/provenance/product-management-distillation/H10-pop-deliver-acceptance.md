# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H10 Product On Purpose Deliver Acceptance Criteria Distillation Receipt

## Source Scope

- Source: `product-on-purpose-pm-skills` / `prd-delivery-family:acceptance`
- Commit: `2b0310d88b8e5918fd298ea4ab1f7969c9a0b8ef`
- Paths: `skills/deliver-acceptance-criteria/`, `commands/acceptance-criteria.md`
- Candidate local owner: future `product-management/skills/product-acceptance-criteria/`
- Authority requirement: source process guidance only; local collection owns product criteria boundary
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H10-pop-deliver-acceptance`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| trigger and usage boundary | Produce structured Given/When/Then criteria for a story or feature slice | `product-acceptance-criteria/SKILL.md` trigger and source ledger | compressed | Direct match to target skill intent | source evidence; local collection authority |
| scope confirmation rule | Require the exact story or feature slice and clarify missing scope | `product-acceptance-criteria/SKILL.md` workflow | compressed | Preserves ambiguity handling | source evidence; local collection authority |
| observable criterion rule | Each criterion must be independently testable and avoid implementation detail leakage | `product-acceptance-criteria/SKILL.md` guardrails | compressed | Core product-owned acceptance behavior | source evidence; local collection authority |
| flow coverage rule | Cover happy path first, then edge cases, error states, and recovery behavior | `product-acceptance-criteria/references/template.md` | compressed | Maintains coverage structure and sequencing | source evidence; local collection authority |
| non-functional expectations | Include performance, accessibility, security, reliability, and auditability when relevant | `product-acceptance-criteria/SKILL.md` and template | compressed | Product testability can include non-functional expectations without owning implementation | source evidence; local collection authority |
| single-outcome rule | Avoid duplicate or overlapping criteria and keep one outcome per criterion | `product-acceptance-criteria/SKILL.md` quality checklist | compressed | Preserves clarity and reviewability | source evidence; local collection authority |
| testability rewrite rule | Convert subjective language into measurable pass/fail outcomes | `product-acceptance-criteria/SKILL.md` quality checklist and fixtures | compressed | Keeps objective acceptance checks | source evidence; local collection authority |
| output contract | Restate context, group criteria, and call out assumptions or open questions | `product-acceptance-criteria/references/template.md` | compressed | Directly reusable artifact contract | source evidence; local collection authority |
| template and example assets | Acceptance-criteria scaffold and worked example | `product-acceptance-criteria/references/template.md`, example, eval fixtures | compressed | Preserve structure and fixture value without copying wording | source evidence; local collection authority |
| command wrapper and metadata | Invocation wrapper, version, license, and framework metadata | none | non-capability | No additional behavioral logic beyond skill body | n/a |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| When to Use | `product-acceptance-criteria` | Trigger boundary | compressed | Equivalent boundary in local trigger contract |
| Scope confirmation instruction | `product-acceptance-criteria` | Clarification rule in workflow | preserved | Same decision behavior |
| Happy, edge, error, and observability instructions | `product-acceptance-criteria` | Core drafting recipe | compressed | Same behavior in local wording |
| Non-functional, dedup, and testability instructions | `product-acceptance-criteria` | Quality checklist rules | preserved | Rules retained conceptually |
| Output Contract | `product-acceptance-criteria` | Local output contract and template structure | preserved | Directly reusable |
| Quality Checklist | `product-acceptance-criteria` | Pre-finalization checklist | preserved | Same validation gate |
| `references/TEMPLATE.md` | `product-acceptance-criteria` | Local template file | preserved | Artifact shape retained |
| `references/EXAMPLE.md` | `product-acceptance-criteria` | Example and fixture seed | compressed | Preserve behavior pattern, not source prose |
| `commands/acceptance-criteria.md` wrapper | none | none | dropped-duplicate | Duplicates trigger and format directions already captured |
| Frontmatter metadata | none | none | non-capability | Packaging metadata, not execution logic |

## Closeout

- Source item count: 10
- Ledger row count: 10
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Non-functional criteria could become implementation design; mitigated by product-constraint wording.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: none
- Authority gaps: none for process guidance
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 0
- Proposed local edits: Add Given/When/Then output, grouping, non-functional checks, deduplication, and open-question handling to `product-acceptance-criteria`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
