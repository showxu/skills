---
description: Route showxu/skills repository and skill changes to their owning documents, and keep skill content inside its skill.
---
# Skills Agent Guide

Read root `README.md` first for repository purpose and entry points, then
`docs/README.md` for the documentation index.

## Task Route

- Use `docs/repository-layout.md` and `docs/repo-architecture/` for repository
  shape, placement, linked-checkout policy, migration, validation, and root
  ownership questions. Historical records under `docs/provenance/` are not
  routing authority.
- Use `docs/collection-taxonomy.md` before adding, moving, grouping, or
  registering skills.
- Use `docs/skill-authoring.md` for repository-wide trigger and manual-entry
  rules. Use `skills/skill-creator/` for single-skill anatomy, production
  quality gates, fixtures, HITL, eval flow, packaging, and one-skill readiness.
- When changing a specific `skills/<name>/`, first read that skill's
  `SKILL.md`, then `skills/<name>/references/architecture.md` if it exists,
  plus directly relevant skill-local references linked from the entrypoint or
  owning artifact.
- The root `.claude-plugin/plugin.json` defines the `showxu-skills` Claude
  plugin and `.claude-plugin/marketplace.json` publishes it; `upstreams.yaml`
  owns upstream source tracking.
- Before finishing repository-level changes, run
  `python3 -B scripts/check_repository.py` and `git diff --check`.

## Repository Guardrails

- Put skill-specific docs, examples, templates, assets, runtime helpers, and
  workflow policy inside the owning `skills/<name>/` directory. Add local skills
  directly under `skills/<name>/`, without child collections or grouping
  folders.
- Use root `scripts/` only for repository infrastructure such as source
  manifest helpers. Do not add root wrappers for skill-local helpers.
- For linked external skill families, use source manifests or the referenced
  source checkout before metadata or write-capable follow-ups.
