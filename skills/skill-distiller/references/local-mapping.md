# Local Mapping

## Destination Order

Prefer local destinations in this order:

1. Existing skill `SKILL.md` when the core trigger, boundary, or workflow must
   change.
2. Existing skill `references/` when the source adds depth, examples, matrices,
   edge cases, or practice notes.
3. Existing skill `scripts/`, `templates/`, or `assets/` when the source adds a
   reusable artifact with a clear owner.
4. Collection docs when the rule applies across multiple skills in that
   collection.
5. `moved` or `deferred` with owner and reason when another collection or future
   thread should carry it.
6. New skill only when local trigger/workflow/validation boundaries are distinct
   and approved.

## Upstream Tracking Boundary

When the requested action is to check whether an upstream changed, update
upstream cursor fields, refresh review state, or mutate tracking fields, stop
before doing any local mapping. Those requests are not distillation scope.

After a distillation pass, it is valid to state that an upstream coverage
receipt or cursor decision may be needed. That recommendation is an output row,
not permission for `skill-distiller` to move the cursor.

## Handover Rows

For rows that are not direct skill prose, record:

- operations or value
- setup/auth and required host state
- output shape
- safety boundary
- validation or failure modes
- candidate backend/adapter
- owner or destination
- authority status
- preserved evidence or source path

`moved` and `deferred` mean the value is retained for later handling, not
forgotten.

Do not reject MCP servers, CLIs, editor extensions, app connectors, tool
services, official docs, resources, or agent workflow prompts just because they
are not a `SKILL.md`. First record the capability or handover row. Then decide
whether an existing local skill can carry it as a backend, adapter, workflow
reference, setup note, validation path, or failure-mode rule.

## Public Wording

Local collection public docs should read as self-owned capability specs. Avoid
exposing upstream repo names, upstream SHAs, source copy ledgers, or temporary
review details in collection README or architecture docs unless that surface is
explicitly a review ledger.

When source material becomes public local guidance, translate it into the local
owner's vocabulary and authority model. Keep provenance in the ledger or
skill-local reference when needed; do not make public docs read like an
upstream comparison report.
