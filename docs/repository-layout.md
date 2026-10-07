# Repository Layout

Repository artifacts live with the smallest owner that can explain and maintain
them. Local skills are de-collectionized: root `skills/*` is the active local
public skill directory.

## Ownership Layers

- Monorepo root owns infrastructure: root marketplace, upstream manifests,
  root docs, and repository-level operations skills.
- Monorepo root owns shared upstream manifests.
- Repository-local Codex configuration in `.codex/config.toml` is ignored
  machine state for automations or commands launched from this repository.
- Root `.claude-plugin/marketplace.json` owns local plugin groups. Groups are
  discovery and install views, may overlap, and are not ownership boundaries.
- For separately owned linked checkouts, source manifests should point at the
  real checkout root. Do not create wrapper marketplace metadata in this
  monorepo for an external repository that already owns its own metadata.
- A skill owns its workflow support files: `SKILL.md`, `agents/openai.yaml`,
  skill-local references, templates, assets, and helper scripts. At the repo
  layout layer, this only defines placement: files that exist for one skill
  stay inside that skill directory. Single-skill anatomy, quality gates,
  progressive disclosure, eval fixtures, eval flow, HITL, and packaging are
  owned by `skill-creator`.

## Documentation Roles

- `README.md` is the root manual and index for the skill collection and its
  installation routes.
- `AGENTS.md` is the root agent routing index. It should point to the README
  and focused docs instead of duplicating durable manual content.
- Historical child-collection docs belong under `docs/provenance/` and must not
  be treated as active routing authority.

## Placement Rules

- Use `collection-taxonomy.md` before adding or moving local skills. It now
  defines marketplace group routing and linked external source policy, not
  local child-collection placement.
- Put root-level artifacts in root docs only when they describe the shared
  repository model, lifecycle overlays, marketplace grouping, or upstream
  intake.
- Put domain-specific workflow detail inside the owning skill unless it is a
  cross-skill lifecycle overlay.
- Put files that exist only to implement one skill's workflow inside that
  skill directory. Do not use repository layout docs to prescribe that skill's
  internal quality structure; route that decision to `skill-creator`.
- Put local skill directories as direct children of root `skills/`. Each direct
  child of `skills/` must be a real skill directory with `SKILL.md`. Do not add
  grouping folders inside root `skills/`.
- Do not duplicate skill inventories in prose when root manifests or
  marketplace metadata already carry them.
- Put durable operating rules in README or focused docs, then link to them from
  `AGENTS.md`.
- Put repository-specific Codex sandbox additions in the ignored local
  `.codex/config.toml`, not in global `~/.codex/config.toml`. When a registered linked checkout is reached
  through a symlink, grant access to the real checkout path instead of the
  symlink path so sandbox write authorization follows the actual target.
- Do not add root wrapper scripts for skill-local helpers just for convenience.
  Document the skill-local command instead.
- If shared code is genuinely needed by multiple owners, extract only the
  shared library or parser to the nearest shared owner. Keep executable
  workflow entry points with the owner of the workflow.
- When an external linked source exposes skills from a separately owned
  checkout, document the source owner and keep the manifest pointed at the real
  checkout root. Do not copy, move, or wrap the source tree's repository
  metadata just to satisfy this repo's marketplace grouping.

## Scripts

- Root `scripts/` is for monorepo infrastructure only: source manifest helpers
  and other commands that are not owned by a single skill.
- Skill helper scripts belong under that skill's `scripts/` directory.

## Automations

- Automations that target this monorepo must treat root `skills/*`, root
  marketplace metadata, and source manifests as the relevant skill surfaces.
- Automation prompts should use root manifests instead of hard-coding old
  collection directories or scanning unregistered paths.
- For linked external families such as Swift skills, automations should use the
  real source checkout path for metadata or write-capable follow-ups.

## Examples

- Local collection-specific validators do not belong here. Skill readiness,
  trigger hygiene, and package checks are maintained by `skill-creator`.
- A nested `.git` is allowed only at a collection root registered as
  `type: linked`; otherwise it is an unexpected nested repository. Generated
  artifact directories such as `.build/` are ignored because they are not source
  ownership boundaries.
- Domain skill docs, templates, assets, and examples belong in the owning
  skill, not in root docs.

## Review Question

Before adding or moving a file, ask: "Would this file still make sense if the
owning skill did not exist?"

If the answer is no, the file should not live at the monorepo root.
