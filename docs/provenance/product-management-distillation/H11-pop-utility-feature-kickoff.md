# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# H11 Product On Purpose Utility And Feature Kickoff Distillation Receipt

## Source Scope

- Source: `product-on-purpose-pm-skills` / `pm-skill-command-and-utility-model`
- Commit: `2b0310d88b8e5918fd298ea4ab1f7969c9a0b8ef`
- Paths: `skills/utility-pm-skill-builder/`, `commands/workflow-feature-kickoff.md`
- Candidate local owners: future `product-management/skills/product-feature-creator/`; `skill-collection-creator` for collection routing and scaffold decisions
- Authority requirement: source evidence only; local collection and creator skills decide final structure
- Target collection rules consulted: `product-management/AGENTS.md`, `product-management/README.md`, `software-engineering/skills/skill-collection-creator/SKILL.md`, `software-engineering/skills/skill-creator/SKILL.md`
- Upstream/source-scope handoff: `product-management/PLAN.md` handoff `H11-pop-utility-feature-kickoff`
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
| feature kickoff command | Product work can be sequenced from problem framing to hypothesis to PRD to stories | `product-feature-creator/SKILL.md` workflow | compressed | Preserves useful product flow while adapting to local first-wave skills | source evidence; local collection authority |
| multi-artifact workflow | Later artifacts should build on earlier product decisions rather than compete as separate truth sources | `product-feature-creator/SKILL.md` integration rules | compressed | Directly supports package-level orchestration | source evidence; local collection authority |
| problem and hypothesis prelude | Feature package should capture problem, affected users, success signal, and hypothesis before detailed requirements | `product-feature-creator/references/template.md` | compressed | Local first wave lacks standalone problem/hypothesis skills, so lightweight sections belong in the package entrypoint | source evidence; local collection authority |
| skill idea entry modes | Accept problem-first or skill-first input and normalize to artifact, audience, and purpose | `skill-collection-creator` routing packet; future creator-pro packet | moved | This is collection/skill creation behavior, not product feature authoring | source evidence; local software-engineering owner |
| gap analysis against existing skills | Check overlap before creating a new skill and identify the specific gap | `skill-collection-creator` packet | moved | Collection architecture owner must decide placement and overlap | source evidence; local software-engineering owner |
| why and kill gates | Require concrete failure scenarios when overlap is high; recommend revise/workflow/docs when new skill is not justified | `skill-collection-creator` and `skill-creator` packet guardrails | moved | Useful for this ExecPlan routing, not for product-management leaf skills | source evidence; local software-engineering owner |
| split-skill signals | Split when one idea produces multiple artifact types or crosses phases | `skill-collection-creator` packet | moved | Directly informs six-skill first-wave routing | source evidence; local software-engineering owner |
| classification and repo fit | Determine domain/foundation/utility naming and directory conventions | `skill-collection-creator` packet | moved | Source taxonomy differs from local collection taxonomy; keep as routing evidence only | source evidence; local software-engineering owner |
| implementation packet shape | Decision, classification, overlap, exemplars, draft files, command, AGENTS entry, validation checklist | collection-routing packet and source ledger | compressed | Useful packet completeness model, but local repo uses creator-pro and marketplace surfaces instead of upstream command promotion | source evidence; local collection authority |
| staging and promotion mechanics | Write drafts to staging, then promote after review and run upstream CI | no local product-management skill | non-capability | Host-specific repository workflow; not used in this monorepo execution | source evidence only |
| frontmatter linter note | Descriptions must be single-line and avoid folded YAML in that source repo | local skill authoring validation awareness | compressed | Preserves known frontmatter failure mode while local validator owns exact rule | source evidence; local repo validation authority |
| command wrapper conventions | Slash command files contain minimal description and `$ARGUMENTS` prose | source ledger only | non-capability | Product-management collection is not adding command files in first wave | source evidence only |
| AGENTS entry convention | Upstream AGENTS entries use source-specific header and path format | source ledger only | non-capability | Local `product-management/AGENTS.md` has its own route model | source evidence only |
| validation checklist | Name/path sync, description quality, template/example completeness, output contract, quality checklist | `skill-collection-creator` and `skill-creator` packets | moved | Validation belongs to software-engineering skill tooling for this monorepo | source evidence; local software-engineering owner |

## Section / Recipe / Guardrail Parity

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
| Feature Kickoff workflow | `product-feature-creator` | Product feature package orchestration from problem through requirements and stories | compressed | Core product-flow evidence for local entrypoint |
| Step 1 Understand the Idea | `skill-collection-creator` | Collection-routing intake and ownership boundary check | moved | Skill creation behavior, not product artifact behavior |
| Step 2 Gap Analysis | `skill-collection-creator` | Overlap and gap analysis in routing packet | moved | Used for this first-wave routing decision |
| Why Gate and Kill Gate | `skill-collection-creator` and `skill-creator` | Exception-only blocker handling and no unjustified new skill creation | moved | Software-engineering authoring owner |
| Step 3 Scope Check | `skill-collection-creator` | Split or merge decision for six first-wave skills | moved | Directly informs collection shape |
| Step 4 Classification and Repo Fit | `skill-collection-creator` | Local taxonomy and marketplace placement | moved | Local collection conventions differ |
| Step 5 Implementation Packet | `skill-collection-creator` packet and `skill-creator` target packets | Receipt-backed routing and authoring packets | compressed | Useful packet completeness model adapted to local flow |
| Step 6 Staging Area | no local owner | Not used | non-capability | This monorepo writes canonical files after plan authorization |
| Step 7 Promote | no local owner | Not used | non-capability | This ExecPlan has no routine promotion approval gate |
| Template and Example references | `skill-creator` target packets | Require template, example, source-ledger, eval fixtures, and host metadata | compressed | Preserves completeness requirement in local artifact set |

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `skills/utility-pm-skill-builder/references/TEMPLATE.md` | Complete implementation packet structure for skill creation | Markdown reference only | packet checklist and draft sections | Do not copy source taxonomy or command conventions | Can create mismatch if upstream repo conventions are imported directly | collection-routing packet template cues | `skill-collection-creator` | source evidence; local repo rules win | template path |
| `skills/utility-pm-skill-builder/references/EXAMPLE.md` | Example packet showing overlap analysis, exemplar selection, draft skill, template, command, AGENTS entry, validation | Markdown reference only | worked example | Use as completeness signal only, not content authority | Example inventory counts are point-in-time and not local truth | creator packet fixture/reference cues | `skill-creator` and `skill-collection-creator` | source evidence; local repo rules win | example path |
| `commands/workflow-feature-kickoff.md` | Command-level workflow from problem to hypothesis to PRD to stories | Host command wrapper; no auth | ordered artifact workflow | Do not copy slash command wrapper; local skill should route by trigger | Source references upstream skill names not present locally | product-flow reference | `product-feature-creator` | source evidence; local collection authority | command path |

## Closeout

- Source item count: 17
- Ledger row count: 14
- Missing rows: 0
- Duplicate mappings: 0
- Compression risks: Skill-builder utility material could leak source repo taxonomy into local product skills; mitigated by moved rows to `skill-collection-creator`.
- Deferred rows with owner/reason: none
- Moved rows with destination/evidence: skill creation, overlap, split, classification, and validation rows moved to `skill-collection-creator` or `skill-creator`.
- Authority gaps: Upstream staging, command, and AGENTS conventions are not local authority.
- Section / recipe / guardrail parity: Complete for product-flow and collection-routing evidence.
- Non-skill handover rows: 3
- Proposed local edits: Add feature-package orchestration to `product-feature-creator`; include collection-routing packet evidence for first-wave skill scaffold decisions.
- Validation: `validate_distillation_report.py` status ok on 2026-05-10
- Upstream coverage receipt or cursor decision needed: yes, after authoring and conservation review
- Upstream cursor mutations performed by distiller: none
