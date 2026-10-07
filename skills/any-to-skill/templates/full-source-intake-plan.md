# <source id or input name> Full-Source / Mixed-Input Intake Plan

## Scope

- Source:
- Input artifacts:
- Source type:
- Branch / reviewed commit:
- Tracking state:
- Local plan owner:
- Owning git repo root:
- Target local path:
- Distillation artifact root: `<target repo>/.agent/skill-distillation/`
- Non-goals:
- Approval boundaries:

## Source Inventory

| Source item | Kind | Tracked by watch paths / segment | Initial scope decision | Original URL | Notes |
| --- | --- | --- | --- | --- | --- |
|  |  | yes / no | in-scope / out-of-scope / moved / deferred / blocked |  |  |

## Routing Hypothesis

| Candidate area | Existing local owner or skill | Collection rules checked | Decision |
| --- | --- | --- | --- |
|  |  |  |  |

## Distillation Handoff Queue

This plan is owned by `any-to-skill`, so it records only handoff packets. Do
not place deep evidence ledgers here. For skill-source material, capability
ledger rows, section / recipe / guardrail parity, compression reasoning, and
tool/resource handover rows belong in a `skill-distiller` artifact based on the
downstream capability-ledger template:
`software-engineering/skills/skill-distiller/templates/capability-ledger.md`.
For non-skill-source artifacts, use the selected domain-specific distiller's
handoff/report shape when one exists.
Use `<target repo>/.agent/skill-distillation/` as the artifact root
for proposed receipts and review packets; do not create `<target repo>/distillation/`.
Resolve the owning git repo root, then mirror the target's real local path
relative to that repo root. Do not normalize the path into a collection or skill
namespace; where the skill lives is the path to write. For a monorepo-owned
skill such as `product-management/skills/product-requirements/`, use
`<target repo>/.agent/skill-distillation/product-management/skills/product-requirements/`.
For an independent git repo whose skill path is `skills/product-requirements/`,
use `<target repo>/.agent/skill-distillation/skills/product-requirements/`.
The orchestrator plan chooses the artifact root and expected receipt/review
paths; `skill-distiller` writes to those supplied paths and owns the evidence
content, not the path convention.

Use `skills/any-to-skill/references/orchestrator-distiller-contract.md`
for the required packet fields.

| Handoff id | Source paths / segment | Source commit | Candidate local owners | Rules consulted | Cursor fields frozen | Distiller artifact | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |

## Receipt Bundle Classification

Classify accepted distiller receipts before final authoring. Use
`single-existing-skill` for one existing target skill. Use
`multi-existing-skills` only when each existing skill can receive an independent
target-skill update packet. Use a repository architecture packet for new
skills, splits, renames, moves, collection-boundary decisions, or blocked
ownership.

| Bundle id | Bundle kind | Affected skills / owners | Receipt evidence | Final route | Open decision |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Target-Skill Update Packets

When distiller receipts converge on one existing local skill, prepare a packet
for `skill-creator`. For multiple independent existing skills, prepare one
packet per target skill. Do not write final local wording or patches in this
plan.

| Packet id | Target skill or owner | Distiller receipts | Expected surfaces | Open blockers | Final owner |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Repository Architecture Packets

When receipts require a new skill, split, rename, move, collection-boundary
change, or ownership decision, prepare a packet using
repository architecture review.

| Packet id | Bundle kind | Affected skills / collections | Needed decision | Receipt evidence | State |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Post-Authoring Conservation Review

When final authoring compresses upstream-derived receipt evidence into local
skill or collection changes, record the review gate before closeout. Run review
per target skill or artifact, then summarize the bundle.

| Review id | Target skill / artifact | Authoring result | Receipts checked | Reviewer task | Verdict | Repair owner |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  | pass / needs-repair / blocked |  |

| Receipt row | Assigned target | Expected preservation | Final local equivalent | Verdict | Repair note |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  | preserved / compressed-ok / missing / distorted / blocked / deferred |  |

## Handoff Slices

| Slice | Scope | Entry criteria | Owned source or handoff rows | Allowed work | Exit criteria | Validation |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

## Authority And Verification

| Topic | Required authority | Status | Followup |
| --- | --- | --- | --- |
|  |  |  |  |

## Closeout Audit

- Source item count:
- Handoff packet count:
- Distiller receipt count:
- Handoffs missing distiller receipt:
- Receipt bundle classification:
- Target-skill update packet count:
- Collection-routing packet count:
- Post-authoring conservation review:
- Source-wide inventory completed: yes / no
- Source-level closeout eligible: yes / no
- Segment-level closeout only: yes / no
- Untracked in-scope paths remaining:
- Authority gaps:
- Public wording review:
- Validation commands:
- Tracking-state update:
