# Subagent Brief: <Role / Source>

## Objective

<Focused evidence task for this role/source.>

## Local Context To Respect

<Local architecture truth, module boundaries, docs destinations, and non-goals.>

## Source / Donor To Inspect

<Repo, docs, API, product reference, examples, tests, fixtures, or local path.>

## Recommended Runtime

Use `gpt-5.3-codex` with `xhigh` reasoning effort when the host supports
explicit subagent model selection. If unavailable, use the host default.

## Parallelization

This brief may run in parallel with other independent source, donor, or review
briefs. Do not duplicate another subagent's scope, and do not perform synthesis
or HITL decisions.

## Questions To Answer

<Concrete questions this pass must answer.>

## Evidence To Collect

<Paths, docs, APIs, tests, examples, links, versions, commits, and quotes or
short excerpts when useful.>

## Required Output

<Findings report path or inline findings shape.>

## Non-Goals

<Work this subagent must not do.>

## Boundaries

- If the scope or goal is ambiguous, report the ambiguity instead of expanding
  the assignment. Name the missing primary target, secondary targets, explicit
  non-goals, or output mode.
- Do not edit `Docs/Architecture`.
- Do not decide local architecture truth.
- Produce findings only.
