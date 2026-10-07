# Codex Exec Plans

Use this reference when deciding whether a Python documentation normalize,
migration, or export task needs a session-spanning `.agent/PLANS.md` execution
aid.

## When To Create `.agent/PLANS.md`

Create `.agent/PLANS.md` when the work is large enough that another agent or a
future session must resume it without chat history:

- documentation tree migration from non-canonical paths into `docs/*`
- profile export across many files
- role collision cleanup across README, AGENTS, proposals, decisions,
  reference docs, and architecture truth
- generated-output boundary cleanup across contracts, schemas, API docs, and
  generated clients
- any normalize operation where active work cannot be safely finished in one
  pass

## When Not To Create It

Do not create `.agent/PLANS.md` for a small audit, single-file README fix, or a
pure report that does not leave resumable implementation state.

## Placement

The active plan surface is:

```text
.agent/PLANS.md
```

Do not place execution plans at repository root, under `docs/*`, or in
`.github/*`.

## Content

The plan should record:

- task state and next action
- selected profile or target shape
- role collisions found
- files to move, split, rewrite, or leave alone
- validation commands
- open decisions and blockers

Keep run-specific notes inside `.agent/*`; promote only accepted current truth
to `docs/architecture/*` or other formal docs.
