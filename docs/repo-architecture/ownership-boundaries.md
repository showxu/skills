# Ownership Boundaries

## Root Owns

- Compatibility manifest and registered skill-source inventory.
- Registered skill-source inventory and upstream source manifests.
- Root documentation that explains the monorepo model.
- Repository-level operations docs and shared manifest helpers.
- Shared parsers or helpers that are truly repository infrastructure.

## Collection Owns

- Domain boundary and collection route.
- Collection `AGENTS.md`, `README.md`, docs, marketplace metadata, and local
  examples.
- The direct `skills/` directory for local skills.
- Collection-local helper scripts only when they support domain workflows.
- Collection `docs/` owns focused rules that apply across multiple skills in
  that collection, such as collection-local skill authoring, review process,
  evidence policy, source authority, or domain placement.

## Skill Owns

- `SKILL.md` and `agents/openai.yaml`.
- Skill-local `references/`, `templates/`, `assets/`, and `scripts/`.
- Workflow-specific validation helpers and examples.
- Skill `references/` owns detailed workflow manuals, examples, matrices, and
  domain knowledge that only one skill needs.

At this repository-architecture layer, these bullets define placement only.
They do not define the internal quality structure of one skill.
`skill-creator` owns single-skill anatomy, progressive disclosure,
Human-in-the-Loop design, eval fixtures, eval flow, host
compatibility, packaging, and one-skill readiness review.

## Boundary Ownership Model

Use the root `docs/skill-authoring.md` boundary ownership rule when changing
skill or collection routes:

- Leaf skills own domain artifacts such as audits, ledgers, implementation
  patterns, reports, or validation outputs. They should stop at non-owned
  work and describe next ownership by responsibility.
- Route stubs exist for compatibility or discoverability. They may name a
  concrete entrypoint when a migration or taxonomy requires it, but they stay
  short and non-executing.
- Orchestrator skills own routing artifacts such as repo shapes, collection
  placement, handoff queues, owner decisions, bundle classifications, or
  migration plans. They may name concrete downstream owners because routing is
  their product.

When this reference names a sibling owner, state why that is a
repository-architecture routing artifact rather than a leaf-skill boundary
patch. Do not copy downstream
workflow commands, host-specific schemas, or internal quality rules into a
collection route unless the collection itself owns that routing surface.

## Placement Rules

- Put files where they would still make sense if unrelated skill surfaces were
  removed.
- Do not put domain rules in root docs unless they apply across collections.
- Do not put skill-only workflow details in collection docs.
- Do not put collection-wide policy into a single skill just because that skill
  was created first.
- Do not add collection-local validators that duplicate root-owned loader,
  marketplace, or trigger hygiene checks.
- Do not add grouping folders inside a collection's `skills/` directory unless
  the host explicitly supports that shape and the validator understands it.
- Do not keep install examples, manifests, or READMEs pointing at old skill
  names after a move.

Agent-facing source orchestration, source intake, information conservation, and
distillation workflows belong to their owning root skills. The root only owns
the shared manifests and repository infrastructure they read.

## Single-Skill Authoring Boundary

Use the single-skill authoring owner for production instruction quality,
trigger contracts, internal references, progressive disclosure,
Human-in-the-Loop design, eval fixtures, eval flow, host compatibility,
packaging, and `SKILL.md` anatomy. In this repo that owner is
`skill-creator`, which should consult the host official `skill-creator` as
its baseline.

Use this skill for repository placement, collection shape, manifests,
templates, migration, and validation. When this skill creates only a repo-local
skill wrapper or path scaffold, explicitly hand off content authoring by
responsibility; name the concrete skill only when the current repo taxonomy
requires it.
