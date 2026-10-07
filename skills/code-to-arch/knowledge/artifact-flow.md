# Artifact Flow

Use staged artifacts to prevent raw findings or tentative synthesis from
becoming architecture truth too early.

## Destinations

### `.agent/code-to-arch-distillation/<topic>/`

Task-scoped workflow workspace for one distillation effort. This directory is
not architecture truth.

Suggested contents:

```text
.agent/code-to-arch-distillation/<topic>/
  README.md
  local-truth.md
  findings/
    <source>.md
  synthesis.md
  hitl-gates.md
  docs-update-plan.md
  case-capture-draft.md
```

### `.agent/code-to-arch-distillation/<topic>/README.md`

Optional index for the task-scoped distillation workspace.

### `.agent/code-to-arch-distillation/<topic>/local-truth.md`

Local repo truth scan: README, `AGENTS.md`, `Docs/Architecture`,
`Docs/Reference`, `Docs/Proposals`, `Docs/Decisions`, `.agent` plans, package
layout, examples, and tests.

### `.agent/code-to-arch-distillation/<topic>/findings/<source>.md`

Per-source findings from local repo and donor/upstream scans. These are not
architecture truth.

### `.agent/code-to-arch-distillation/<topic>/synthesis.md`

Main-agent synthesis report. This is evidence summary and recommendation, not
automatically current truth.

### `.agent/code-to-arch-distillation/<topic>/hitl-gates.md`

HITL gate notes and unresolved decisions.

### `.agent/code-to-arch-distillation/<topic>/docs-update-plan.md`

Planned destination for accepted changes across `Docs/Architecture`,
`Docs/Reference`, `Docs/Proposals`, `Docs/Decisions`, README, `AGENTS.md`, or
`.agent`.

### `.agent/code-to-arch-distillation/<topic>/case-capture-draft.md`

Optional case capture draft only when the user asks to preserve the lesson.

### `Docs/Reference/*`

Current reference facts in product language: protocol and API references,
compatibility references, and cited specifications. Donor notes, upstream
inventories, and source comparisons stay in the staged workspace.

### `Docs/Proposals/*`

Design-in-progress when local reconstruction is not accepted yet.

### `Docs/Architecture/*`

Accepted local architecture truth only after synthesis and required HITL gates.

### `Docs/Decisions/*`

Accepted architectural decisions and tradeoff records.

### Future `knowledge/cases/*`

Curated reusable skill cases only after an explicit Case Capture Gate. This
skill intentionally does not keep scaffolded sample cases in `knowledge/`.
Until a case is explicitly promoted, preserve teaching material under
`references/example-captures/` or task-scoped `.agent` artifacts instead.

## Rule

Scope / Goal Gate before expensive donor work when the goal is ambiguous.
Findings before synthesis. Synthesis before architecture truth. HITL before
accepted architecture changes.

## Practical Flow

1. Ask Scope / Goal Gate first when the objective or local artifact is unclear:
   primary target, secondary targets, explicit non-goals, and output mode.
2. Write or return per-source findings.
3. Synthesize findings into one distillation report.
4. Ask Boundary Gate or Architecture Truth Gate when decisions materially
   change local architecture.
5. Write `Docs/Reference` for accepted reference facts when useful.
6. Write `Docs/Proposals` for unaccepted local reconstruction.
7. Write `Docs/Architecture` only for accepted current truth.
8. Write `Docs/Decisions` only for accepted decision records.
9. Add case capture only after the Case Capture Gate.
