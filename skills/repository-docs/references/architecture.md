# Maintenance Architecture

## Owned Artifact

This skill owns ecosystem-neutral repository documentation-role rules,
evidence-backed placement audits, and authorized documentation normalization.
It is a staged serial workflow: inspect, classify, choose owners, revise within
authorization, verify. It does not orchestrate other skill executions.

The target repository owns its facts, architecture decisions, document paths,
tool interfaces, and Git state. This skill classifies and relocates those facts
without becoming their authority.

## Resource Responsibilities

| Resource | Responsibility |
| --- | --- |
| SKILL.md | Trigger contract, runtime read route, workflow, audit output |
| rules/route-vs-index.md | Shared role and authority classification |
| rules/readme-layering.md | Shared reader/manual/index layering |
| rules/code-review-rules.md | Review-rule shape and tool entry files |
| scripts/derive_rules.py | Writes and checks the rule copies bundled into adapters |
| references/eval-fixtures.md | Durable behavioral inputs and acceptance checks |
| agents/openai.yaml | Manual entry metadata for the same skill contract |

## Shared Rule Ownership

The three files under rules/ are the maintained source for the neutral role
model. Ecosystem adapters own their language-specific paths, API-documentation
facilities, templates, and project validation entry points.

An independently distributed consumer must bundle complete local rules. If
bundled copies are used, derive them deterministically from this source, retain
source identity, and check synchronization; edit the source rather than a
second handwritten normative copy. A cross-repository relative link is not a
portable distribution dependency.

`scripts/derive_rules.py ADAPTER_SKILL_DIR` writes the bundled copies, each
under a one-line source-identity comment, and `--check` fails when a copy is
missing or differs. Adapters ship in other repositories, so the check runs from
this skill with the adapter path as input. A rule change runs it for every
adapter in the same sitting.

This skill's runtime resources are contained in its package. Documented
handoffs describe the next responsibility; they do not require a sibling skill
name, sibling directory, or sibling script to perform a documentation audit.

## Change And Validation Boundaries

Changing classification requires reviewing both rules and every affected
fixture. Keep examples domain-neutral and target paths case-local. Public
manual instructions and concise edit ownership guards are deliberate positive
cases, not keywords to remove.

Check frontmatter and manual metadata agreement, resource links, package
portability, `derive_rules.py --check` for each adapter, representative audit results, and template/output consistency
when templates are in scope. Package preflight checks structure only; semantic
behavior needs actual evaluation outputs. Evaluation workspaces and run
evidence remain outside the shipped skill.
