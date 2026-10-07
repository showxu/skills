# Orchestration

Use orchestration only when the distillation task is large enough to need
separate evidence gathering, synthesis, and architecture truth gates.

## Execution Modes

### Single-Agent Mode

Use for small tasks, one donor, low ambiguity, or a narrow docs-only review.
The main agent reads local truth, inspects the donor, extracts capabilities and
baggage, synthesizes local reconstruction, and produces the requested artifact.

### Subagent Mode

Default to this mode when the task includes clearly scoped collection across
multiple donors, mixed official/community/product/test sources, or independent
parallel evidence gathering. This default is subject to host capability and
user/system policy. If subagents are unavailable or disallowed, run the same
roles as serial sections in the main context.

Do not add a separate HITL gate only to dispatch bounded collection subagents
when the source scope and non-goals are already clear. Use HITL for material
scope, boundary, reconstruction, and architecture-truth decisions.

Recommended subagent runtime: `gpt-5.3-codex` with `xhigh` reasoning effort,
when the host supports explicit model and effort selection. If unavailable, use
the host default rather than blocking the workflow.

Parallelize subagents by independent source, donor category, or review role
when their scopes do not overlap. Do not parallelize dependent synthesis,
boundary decisions, HITL gates, or architecture truth updates; those stay with
the main agent.

Subagent mode is for evidence collection and extraction:

- local truth scan
- upstream repo, docs, examples, and tests scan
- donor capability and semantics extraction
- baggage, coupling, and risk identification
- per-source findings

Subagent mode is not for final architecture decisions. The main agent owns
synthesis, local reconstruction, docs destination decisions, and any accepted
architecture truth update.

### HITL Mode

Use HITL mode when the result may change public API, module boundaries,
runtime boundaries, architecture truth, or donor-baggage decisions.

Use HITL before material scope, boundary, or architecture-truth decisions. Do
not wait until final docs edits if the goal itself is ambiguous:

- Goal unclear: ask at Scope / Goal Gate before local truth or donor work.
- Boundary unclear: stop at Boundary Gate before local reconstruction.
- Truth unclear: stop at Architecture Truth Gate before editing
  `Docs/Architecture`.

Scope / Goal Gate should identify primary target, secondary targets, explicit
non-goals, and output mode. Do not make broad architecture requests choose one
exclusive target when several layers may be in scope.

Use gates at material decision points, not after every minor step. The most
important gates are Boundary Gate and Architecture Truth Gate.

## Core Flow

```text
Scope / Goal Gate
-> Local repo truth scan
+ Upstream repo/docs/examples/tests scan
-> Per-source findings
-> Main-agent synthesis
-> Boundary Gate
-> Local Reconstruction Gate
-> Architecture Truth Gate
-> Docs/Architecture update
-> Optional Docs/Reference promotion
-> Optional case capture
```

## Central Rules

- Subagents collect evidence, extraction, and risk.
- The main agent performs synthesis, local reconstruction, and final
  architecture truth updates.
- Subagents must not independently edit architecture truth.
- Findings are not architecture truth.
- Synthesis is not architecture truth until accepted through the required HITL
  gate.
- Case capture happens only after the Case Capture Gate accepts preserving the
  lesson.
