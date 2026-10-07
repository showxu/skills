# Repository Shapes

Use the smallest repository shape that can own the lifecycle.

## Single Skill Repo

Use when one skill is the whole artifact.

```text
<repo>/
└── <skill-name>/
    ├── SKILL.md
    ├── agents/openai.yaml
    ├── references/
    ├── templates/
    └── scripts/
```

This shape is useful for personal/global skills, but it does not scale well to
multiple published skills unless a marketplace or collection layer is added.

## Collection Repo

Use when one domain owns multiple related skills.

```text
<collection>/
├── AGENTS.md
├── README.md
├── .claude-plugin/marketplace.json
├── docs/
└── skills/
    └── <skill-name>/
        ├── SKILL.md
        └── agents/openai.yaml
```

The collection owns its own boundary, docs, marketplace metadata, and skills.
The direct children of `skills/` should be real skill directories.

## Multi-Collection Monorepo

Use when one repository maintains multiple collection domains and shared
infrastructure.

```text
<repo>/
├── AGENTS.md
├── README.md
├── docs/
├── scripts/
├── skills/
│   └── <root-maintenance-skill>/
└── <collection>/
    ├── AGENTS.md
    ├── README.md
    ├── .claude-plugin/marketplace.json
    └── skills/
```

The root owns marketplace metadata, upstream source manifests, and
repository-level operations skills. Agent-facing source orchestration and
distillation workflows stay in the owning functional collection.

## Linked Checkout

Use when a source-owned repo should appear inside a local taxonomy without
copying or wrapping its metadata.

```text
<collection>/
└── <linked-family>/ -> /real/source/repo
```

Register the real source checkout in the root manifest when validation,
marketplace metadata, or write-capable follow-ups need the source repo. The
taxonomy path is navigation only.

## In-Tree Linked Collection Repo

Use when the first-level collection directory itself is becoming a
source-owned repo but stays physically inside the monorepo workspace.

```text
<collection>/
├── .git/
├── AGENTS.md
├── README.md
├── .claude-plugin/marketplace.json
└── skills/
    └── <real-skill>/
        └── SKILL.md
```

Register `<collection>` as `type: linked` with `skills_dir: skills`. The root
manifest and validators still provide cross-collection discovery, while the
collection owns its own git history.

## Source-Owned Repo Under A Route

Use when a first-level route contains a complete source-owned repo.

```text
<collection>/
└── skills/              # source-owned repo root
    ├── .git/
    ├── .claude-plugin/marketplace.json
    └── skills/
        └── <real-skill>/
            └── SKILL.md
```

Register `<collection>/skills` as the repo root. Real skill directories resolve
under that repo's own `skills/` layer.
