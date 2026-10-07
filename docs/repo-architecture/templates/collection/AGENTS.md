# <collection-name> Agent Route

Read `README.md` first for the collection scope and authority model.

## Route

- Use each `skills/*/SKILL.md` frontmatter description as the primary trigger
  contract.
- Keep this collection scoped to <owned-domain>.
- Route <handoff-domain> to `<other-collection>`.

## Authority

- `AGENTS.md` files route work and define operational handling.
- `README`-class files are manuals plus indexes for scope, placement,
  ownership, install/use surface, and focused docs.
- `skills/*/SKILL.md` defines each skill boundary and supported operations.
- `.claude-plugin/marketplace.json` is the discovery registry for the
  collection.

## Documentation Guardrails

- Keep README, Reference docs, and bundled user-facing skills focused on current
  product facts, supported behavior, and operating guidance.
- Keep temporary notes, local evidence, local paths, and historical comparison
  notes in `.agent/`. Promote only accepted decisions or durable migration
  records into Decisions or Migrations.
