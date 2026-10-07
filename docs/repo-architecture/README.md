# Repo Architecture

This directory owns repository-level skill workspace rules. It replaces the
former active collection-architecture skill with a docs surface.

## Current Model

This repository is de-collectionized for local skills:

- root `skills/*` is the active local skill surface
- the Swift skill family is an external linked source checkout
- root `.claude-plugin/marketplace.json` is the active local marketplace

Do not add local product, design, Web, market, or software-engineering child
collections. Add local skills directly under root `skills/`.

## Responsibility Split

- `skills/skill-creator/`: one-skill authoring, hardening, evals, package
  readiness, and tracked source baselines.
- `docs/repo-architecture/`: repo shape, placement, migration,
  marketplace, manifest, and linked-checkout policy.

## Documents

- `repository-shapes.md`: single-skill repo, collection repo, monorepo, and
  linked checkout shapes.
- `ownership-boundaries.md`: root, docs, script, collection, and skill
  ownership boundaries.
- `collection-scaffold.md`: historical scaffold expectations for collection
  repos.
- `migration-patterns.md`: safe moves, wrappers, and consolidation patterns.
- `validation.md`: validation surfaces and failure handling.
- `collection-checklist.md`: collection-level review checklist.
- `templates/`: historical templates for collection and skill placement
  scaffolds.
