# Route In README

## Problem

Root `README.md` contains agent task routing:

```markdown
Before changing generated contracts, inspect `contracts/` and update
`docs/reference/*` in the same patch.
```

## Classification

This sentence is Route because it tells an agent what to do for a change type.

## Normalization

Move the task-routing sentence to `AGENTS.md`. Keep root `README.md` focused on
public usage and links:

```markdown
Generated contract reference lives in `docs/reference/`.
```

## Target Result

- `AGENTS.md` carries agent routing and operational guardrails.
- `README.md` remains the public landing manual and index.
