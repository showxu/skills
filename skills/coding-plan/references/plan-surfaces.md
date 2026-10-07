# Plan Surface Detection

Use this reference when a repository has more than one possible plan location.
The goal is to choose the plan surface that matches the repository contract
and current task without overwriting unrelated work.

## Surface Types

- Route file: `AGENTS.md`, `README.md`, docs index, or package guide that tells
  agents where plans live.
- Policy file: `.agent/PLANS.md`, `.agents/PLANS.md`, or equivalent file that
  explicitly defines how plans should be written.
- Active task plan: `.agent/PLANS.md` when used as the fallback surface,
  `PLAN.md`, `.agent/PLAN.md`, `.agents/PLAN.md`, `plans/*.md`,
  package-local plan, or collection-local plan.
- Archive/history: completed, locked, paused, closeout-only, or old plan files.
  Use these as format references, not active task plans, unless the user
  explicitly asks to reopen them.

## Common Combinations

### Root `PLAN.md` only

Use root `PLAN.md` when the repository contract says it is the active plan
layer, or when it is the only existing plan surface and it clearly belongs to
the current task.

If root `PLAN.md` is about a different active task, do not overwrite it. Create
a new accepted plan file or ask if there is a real conflict.

### Package-local `PLAN.md`

Use a package-local `PLAN.md` when the task is scoped to that package and the
repo or package docs treat that file as the active execution queue.

Do not write a root plan for a package-only task just because root exists.

### `.agent/PLANS.md` plus `.agent/PLAN.md`

Treat `.agent/PLANS.md` as the policy file and `.agent/PLAN.md` as the active
task plan unless the repository says otherwise.

Read `.agent/PLANS.md` first, then create or update `.agent/PLAN.md` according
to that policy.

### Fallback `.agent/PLANS.md`

Use `.agent/PLANS.md` as the default active task plan when the repository has
no clearer plan convention and the user did not name another path.

If `.agent/PLANS.md` already exists, inspect it before writing. Treat it as a
policy file only when its content clearly defines plan rules or points to a
separate active task surface. If it belongs to unrelated active work, ask or use
the repo-declared separate surface rather than overwriting it.

### `plans/` directory only

Use an existing matching `plans/*.md` when it is the same task. Otherwise create
a new fallback `.agent/PLANS.md` unless the repository already requires new
task plans under `plans/`.

If several plan files look related, choose the one with matching module, goal,
or status; do not merge unrelated plans.

### Root plan plus feature plan

Use the root plan as a parent/roadmap when it describes a broad initiative and
the current work is one slice. Add a slice to the root plan only if its existing
architecture uses slices. Otherwise create a feature plan and reference the
root plan briefly.

### Locked or paused plan

Do not append new work to a locked, paused, archived, or completed plan. Use it
as a structure reference and create a current plan unless the user explicitly
asks to reopen it.

## Decision Checklist

Before writing, answer:

1. Did the user name a path?
2. Did `AGENTS.md` or repo docs name a plan surface?
3. Is there a policy file that defines the plan format?
4. Is there an active plan for the same task?
5. Is an existing plan locked, paused, completed, or unrelated?
6. Should this be an update, a subplan/slice, or a new plan?
7. Is the chosen plan temporary, durable, or an execution ledger with closeout?

Record the selected surface and reason in the plan `Context` when it affects
future execution.
