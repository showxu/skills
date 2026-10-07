# HITL Gates

Use HITL gates when a decision changes scope, accepted boundaries, public API,
module ownership, architecture truth, or durable docs placement. Do not ask
after every minor step.

Core rule:

- Use HITL before material scope, boundary, or architecture-truth decisions.
- Do not wait until final docs edits if the goal itself is ambiguous.
- Goal unclear: ask at Scope / Goal Gate before running the distillation.
- Boundary unclear: stop at Boundary Gate before local reconstruction.
- Truth unclear: stop at Architecture Truth Gate before editing
  `Docs/Architecture`.

## Scope / Goal Gate

Clarify what is being distilled:

- API
- DSL
- runtime
- UX
- tests
- docs truth
- implementation plan
- case capture

Use when the request names donors but not the local artifact or local decision
they should inform, or when the goal is broad enough that expensive donor work
could answer the wrong architecture question.

Do not force exactly one target. Ask for:

- Primary target.
- Secondary targets.
- Explicit non-goals.
- Output mode:
  - gate decision only
  - dry-run workspace
  - docs update plan
  - implementation plan

## Donor Set Gate

Clarify which upstreams are authoritative, which are reference evidence, and
which are anti-patterns.

Use when donors disagree, the donor list is open-ended, or authority affects
local truth.

## Boundary Gate

Decide what to absorb and what donor baggage to reject. This is one of the two
most important gates.

Use when the decision affects public API, module boundaries, runtime layering,
dependency direction, naming, test harness ownership, or product coupling.
Run this gate before local reconstruction when donor baggage decisions are
material.

## Local Reconstruction Gate

Confirm the local semantic model, DSL/API shape, runtime boundary, product
architecture direction, or implementation-plan target.

Use when synthesis produces multiple plausible local reconstruction options.

## Architecture Truth Gate

Decide what enters `Docs/Architecture`, what enters `Docs/Reference` as
reference facts, what is a proposal, and what stays in `.agent`. This is one of the two most important
gates.

Use before accepted architecture changes are written.

## Case Capture Gate

Decide whether the work should become a curated reusable case capture.

Use only when the user asks to preserve the lesson or when the agent proposes a
case capture as optional follow-up. Do not add cases by default.
