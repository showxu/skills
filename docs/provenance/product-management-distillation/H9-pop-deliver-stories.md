# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H9 Product On Purpose Deliver User Stories Distillation Receipt

## Source Scope

- Source: `product-on-purpose-pm-skills` / `prd-delivery-family:stories`
- Commit: `2b0310d88b8e5918fd298ea4ab1f7969c9a0b8ef`
- Paths: `skills/deliver-user-stories/`, `commands/user-stories.md`
- Candidate local owner: future `product-management/skills/product-user-stories/`
- Authority requirement: source process guidance only; local collection owns product story boundary
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `product-management/PLAN.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H9-pop-deliver-stories`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| trigger and when-to-use | Generate stakeholder-readable stories from requirements or feature context | `product-user-stories/SKILL.md` trigger | compressed | Keep trigger and remove project-mechanics language | source evidence; local collection authority |
| requirement traceability | Story set must map back to spec intent | `product-user-stories/SKILL.md` and source ledger | compressed | Preserves traceability contract | source evidence; local collection authority |
| persona identification | Stories should be persona-scoped rather than generic | `product-user-stories/SKILL.md` workflow | compressed | Core product-story behavior | source evidence; local collection authority |
| goal-based decomposition | Split requirements into distinct user-value increments | `product-user-stories/SKILL.md` workflow | compressed | Retains value-first slicing | source evidence; local collection authority |
| story statement rule | Each story needs persona, action, and benefit | `product-user-stories/references/template.md` | compressed | Direct output-shape preservation | source evidence; local collection authority |
| INVEST checklist | Apply independent, negotiable, valuable, estimable, small, and testable checks | `product-user-stories/SKILL.md` checklist and fixtures | compressed | Keeps explicit quality checks | source evidence; local collection authority |
| Given/When/Then emphasis | Detailed acceptance authoring guidance | `product-acceptance-criteria/SKILL.md` with handoff note | moved | Acceptance depth belongs to acceptance artifact owner | local collection boundary |
| template traceability fields | Story identity, context, out-of-scope, and open questions | `product-user-stories/references/template.md` | compressed | Useful product artifact structure | source evidence; local collection authority |
| planning fields | Priority, estimates, dependency status, and backlog mechanics | `software-engineering` planning owners | moved | Sprint/backlog management is outside product-management ownership | local collection boundary |
| technical notes | Implementation and architecture hints | `software-engineering` owners | moved | Implementation guidance is outside this collection | local collection boundary |
| design notes | Design links attached to stories | `product-user-stories/references/template.md` with design authority boundary | compressed | Keep links as references, not UX authority | local collection boundary |
| example story set | Multi-story example corpus | `product-user-stories/references/example.md` and eval fixtures | compressed | Reusable calibration evidence | source evidence; local collection authority |
| command wrapper | Thin prompt routing to skill and template | `product-user-stories/agents/openai.yaml` and source ledger | compressed | Preserve invocation pattern without upstream command surface | source evidence; local collection authority |
| frontmatter metadata | Framework, license, version, and repo metadata | none | non-capability | Not execution behavior | n/a |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| When to Use | `product-user-stories` | Trigger contract for requirement-to-story decomposition | compressed | Scope retained with local boundary wording |
| Instructions | `product-user-stories` | Workflow checklist for traceability, persona, and slicing | compressed | Core recipe preserved |
| Quality Checklist | `product-user-stories` | Final checklist and eval fixtures | compressed | Explicit guardrails retained |
| `references/TEMPLATE.md` | `product-user-stories` and moved owners | Local template plus boundary split for planning and implementation fields | compressed | Keeps structure while routing out-of-scope parts |
| `references/EXAMPLE.md` | `product-user-stories` | Example artifact and fixture seeds | compressed | Practical calibration retained |
| `commands/user-stories.md` | `product-user-stories` | Manual-entry routing note | compressed | Invocation behavior retained without command coupling |
| metadata and framework lists | none | none | non-capability | Not behavior-bearing instructions |

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `commands/user-stories.md` | Routes a user prompt to story generation and template use | no setup or auth required | story artifact document | Do not treat command wrapper as product authority; skill body owns behavior | Validate output against template and INVEST checks; fail if stories include implementation planning | possible `agents/openai.yaml` mapping and source-ledger note | `product-user-stories` | source evidence; local collection authority | pinned command file |

## Closeout

- Source item count: 14
- Ledger row count: 14
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Planning and technical fields could leak into product story owner; mitigated by moved rows.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: acceptance depth moved to `product-acceptance-criteria`; planning and technical notes moved to `software-engineering`.
- Authority gaps: none for process guidance
- Section / recipe / guardrail parity: Complete
- Non-skill handover rows: 1
- Proposed local edits: Add traceability, persona, slicing, INVEST, design-reference boundary, and command/manual-entry cues to `product-user-stories`.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
