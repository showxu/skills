# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H7 Alireza Code To PRD Distillation Receipt

## Source Scope

- Source: `alirezarezvani-claude-skills-product-prd` / `code-to-prd`
- Commit: `7d493fed97e4d57553630e1a2432c1c02bf5b2b3`
- Paths: `product-team/code-to-prd/skills/code-to-prd/`, `commands/code-to-prd.md`, `docs/skills/product-team/code-to-prd.md`
- Candidate local owner: future `product-management/skills/code-to-product-feature/`
- Authority requirement: code-derived behavior is evidence, not product intent
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `docs/skill-authoring.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H7-alireza-code-to-prd`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| trigger contract | Trigger on requests to turn an existing codebase into product documentation, functional inventory, or requirements evidence | `code-to-product-feature/SKILL.md` description | compressed | Local skill must own observed product evidence, not a canonical PRD claim | source evidence; local collection authority |
| dual audience framing | Output should be readable by product stakeholders while retaining enough exact behavior for engineering follow-up | `code-to-product-feature/SKILL.md` output contract | compressed | Preserves audience balance while avoiding implementation planning ownership | source evidence; local collection authority |
| phase 1 global scan | Identify framework, route/page inventory, shared state, auth, API config, models, middleware, and enums before page analysis | `code-to-product-feature/SKILL.md` workflow | compressed | Core evidence-gathering sequence for local skill | source evidence; target repo evidence required |
| route and endpoint inventory | Treat frontend pages and backend endpoints as product-facing surfaces with path, owner file, module, method, and auth fields | `code-to-product-feature/references/template.md` | compressed | Local output needs product surface inventory for both UI and API projects | source evidence; target repo evidence required |
| global context mapping | Capture shared components, permissions, feature flags, config, entity relationships, DTOs, and middleware as product behavior evidence | `code-to-product-feature/references/template.md` | compressed | Preserves hidden system context that affects user-facing behavior | source evidence; target repo evidence required |
| page-by-page analysis | For every page or endpoint group, document overview, layout, fields, interactions, APIs, relationships, and business rules | `code-to-product-feature/SKILL.md` workflow and template | compressed | Main local artifact structure | source evidence; target repo evidence required |
| field extraction priority | Prefer visible labels and translations before variable names; mark inferred names | `code-to-product-feature/SKILL.md` guardrails | compressed | Prevents implementation naming from becoming product truth | source evidence; target repo evidence required |
| action-response interaction format | Describe behavior as user action, system response, validation, success, and failure paths | `code-to-product-feature/references/template.md` | compressed | Produces PM-readable behavior without code narration | source evidence; local collection authority |
| API dependency handling | Distinguish real integrations from mock, fixture, hardcoded, and simulated data; document required API when absent | `code-to-product-feature/SKILL.md` guardrails | compressed | Critical evidence boundary for code-derived product docs | source evidence; target repo evidence required |
| enum and model extraction | Exhaustively list constants, statuses, roles, field constraints, and entity relationships when present | `code-to-product-feature/references/template.md` | compressed | Preserves hidden business rules from code | source evidence; target repo evidence required |
| uncertainty marking | Use explicit uncertainty markers instead of fabricating business meaning | `code-to-product-feature/SKILL.md` quality checklist | compressed | Aligns with local requirement to label inferred product intent | source evidence; local collection authority |
| output directory shape | Produce overview, per-page docs, enum dictionary, API inventory, and relationship map | `code-to-product-feature/references/template.md` | compressed | Local feature package can keep equivalent Evidence sections rather than copying directory shape | source evidence; local collection authority |
| framework-specific lookup guidance | Framework references identify where to find routes, APIs, forms, permissions, validation, models, middleware, and mocks | `code-to-product-feature/references/framework-patterns.md` | compressed | Useful progressive-disclosure reference for local skill | source evidence; target repo evidence required |
| PRD quality checklist | Validate completeness, accuracy, readability, backend specifics, and common omissions | `code-to-product-feature/references/eval-fixtures.md` and quality checklist | compressed | Converts source checklist into local fixtures and validation prompts | source evidence; local collection authority |
| large-project pacing | Work in batches for large projects | `code-to-product-feature/SKILL.md` runtime guidance | compressed | Preserve batching as an internal execution strategy; this ExecPlan has no routine HITL pauses | source evidence; local collection authority |
| attribution and external inspiration | Upstream attribution and author metadata | source ledger only | non-capability | Provenance belongs in receipt or source ledger, not public skill behavior | source evidence only |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Features | `code-to-product-feature` | Trigger and capability summary for code-derived product evidence | compressed | Preserves behavior without stack marketing |
| Role and Dual Audience | `code-to-product-feature` | Output contract for product-readable evidence with engineering traceability | compressed | In scope |
| Phase 1 Project Global Scan | `code-to-product-feature` | Evidence scan workflow | compressed | In scope |
| Phase 2 Page-by-Page Deep Analysis | `code-to-product-feature` | Page or endpoint artifact workflow | compressed | In scope |
| Phase 3 Generate Documentation | `code-to-product-feature` | Product feature package Evidence output structure | compressed | Directory shape adapted to local product package model |
| Key Principles | `code-to-product-feature` | Business-language, hidden-logic, enum, uncertainty, and self-contained-page guardrails | compressed | In scope |
| Page Type Strategies | `code-to-product-feature/references/framework-patterns.md` | Page and endpoint type reference | compressed | In scope |
| Execution Pacing | `code-to-product-feature/SKILL.md` | Internal batching guidance | compressed | Preserved without making routine user review mandatory for this ExecPlan |
| Common Pitfalls | `code-to-product-feature/references/eval-fixtures.md` | Fixture prompts for hidden modals, permissions, stale mocks, missing errors, and unlinked pages | compressed | Best represented as durable fixtures |
| Tooling | `code-to-product-feature/scripts/` candidate | Script handover row | compressed | Scripts may be adapted if useful |

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `scripts/codebase_analyzer.py` | Scans project structure to infer framework, routes, APIs, models, enums, and metadata | Local Python script; source claims stdlib-only | JSON or Markdown analysis summary | Must read target repo only; must label uncertain or unsupported frameworks | Analyzer can miss custom routing and dynamic behavior | possible adapted helper under `code-to-product-feature/scripts/` | `code-to-product-feature` | source evidence; validate before reuse | script path and command docs |
| `scripts/prd_scaffolder.py` | Generates PRD skeleton from analysis JSON | Local Python script; no live auth | Markdown directory skeleton | Skeleton is a draft, not product truth | Missing analysis fields can create empty or misleading stubs | possible adapted helper under `code-to-product-feature/scripts/` | `code-to-product-feature` | source evidence; validate before reuse | script path and command docs |
| `commands/code-to-prd.md` | Slash-command wrapper for analyze, scaffold, fill, finalize sequence | Host command wrapper only | command invocation prose | Do not preserve as local authority; local skill should work without slash command | Wrapper can imply unsafe cleanup or user review assumptions | no direct adapter in first wave | `code-to-product-feature` source ledger | source evidence only | command path |
| `references/prd-quality-checklist.md` | Completeness and accuracy validation checklist | Markdown reference | checklist and fixture prompts | Must be translated to observed-product evidence boundary | Checklist can overclaim if code evidence is incomplete | local reference and eval fixtures | `code-to-product-feature` | source evidence; local collection authority | reference path |
| `references/framework-patterns.md` | Framework lookup hints for routes, APIs, forms, permissions, models, and mocks | Markdown reference | framework matrix | Not exhaustive authority for all frameworks | Framework drift and custom patterns can invalidate assumptions | local reference | `code-to-product-feature` | source evidence; target repo evidence required | reference path |

## Closeout

- Source item count: 21
- Ledger row count: 16
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Script-driven scaffolding could overstate product intent; mitigated by uncertainty and observed-evidence guardrails.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: none
- Authority gaps: Script behavior and framework coverage must be validated before local reuse.
- Section / recipe / guardrail parity: Complete for in-scope code-derived product evidence.
- Non-skill handover rows: 5
- Proposed local edits: Create `code-to-product-feature` with scan, evidence, uncertainty, field/API/enum, and quality-check references.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
