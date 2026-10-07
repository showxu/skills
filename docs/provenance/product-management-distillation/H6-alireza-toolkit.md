# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H6 Alireza Product Manager Toolkit Distillation Receipt

## Source Scope

- Source: `alirezarezvani-claude-skills-product-prd` / `product-manager-toolkit`
- Commit: `7d493fed97e4d57553630e1a2432c1c02bf5b2b3`
- Paths: `product-team/skills/product-manager-toolkit/`, `docs/skills/product-team/product-manager-toolkit.md`
- Candidate local owner: future `product-management/skills/product-requirements/`; deferred rows to future product discovery, prioritization, metrics, and go-to-market owners
- Authority requirement: source evidence only; product-management local rules decide final owner and wording
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `docs/skill-authoring.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H6-alireza-toolkit`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| toolkit trigger and scope | Broad product management trigger spans PRDs, discovery, prioritization, strategy, and GTM | `product-requirements` trigger plus future skill backlog | compressed | First wave only needs PRD-relevant trigger cues; broad toolkit scope is split by local taxonomy | source evidence; local collection authority |
| PRD template selection | Select template by feature size, stage, and cross-team complexity before drafting | `product-requirements/references/template.md` | compressed | Preserves template-choice behavior without importing all upstream template variants | source evidence; local collection authority |
| PRD development flow | Scope, draft, review, refine, approve, then track outcomes | `product-requirements/SKILL.md` workflow | compressed | Keeps source-of-truth lifecycle while avoiding project-management ownership | source evidence; local collection authority |
| problem-first PRD guidance | Lead with problem, define success metrics, state out-of-scope items, and keep technical detail secondary | `product-requirements/SKILL.md` quality checklist | compressed | Directly strengthens first-wave PRD quality rules | source evidence; local collection authority |
| review cycle roles | Engineering, design, sales, support, and stakeholders review different risks | `product-requirements/references/source-ledger.md` and handoff notes | compressed | Preserves review lens as product handoff readiness, not mandatory external workflow | source evidence; local collection authority |
| post-launch tracking | Compare actual metrics, gather feedback, record learnings, update estimates | future `product-metrics` or product operations skill | deferred | Valuable but outside first-wave PRD artifact authoring | source evidence; future owner required |
| RICE prioritization workflow | Gather candidate features, score reach/impact/confidence/effort, analyze portfolio, build roadmap | future `product-prioritization` | deferred | Distinct prioritization artifact and possible script owner, not first-wave PRD documentation | source evidence; future owner required |
| roadmap capacity planning | Balance quick wins, big bets, dependencies, and capacity | future `product-prioritization` or roadmap skill | deferred | Useful planning capability but not needed for first-wave PRD skill set | source evidence; future owner required |
| customer discovery workflow | Plan research, recruit, interview, analyze, synthesize, validate solutions | future `product-discovery` | deferred | Separate discovery artifact family; first wave may reference evidence but should not own research operations | source evidence; future owner required |
| interview best practices | Ask about past behavior, avoid leading questions, record with permission, synthesize patterns | future `product-discovery` | deferred | Discovery-specific capability should not be folded into PRD authoring | source evidence; future owner required |
| metrics frameworks | North-star, HEART, funnel, and feature-success metric frameworks | future `product-metrics`; `product-requirements` success metric section | compressed | Product requirements need success metric prompts; full measurement framework waits for future metric owner | source evidence; local collection authority |
| GTM checklist | Launch, sales enablement, marketing assets, support docs, rollout stages | `go-to-market` plus future product launch-readiness owner | moved | Market execution is outside product-management collection, while product launch readiness can be revisited later | source evidence; local route authority |
| integration platform list | Names analytics, roadmapping, design, development, research, and communication tools | `product-requirements/references/source-ledger.md` as evidence categories only | non-capability | Tool names are not stable local authority and do not define workflow behavior | source evidence only |
| common pitfalls | Avoid solution-first PRDs, over-researching, feature factory behavior, stakeholder surprise, vanity metrics | `product-requirements/SKILL.md` quality checklist; future discovery/metrics owners | compressed | Converts pitfalls into durable PRD and product-decision checks | source evidence; local collection authority |
| best-practice summaries | Problem-first writing, success metrics, explicit scope, visuals as evidence, concise technical appendix | `product-requirements/SKILL.md` and `references/template.md` | compressed | Preserves effective guidance in local vocabulary | source evidence; local collection authority |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Quick Start | `product-requirements` and future owners | Route to PRD drafting, prioritization, or discovery based on requested artifact | compressed | Local collection uses multiple small skills instead of one toolkit |
| Feature Prioritization Process | future `product-prioritization` | Future prioritization workflow and script handover | deferred | Outside first-wave scope |
| Customer Discovery Process | future `product-discovery` | Future discovery/interview synthesis workflow and script handover | deferred | Outside first-wave scope |
| PRD Development Process | `product-requirements` | Product requirements workflow from scope to outcome tracking | compressed | Core PRD lifecycle is in scope |
| PRD Templates | `product-requirements/references/template.md` | Template modes for full spec, feature brief, and lightweight PRD | compressed | Preserves template choice without copying source text |
| Common Pitfalls | `product-requirements` and future product skills | Quality checklist and source-ledger notes | compressed | Pitfalls become guardrails for local authoring |
| Best Practices | `product-requirements` | Problem, metrics, scope, evidence, and appendix guidance | compressed | Directly maps to local PRD quality rules |
| Integration Points | collection docs or source ledger | Evidence categories only, not a compatibility claim | non-capability | Platform list is not stable workflow behavior |

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `scripts/rice_prioritizer.py` | Calculates RICE scores and portfolio groupings from CSV | Local Python script; no live auth in source | text, JSON, or CSV priority output | Do not run as first-wave PRD authoring; prioritization owner must validate inputs | Bad estimates produce misleading rankings; capacity assumptions can be gamed | possible future `product-prioritization/scripts/` helper | future `product-prioritization` | source evidence only | script path and RICE reference rows |
| `scripts/customer_interview_analyzer.py` | Extracts pain points, feature requests, JTBD, sentiment, themes, and quotes | Local Python script; no live auth in source | interview insight summary | Do not treat automated extraction as product truth without review | NLP extraction can miss nuance and overstate sentiment | possible future `product-discovery/scripts/` helper | future `product-discovery` | source evidence only | script path and example output |
| `assets/prd_template.md` and `references/prd_templates.md` | Provide PRD section shapes and mode variants | Markdown assets only | template sections | Do not copy wholesale; local template must match product-management boundaries | Risk of importing technical-design and GTM sections into PRD | `product-requirements/references/template.md` | `product-requirements` | source evidence; local collection authority | template/reference paths |

## Closeout

- Source item count: 17
- Ledger row count: 15
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Broad toolkit rows could over-expand `product-requirements`; mitigated by deferred and moved rows.
- Deferred rows with owner/reason: product discovery, prioritization, metrics, and product operations rows deferred to future skills.
- Moved rows with destination/evidence: GTM execution moved to `go-to-market`; evidence is source GTM checklist and collection route rules.
- Authority gaps: Tool/platform integration names and automated script behavior remain source evidence only.
- Section / recipe / guardrail parity: Complete for in-scope PRD and routing-relevant sections.
- Non-skill handover rows: 3
- Proposed local edits: Use PRD lifecycle, template mode, success metrics, scope, and pitfall guardrails in `product-requirements`; record deferred owners in source ledger.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
