# ExecPlans Reference

Use this reference when a coding plan is large enough that the plan must drive
implementation over hours, across compaction, or across handoff to another
agent or human.

Primary source:

- OpenAI Developers Cookbook, "Using PLANS.md for multi-hour problem solving",
  published 2025-10-07:
  `https://developers.openai.com/cookbook/articles/codex_exec_plans`
- Source repository:
  `https://github.com/openai/openai-cookbook/blob/main/articles/codex_exec_plans.md`

## When To Use ExecPlan Mode

Use an ExecPlan variant for:

- complex features
- significant refactors
- migrations with rollback or compatibility risk
- multi-hour implementation tasks
- tasks likely to cross context compaction or agent handoff
- work with substantial unknowns that needs spikes or prototypes
- tasks where the user wants a plan that can be executed without additional
  conversation context

Do not use ExecPlan mode for small changes, ordinary bug fixes, short
documentation edits, or plans that only need a scannable implementation outline.

## Policy File Versus Plan Instance

The official pattern separates two concepts:

- `AGENTS.md`: tells agents when to use an execution plan.
- `.agent/PLANS.md`: defines the local ExecPlan policy and required format.

Treat `.agent/PLANS.md` or `.agents/PLANS.md` as a plan policy surface, not as
the active task plan unless the repository explicitly says otherwise. If one
exists, read it before creating or updating an ExecPlan. If it conflicts with
this reference, prefer the repository-local policy.

When no repository-local policy or active plan location exists, the default
active task plan is `.agent/PLANS.md`. Otherwise, the active task plan may live
in `PLAN.md`, `.agent/PLAN.md`, `.agents/PLAN.md`, `plans/*.md`, or another
repo-declared location.

## Core Standard

An ExecPlan must be self-contained enough that a novice to the repository can
continue from the current working tree and the plan alone. It should not rely
on conversation memory, unstated prior plans, or unexplained jargon.

Preserve these properties:

- Purpose first: explain what the user can do after the change and how to see
  it working.
- Outcome-focused: acceptance is observable behavior, test output, CLI output,
  HTTP response, UI behavior, logs, or another concrete proof.
- Repository-specific: name full repository-relative paths, functions,
  modules, commands, working directories, assumptions, and environment
  constraints.
- Stateful: declare whether the plan is draft, waiting, approved, executing,
  blocked, or completed, and name the next action needed to resume safely.
- Idempotent and recoverable: steps can be retried, or risky steps include a
  rollback/recovery path.
- Validation is required: exact commands, expected output, and diagnosis hints
  must be present.
- Evidence is captured: short terminal output, diffs, logs, or test snippets
  should be recorded when they prove success.

## Living Document Sections

ExecPlans are durable execution documents. They must be updated as work
proceeds. Include and maintain these sections:

- `Progress`: checkbox list with timestamps or clear status notes. Split
  partially completed work into done and remaining parts at stopping points.
- `Task State`: current status, owner, last update, next action, stop reason,
  and out-of-scope follow-ups.
- `Surprises & Discoveries`: unexpected behavior, bugs, performance findings,
  library constraints, or design discoveries, with short evidence snippets.
- `Decision Log`: each meaningful decision, its rationale, date, and author or
  agent.
- `Outcomes & Retrospective`: what was achieved, what remains, and what should
  be learned at major milestones or completion.

Session todos are still useful for moment-to-moment tracking, but in ExecPlan
mode durable state belongs in the plan file itself. Before handoff or stopping,
reconcile session todos into `Task State` and `Progress`.

## Task State And Status

Every ExecPlan must include a `Task State` section that a later agent can use
to decide whether to continue, stop, or ask the user before touching source
files.

Use these status values unless a repository-local policy defines a stricter
set:

- `draft`: planning is not accepted; do not implement.
- `needs-plan-review`: the plan is ready for human review; do not implement.
- `needs-ack`: a human decision is required; do not implement.
- `approved`: the plan can be executed once the user exits plan mode or asks
  for execution in an implementation-capable context.
- `in-progress`: implementation has started; continue only when execution is
  allowed and the next action is clear.
- `blocked`: an external dependency prevents progress; do not continue until
  the blocker is resolved.
- `completed`: closeout is done; do not reopen unless the user explicitly asks.

Use these stop reasons when no repository-local vocabulary exists:

- `none`
- `waiting-for-review`
- `waiting-for-decision`
- `external-blocker`
- `completed`

Persist Human-in-the-Loop outcomes into `Task State`: plan review maps to
`needs-plan-review`, an unresolved decision maps to `needs-ack`, an external
dependency maps to `blocked`, and closeout maps to `completed`.

`Current Next Action` must point to the next concrete unchecked execution step
or state exactly why no step can run. Out-of-scope work discovered during
execution belongs in `Discovered Follow-ups`, not in the current `Progress`
queue.

## Progress Semantics

`Progress` is durable execution history, not a loose todo list.

- Each checkbox must be granular and dated or clearly status-stamped.
- Split partially completed work into completed and remaining items before
  stopping.
- The next actionable unchecked item must match `Current Next Action`.
- Do not mix future scope expansion into `Progress`; put it in `Discovered
  Follow-ups` and decide later whether it needs a separate plan.
- When implementation starts, update `Status` from `approved` to `in-progress`.
- At closeout, mark accurate progress, set `Status: completed`, set
  `Stop Reason: completed`, and summarize results in `Outcomes &
  Retrospective`.

## Milestones

Milestones are narrative execution chunks, not bureaucracy. Each milestone
should describe:

- the goal
- the work to do
- what will exist at the end that did not exist before
- commands to run
- expected observations or outputs
- acceptance criteria

Each milestone should be independently verifiable and move the overall plan
forward.

## Spikes And Prototypes

When requirements are uncertain, libraries are unfamiliar, or multiple designs
are plausible, include explicit spike/prototype milestones.

Spike milestones should be:

- additive and testable
- clearly labeled as prototype scope
- validated with commands or observations
- promoted, revised, or discarded by stated criteria

Parallel implementations can reduce migration risk when both paths are
validated and the plan says how to retire the old path safely.

## Suggested ExecPlan Shape

Use the repository's `.agent/PLANS.md` or `.agents/PLANS.md` if present and it
declares a local policy. If no local policy exists, write the ExecPlan to
`.agent/PLANS.md` using this shape:

```md
# <Action-oriented title>

This ExecPlan is a living document. `Progress`, `Surprises & Discoveries`,
`Task State`, `Decision Log`, and `Outcomes & Retrospective` must be kept
current.

## Task State

Status: draft
Owner: <agent, person, or team>
Last Updated: <YYYY-MM-DD or timestamp>
Current Next Action: <next unchecked execution step, or why none can run>
Stop Reason: none

Discovered Follow-ups:

- <out-of-scope follow-up, or "None yet">

## Purpose / Big Picture

Explain the user-visible outcome and how to see it working.

## Progress

- [ ] <timestamp or status> <granular execution step>

## Surprises & Discoveries

- Observation: <what was discovered>
  Evidence: <short command output, test result, log, or source pointer>

## Decision Log

- Decision: <what was decided>
  Rationale: <why>
  Date/Author: <date and author or agent>

## Outcomes & Retrospective

Summarize completed outcomes, gaps, and lessons at milestones or closeout.

## Context and Orientation

Describe relevant repository state, files, modules, and terms for a novice.

## Plan of Work

Describe the sequence of edits and additions in prose. Name files, functions,
types, and modules precisely.

## Concrete Steps

List exact commands with working directories and expected outputs. Update as
work proceeds.

## Validation and Acceptance

Describe tests, manual checks, system startup, CLI/HTTP/UI observations, and
expected success/failure signals.

## Idempotence and Recovery

Explain retry, rollback, cleanup, and safety boundaries.

## Artifacts and Notes

Keep concise evidence snippets that prove important results.

## Interfaces and Dependencies

Name libraries, modules, services, APIs, types, traits/interfaces, signatures,
and compatibility constraints that matter to the plan.
```

## Closeout

At completion, update the plan before reporting done:

- mark progress accurately
- set `Task State` to `Status: completed` and `Stop Reason: completed`
- add final outcomes and remaining gaps
- record major decisions that shaped the result
- preserve evidence needed by the next agent or maintainer
- move durable architecture or product truth to the repo's declared truth
  surface when the plan is temporary

If the plan is no longer the durable truth after execution, leave a closeout
receipt or remove it only when repository policy and the user request allow it.
Completed plans must not be reopened for adjacent work unless the user
explicitly asks to reopen that plan.
