# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# R-code-to-product-feature Conservation Review

## Review Scope

- Target: `product-management/skills/code-to-product-feature/`
- Receipts checked: `H7`
- Review date: 2026-05-10
- Overall verdict: pass after hardening repair
- Repair needed: completed for batch HITL, local scripts, and product-signal
  wording

## Row Verdicts

| Receipt row | Authoring destination | Verdict | Notes |
| --- | --- | --- | --- |
| trigger contract | `SKILL.md` description and when-to-use | compressed-ok | Code-to-doc requests route to observed product evidence, not canonical intent. |
| dual audience framing | output contract and template evidence paths | compressed-ok | PM-readable behavior keeps code traceability. |
| phase 1 global scan | workflow and template scan summary | compressed-ok | Framework, routes, auth, models, and integrations retained. |
| route and endpoint inventory | product surface inventory table | compressed-ok | UI and API surfaces are captured as product-facing surfaces. |
| global context mapping | template shared-state, permissions, config, and integration rows | compressed-ok | Hidden system context preserved as evidence. |
| page-by-page analysis | observed behavior details | compressed-ok | Action, response, validation, success, failure, and recovery paths retained. |
| field extraction priority | decision rules | compressed-ok | Visible labels outrank variable names; inferred naming is labeled. |
| action-response interaction format | observed behavior template | compressed-ok | Behavior is described in product language. |
| API dependency handling | integration notes and decision rules | compressed-ok | Live, mock, fixture, hardcoded, and unknown status retained. |
| enum and model extraction | constants, enum, and rule signals table | compressed-ok | Statuses, roles, field constraints, and relationships retained. |
| uncertainty marking | decision rules and unknowns table | preserved | Observed, inferred, and unknown labels are mandatory. |
| output directory shape | local product package output contract | compressed-ok | Source directory shape adapted to local `Docs/Product` convention. |
| framework-specific lookup guidance | `references/framework-patterns.md` | compressed-ok | Lookup hints retained as non-exhaustive guidance. |
| PRD quality checklist | validation rules and eval fixtures | compressed-ok | Checklist became observed-evidence quality checks. |
| large-project pacing | `SKILL.md` HITL gates and runtime topology | repaired | Source batch review guardrail is preserved: >15 surfaces use 3-5 surface batches with user review unless uninterrupted execution was explicitly requested. |
| attribution and external inspiration | source ledger only | compressed-ok | Provenance retained outside public workflow prose. |

## Non-Skill Handover Check

| Source item | Destination | Verdict | Notes |
| --- | --- | --- | --- |
| `scripts/codebase_analyzer.py` | `scripts/analyze_code_evidence.py` | repaired | Read-only analyzer capability is locally adapted to observed-evidence output. |
| `scripts/prd_scaffolder.py` | `scripts/scaffold_observed_evidence.py` | repaired | PRD scaffolding is converted to observed-from-code evidence scaffolding and must not generate canonical PRD claims. |
| `commands/code-to-prd.md` | source ledger only | compressed-ok | Slash-command wrapper not preserved as local authority. |
| `references/prd-quality-checklist.md` | validation rules and eval fixtures | compressed-ok | Checklist translated to observed-product boundary. |
| `references/framework-patterns.md` | local `references/framework-patterns.md` | preserved | Framework lookup hints retained. |

## Boundary Check

The final skill consistently treats source code as evidence. It does not claim
product intent, create implementation plans, or own technical design.

## Hardening Addendum

Post-review hardening found that `Product implication` wording and the example
phrase `Product should...` could convert rule signals into product intent. The
template now uses `Observed product signal`, and the example states validators
as implementation evidence requiring product confirmation.
