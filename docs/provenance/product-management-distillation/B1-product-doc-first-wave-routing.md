# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# B1 Product Documentation First-Wave Collection Routing Packet

## Receipt Bundle Classification

- Bundle id: `B1-product-doc-first-wave`
- Bundle kind: `new-skill-needed` with collection-surface updates
- Affected collection: `product-management`
- Evidence receipts: `H1` through `H11` in `product-management/distillation/`
- Routing owner: `skill-collection-creator` for collection shape and shared surfaces
- Authoring owner after routing: `skill-creator`, one target packet per skill
- Cursor fields frozen: `last_seen`, `tracking.last_checked_commit`, and `review_coverage.reviewed_commit` remain unchanged until authoring, conservation review, validation, and closeout.

The `product-management` collection currently has no published skills. The
accepted receipts do not fit a single existing skill; they define a coherent
first-wave product documentation family with six leaf skills and collection
README/marketplace updates.

## Routing Decision

| Target | Route | Receipt evidence | Decision |
| --- | --- | --- | --- |
| `product-feature-creator` | new leaf/orchestrator skill | `H11`; local-first plan rows | Create. Owns feature-package orchestration, product artifact routing, subagent fanout decisions, and final package integration. |
| `product-requirements` | new leaf skill | `H1`, `H2`, `H3`, `H6`, `H8` | Create. Owns PRD/product requirements source-of-truth artifacts. |
| `code-to-product-feature` | new leaf skill | `H7` | Create. Owns observed product evidence from existing codebases, with implementation-vs-intent labeling. |
| `product-interaction` | new local-first leaf skill | PLAN local-first row | Create. Owns product behavior and interaction requirements; routes UX craft and implementation away. |
| `product-user-stories` | new leaf skill | `H4`, `H9` | Create. Owns persona and JTBD story breakdown, with acceptance-depth handoff. |
| `product-acceptance-criteria` | new leaf skill | `H5`, `H10` | Create. Owns product-owned pass/fail acceptance criteria, not QA automation execution. |
| future `product-discovery` | future skill | deferred rows in `H6` | Defer. Discovery/interview analysis is useful but out of first wave. |
| future `product-prioritization` | future skill | deferred rows in `H6` | Defer. RICE, roadmap capacity, and portfolio analysis are separate artifact owners. |
| future `product-metrics` | future skill | deferred rows in `H6` | Defer. Full measurement framework is separate from PRD success-metric prompts. |
| `go-to-market` | existing collection | moved row in `H6` | Move GTM execution and launch marketing evidence out of product-management. |
| `software-engineering` | existing collection | moved rows in `H1`, `H4`, `H9`, `H11` | Move implementation verification, planning mechanics, technical notes, and skill-repo authoring mechanics out of product-management leaf skills. |

## Collection Surface Changes

| Surface | Change | Owner |
| --- | --- | --- |
| `product-management/README.md` | Replace "no skills published yet" with six skills and update the capability matrix. | main context |
| `product-management/.claude-plugin/marketplace.json` | Add plugin entries for the six skill directories. | main context |
| `product-management/docs/README.md` | No change required unless a focused collection rule doc is added. | main context |
| `product-management/AGENTS.md` | No change required; existing route rules are still correct. | main context |
| `collections.yaml` | No change expected; collection already registered. | main context |
| root `PLAN.md` | No change expected; root plan is an index. | main context |

## Target-Skill Update Packets

| Packet id | Target skill | Receipts | Required files |
| --- | --- | --- | --- |
| `P-product-feature-creator` | `product-management/skills/product-feature-creator/` | `H11`, local-first route rows | `SKILL.md`, `references/template.md`, `references/example.md`, `references/workflow.md`, `references/decision-routing.md`, `references/source-ledger.md`, `references/eval-fixtures.md`, `agents/openai.yaml` |
| `P-product-requirements` | `product-management/skills/product-requirements/` | `H1`, `H2`, `H3`, `H6`, `H8` | `SKILL.md`, `references/template.md`, `references/example.md`, `references/source-ledger.md`, `references/eval-fixtures.md`, `agents/openai.yaml` |
| `P-code-to-product-feature` | `product-management/skills/code-to-product-feature/` | `H7` | `SKILL.md`, `references/template.md`, `references/example.md`, `references/source-ledger.md`, `references/eval-fixtures.md`, `references/framework-patterns.md`, `agents/openai.yaml` |
| `P-product-interaction` | `product-management/skills/product-interaction/` | local-first route rows and supporting package boundary | `SKILL.md`, `references/template.md`, `references/example.md`, `references/source-ledger.md`, `references/eval-fixtures.md`, `agents/openai.yaml` |
| `P-product-user-stories` | `product-management/skills/product-user-stories/` | `H4`, `H9` | `SKILL.md`, `references/template.md`, `references/example.md`, `references/source-ledger.md`, `references/eval-fixtures.md`, `agents/openai.yaml` |
| `P-product-acceptance-criteria` | `product-management/skills/product-acceptance-criteria/` | `H5`, `H10` | `SKILL.md`, `references/template.md`, `references/example.md`, `references/source-ledger.md`, `references/eval-fixtures.md`, `agents/openai.yaml` |

## Authoring Guardrails

- Public skill docs should use local product-management vocabulary, not upstream repo names or commit hashes.
- Provenance belongs in `references/source-ledger.md` and distillation receipts.
- `product-feature-creator` may name the sibling product skills because routing is its owned artifact.
- Leaf skills should first state their owned artifact, then route non-owned work by responsibility.
- Every skill needs `references/eval-fixtures.md` and `agents/openai.yaml`.
- Do not add command files in this pass.
- Do not create a local utility skill, standalone test-scenarios skill, discovery skill, prioritization skill, metrics skill, roadmap skill, or GTM skill in this pass.

## Validation

- `python3 software-engineering/skills/skill-distiller/scripts/validate_distillation_report.py product-management/distillation/H*.md`
- `python3 software-engineering/skills/skill-creator/scripts/validate_skill_package.py <skill-path>` for each target skill
- `scripts/validate-collections`
- `software-engineering/skills/any-to-skill/scripts/upstream-status --root . --segments`
- `git diff --check`

## Closeout

- Bundle classification: `new-skill-needed`
- Collection-routing result: create six first-wave product-management skills and update collection surfaces.
- Open blockers: none.
- Upstream cursor mutations performed by collection routing: none
