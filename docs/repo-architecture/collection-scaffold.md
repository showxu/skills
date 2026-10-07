# Collection Scaffold

A collection should start with only the files needed to route, publish, and
maintain its skills.

## Required Files

```text
<collection>/
├── AGENTS.md
├── README.md
├── .claude-plugin/marketplace.json
├── docs/
│   └── README.md
└── skills/
```

Add `docs/skill-authoring.md` only when the collection has enough
domain-specific authoring rules to justify it. It is not a required file for an
empty or thin collection.

## AGENTS.md

Use as a route-only index:

- point to `README.md`
- name positive scope
- name common handoffs
- avoid duplicating durable manual content

## README.md

Use as the manual plus index:

- scope
- published skills
- capability matrix
- input boundaries
- install/use surface
- layout
- documentation index

## docs/

Use `docs/` for focused collection-level rules that are too durable or too
detailed for the collection README, but still apply to more than one skill.

Common files:

- `docs/README.md`: index for collection docs.
- `docs/skill-authoring.md`: collection-local skill shape, naming, trigger,
  and review rules. Create this only when the collection has rules beyond the
  root skill-authoring contract, such as domain-specific split/merge criteria,
  source authority, safety stops, naming families, reference layering, or
  validation evidence.
- `docs/review-process.md`: collection-local review order and evidence rules.
  Create this only when review behavior is materially different from root
  maintenance or generic review practice.
- `docs/<domain-policy>.md`: collection-wide domain policy, source authority,
  safety model, or placement rules. Create this when the policy applies to more
  than one skill.

Do not put one skill's workflow manual in collection `docs/`; put it in that
skill's `references/`. Do not put root manifest, sync, validator, or
cross-collection taxonomy rules in collection `docs/`; put those at the root.

Thin collections may have only `docs/README.md` until real collection-local
rules appear.

## Marketplace

Keep marketplace metadata beside the declared `skills/` directory. A local
collection marketplace should register only skills that exist inside that
collection. A linked checkout with its own marketplace should keep that
metadata in the source checkout.

## Skills Directory

`skills/` direct children should be real skills:

```text
skills/<skill-name>/SKILL.md
```

Do not place `SKILL.md` at collection root and do not add grouping folders
inside `skills/` unless the repo validator and host support that shape.

## First Skill

Before creating the first skill, confirm:

- concrete trigger and user task
- owned output
- neighboring skills or collections
- validation path
- whether `skill-creator` should produce or harden the single-skill content
  scaffold after this skill decides placement and repository shape
