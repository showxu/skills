# Upstream Intake Report: <Topic>

## Objective

<What local architecture question this intake must answer.>

## Scope / Goal Gate

<If the objective is broad or ambiguous, ask before expensive donor work. Do not
force exactly one target. Capture:
- Primary target:
- Secondary targets:
- Explicit non-goals:
- Output mode: gate decision only / dry-run workspace / docs update plan /
  implementation plan.
If already explicit, say no gate needed.>

## Local Project Context

<Repo, module, product surface, current phase, and affected owners.>

## Current Local Truth

<Docs, APIs, modules, tests, and boundaries read before donor conclusions. Cite
local file paths.>

## Orchestration Mode

<Single-agent / default subagent / HITL. Default to subagent mode for clearly
scoped multi-donor or parallel evidence gathering when the host allows it.>

## Candidate Upstreams

<List upstreams, donor repos, official APIs, products, protocols, fixtures, and
anti-patterns.>

## Donor Classification

| Donor | Category | Confidence | Reason |
|---|---|---|---|
| <donor> | <category> | <high/medium/low> | <why it matters> |

## Why Each Upstream Matters

<Explain the useful design pressure each donor can provide.>

## What To Inspect

<Files, docs, APIs, tests, product states, examples, fixtures, or releases to
inspect.>

## Per-Source Findings

<Findings paths or summaries. Use
`.agent/code-to-arch-distillation/<topic>/findings/<source>.md` when
writing per-source artifacts.>

## Extracted Capabilities

<Capabilities, semantics, API shapes, tests, UX patterns, names, and boundaries
that are reusable.>

## Rejected Baggage

<Product coupling, implementation assumptions, file layout, dependency graph,
test harness assumptions, visual clutter, or names to reject.>

## Local Reconstruction Options

<DSL, runtime abstraction, facade, docs truth, test harness, UX flow, semantic
model, or layered architecture options.>

## Recommended Architecture Direction

<Recommended local framework direction and why.>

## HITL Gate

<Scope / Goal Gate if the goal is ambiguous, Boundary Gate before material local
reconstruction, or Architecture Truth Gate before accepting architecture truth
or changing Docs/Architecture.>

## Open Questions

<Questions that block architecture truth or implementation planning.>

## Evidence / References

<Local file paths and upstream evidence. Use links or commit/path references
when available.>

## Recommended Next Codex Prompt

```text
<Self-contained follow-up prompt for research, architecture review,
implementation planning, or docs updates.>
```
