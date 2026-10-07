# Proposal In Architecture

## Problem

`docs/architecture/generated-artifacts.md` contains unresolved options:

```markdown
Option A keeps generated OpenAPI clients checked in.
Option B excludes generated clients and builds them during install.
```

## Classification

This content is Proposal because it is still comparing unresolved options. It
is not current architecture truth.

## Normalization

Move the options to `docs/proposals/generated-client-policy.md`.

When a decision is accepted:

- record the rationale in `docs/decisions/generated-client-policy.md`
- restate the current policy in `docs/architecture/generated-artifacts.md`

## Target Result

- `docs/proposals/*` holds unresolved options.
- `docs/decisions/*` records accepted rationale.
- `docs/architecture/*` states what is true now.
