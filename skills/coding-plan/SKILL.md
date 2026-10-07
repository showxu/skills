---
name: coding-plan
description: Enter plan mode for a coding task inside a code repository. Use when the user asks for a written implementation plan before code changes, says plan mode, /coding-plan, make a plan, draft a plan first, give me a plan before you code, write a PLAN.md, update the existing PLAN.md, add a subplan, ExecPlan, PLANS.md, multi-hour plan, think before coding, investigate the codebase and propose an approach without touching source files, or otherwise asks for a repo-local plan artifact such as PLAN.md, .agent/PLAN.md, .agents/PLAN.md, .agent/PLANS.md, .agents/PLANS.md, or a repo-declared plans/*.md file. The default fallback plan surface is .agent/PLANS.md. This skill is read-only except for writing the selected plan file. Do not use when the user wants immediate implementation, a code review findings report, non-code research planning, final prose, or a conversational answer without a plan artifact.
---

# Plan Mode

A read-only, 4-phase workflow for coding tasks. Output is a single repo-local
plan file that a teammate or later agent can scan before saying "go".

This skill is for code repositories: implementation, refactor, bug fix,
migration, testing, build, engineering docs, repository maintenance, and
source-level investigation plans. It is not a generic brainstorming mode and
does not execute the implementation.

For complex features, significant refactors, migrations, multi-hour tasks,
unknown-heavy designs, or work likely to cross context compaction or agent
handoff, read `references/execplans.md` and use the ExecPlan variant instead
of the short fallback plan shape.

ExecPlan mode must include a `Task State` section with status, owner, last
update, current next action, stop reason, and discovered follow-ups. Use it to
make a single plan resumable without relying on session todos, chat history, or
external task trackers.

When a repository has multiple possible plan locations, read
`references/plan-surfaces.md` before writing or updating a plan.

## Hard constraint: read-only

While this skill is active:

- The only file you may write is the selected plan file. Do NOT edit source
  files.
- Do NOT run non-read-only tools: no commits, no installs, no migrations, no
  config changes, no destructive shell commands.
- Read-only operations are encouraged: file reads, code search, doc lookup,
  web search, non-mutating tool help, and dry-run inspection commands.
- If a command may change repository state, skip it or ask before running it.

Apply this boundary during the user's planning request, within the host's
instruction hierarchy. An explicit request to implement the plan ends this
skill's planning-only scope; the selected plan remains the execution record.

Use the available task tracker, such as `update_plan` or `todo_write`, for a
4-phase session workflow. Session todos track the agent's current work; they are
not durable plan state unless the selected plan file already uses persistent
progress checkboxes or status fields.

## HITL gates

Ask only when the answer changes the plan target, write surface, permissions, or
runtime topology. Keep questions focused and continue only the work listed as
allowed before answer.

When ExecPlan mode is active, persist unresolved HITL outcomes in `Task State`.
Set `Status: needs-plan-review` for required human plan review,
`Status: needs-ack` for a missing human decision, and `Status: blocked` for an
external blocker. Do not implement while any of those statuses is current.

### Ambiguous target

- Trigger: the request lacks a concrete module, issue, branch, diff, file family,
  bug, feature, or accepted design.
- Question: "Which module, issue, file set, or accepted design should this plan
  target?"
- Why it matters: a standalone coding plan needs real paths, likely changed
  files, risks, and verification commands.
- Options: user supplies a target; user narrows to docs/tests/investigation; user
  cancels plan mode.
- Safe default: do not write a plan file.
- Allowed before answer: read route files, plan policy, README indexes, and any
  obvious docs needed to explain what is missing.
- Blocked until answer: writing a plan, inventing a target, broad source scans,
  source edits, or implementation.
- Artifact: if a plan is later written, record the chosen target in `Context`;
  in ExecPlan mode also record any waiting state in `Task State`; otherwise
  state in the response that no plan was written.

### Plan-surface conflict

- Trigger: the user names a plan path that may conflict with repository rules,
  multiple active surfaces look plausible, or an existing active plan belongs to
  different work.
- Question: "Should I use `<path A>`, use `<path B>`, or create a separate plan
  for this task?"
- Why it matters: the wrong surface can overwrite unrelated work or put durable
  execution state in a policy/index file.
- Options: use the user-named path, use the repo-declared active surface, create
  a separate accepted plan, or stop.
- Safe default: do not overwrite or repurpose an unrelated active plan.
- Allowed before answer: read policy files, existing plan headings/status, and
  nearby docs that define ownership.
- Blocked until answer: overwriting a plan, appending to unrelated active work,
  creating a fallback directory when repository policy is unclear, or renaming
  plan files.
- Artifact: record the selected surface and active-plan decision in `Context`.
  In ExecPlan mode, use `Task State` only for the current plan instance; do not
  use it to repurpose a policy file or unrelated active plan.

### Possibly mutating inspection command

- Trigger: an inspection command may write caches, install packages, start
  services, create artifacts, run migrations, or otherwise change repository or
  environment state.
- Question: "May I run `<command>` for inspection, or should I record it as a
  future verification step?"
- Why it matters: plan mode is read-only except for the selected plan artifact.
- Options: run the command, use a safer read-only alternative, or list it as
  future verification only.
- Safe default: skip the command and record it as future verification.
- Allowed before answer: run clearly read-only alternatives such as file reads,
  code search, tool help, version checks, or dry-run commands that the local repo
  treats as non-mutating.
- Blocked until answer: the possibly mutating command and any dependent claims
  that require its output.
- Artifact: note skipped commands in `Verification` or `Context` when they affect
  execution confidence. In ExecPlan mode, record a blocking skipped command as
  `Status: needs-ack` only when the command output is required before the plan
  can stand alone.

### Locked-plan reopen

- Trigger: a matching or nearby plan is completed, locked, paused, archived, or
  closeout-only, and the user has not explicitly asked to reopen it.
- Question: "Do you want to reopen `<path>`, or should I create a new current
  plan for this task?"
- Why it matters: reviving old execution state can erase closeout meaning and
  confuse the next implementer.
- Options: reopen the existing plan, create a new plan, or stop.
- Safe default: treat the old plan as a format reference and create a new plan
  only if repository policy gives a non-conflicting surface.
- Allowed before answer: read the old plan enough to classify status and reuse
  structure.
- Blocked until answer: appending to, renaming, or changing status on the locked
  or completed plan.
- Artifact: record the status decision in `Context` or the ExecPlan `Decision
  Log`. Completed ExecPlans must remain `Status: completed` unless the user
  explicitly asks to reopen them.

### Implementation permission

- Trigger: the plan is written, or the user gives generic continuation language
  such as "go on" without clearly exiting plan mode.
- Question: "Do you want me to leave plan mode and implement this plan?"
- Why it matters: this skill does not execute implementation while active.
- Options: stay in plan mode, revise the plan, or leave plan mode and implement.
- Safe default: stay in plan mode and report the plan path.
- Allowed before answer: read back the plan, report validation gaps, or adjust
  the plan if the user asks for planning changes.
- Blocked until answer: source edits, installs, commits, migrations, tests that
  mutate state, or live operations.
- Artifact: if execution starts later, use the repository's implementation
  progress surface rather than treating session todos as durable plan state.
  For ExecPlans, execution starts from `Status: approved` and moves to
  `Status: in-progress` in the plan file during the execution workflow, not
  during this read-only planning workflow.

### Read-only subagent fan-out

- Trigger: independent read-only investigation or verification could materially
  improve the plan and can be bounded by objective, input paths, output shape,
  and stop condition.
- Default: use clean-context read-only subagent passes after serial framing for
  complex planning unless the task is clearly narrow or the user asks to keep
  work in the main context.
- Ask only when the fan-out boundary, host mechanics, cost, data exposure, or
  permission surface is unclear.
- Allowed: spawning bounded read-only subagents for independent investigation or
  verification slices.
- Blocked: asking agents to edit files, write the plan, choose the plan
  surface, make irreversible decisions, or run unbounded exploration.
- Artifact: record any fan-out and returned evidence in `Context`, `Approach`,
  or the ExecPlan `Surprises & Discoveries` / `Decision Log`.

## Runtime topology

The default workflow is staged serial with parallel read batches. Ordinary file
reads and code searches can be parallelized during preparation, but the lead
agent owns the final synthesis and writes one coherent plan artifact.

1. Serial framing: identify the user goal, repository contract, plan-surface
   candidates, active-plan status, and the first file families to inspect.
2. Parallel preparation: batch independent file reads, searches, and metadata
   inspection when local tools support it. This is still read-only and does not
   require subagents.
3. Default read-only fan-out: for complex planning, use subagents after serial
   framing unless the task is clearly narrow or the user asks to stay in the
   main context. Each slice must name objective, input paths, boundaries,
   allowed tools, output shape, and stop condition.
4. Serial fan-in: compare evidence, resolve conflicts by inspecting sources,
   choose the plan surface, and write or update the single selected plan artifact
   or the repository-defined subplan/slice.
5. Verification planning: independent verification ideas may be gathered in
   parallel, but the plan records one ordered verification path with expected
   signals and failure diagnosis.

Do not use parallel agents for same-file writes, source edits, plan writes, or
plan-surface decisions. For multiple independent tasks, choose a parent ExecPlan,
repo-defined slices, or separate plan files only after classifying the task
relationship and, when unclear, asking the plan-surface gate.

## Phase 1 - Understanding

Figure out what the user wants, how the relevant code works, and where the
plan belongs.

- Read the repository contract first: `AGENTS.md`, `README.md`, relevant
  docs indexes, plan policy files such as `.agent/PLANS.md` or
  `.agents/PLANS.md`, existing `PLAN.md`, `.agent/PLAN.md`,
  `.agents/PLAN.md`, `plans/`, or collection/package-local planning rules.
- Identify the current task goal, target module, requested output, and whether
  the user asked for a new plan, an update to an existing plan, or a subplan.
- Read the files implicated by the request, plus obvious dependencies:
  callers, tests, configs, schemas, package manifests, types, routes, and
  build/test entry points.
- Identify every file that will likely need to change. The most common plan
  failure is discovering a new file mid-execution that should have been listed
  up front. Investigate enough to avoid that.
- Actively search for existing functions, utilities, and patterns that can be
  reused. Avoid proposing new code when suitable implementations already
  exist.
- If something is ambiguous in a way that materially changes the design, ask a
  focused clarification. Do not ask trivia. Batch related questions.

You do not need to read the whole repo. Read enough that Phase 2 is not
guesswork.

## Phase 2 - Design

Pick one recommended approach.

- Consider 2-3 alternatives internally; only the chosen one goes into the
  plan.
- Find every touched file by working outward from the obvious. Do not trust
  your first guess to be complete. Useful tactics:
  - Grep for the symbols, types, and strings being changed; every callsite is
    a candidate.
  - Glob by file/path pattern to enumerate the feature area.
  - Read entry points such as `package.json`, `Package.swift`, main routers,
    `index.*`, app entry files, route registrations, and plugin manifests.
  - Walk tests in the feature area; they often touch files otherwise missed.
  - For typed languages, follow the type chain and import graph.
  - For schema or data-shape changes, check migrations, fixtures, seed
    scripts, generated files, and config files.
  - Batch independent reads and searches in parallel when available; follow the
    runtime topology above before using subagents or fan-out work.
- For each touched file, decide what kind of change it needs: add, modify,
  delete, rename, generated, or no-change/reference-only.
- Separate files by confidence:
  - definite: the implementation almost certainly changes this file
  - possible: the implementation may change this file after closer execution
  - intentionally out of scope: related but should not be changed in this plan
- Stick to scope. If you noticed adjacent issues during investigation,
  mention them and let the user decide whether they belong in this plan or a
  separate one. Do not silently expand scope.
- Surface hidden technical risks. Do not just list steps; analyze pitfalls
  such as breaking API changes, migrations, data loss, deadlocks, race
  conditions, performance regressions, compatibility constraints, and
  operational risk. Explain how the plan addresses each one.

Nothing gets written to source files.

## Phase 3 - Review

Sanity-check the design before writing the plan file. The goal is to catch
things you would otherwise discover the hard way during execution.

- Re-read the critical files. First-pass impressions miss hidden callsites,
  side effects, type mismatches, generated surfaces, or related code that also
  needs touching.
- Re-run the key searches that justify the file list. Record enough search
  terms or path families in the plan that a later executor understands the
  boundary.
- Surface risks: breaking changes for callers, irreversible migrations, perf
  regressions, concurrency issues, data loss, security impact, live-service
  effects, or platform compatibility. If something is risky, fold a mitigation
  into the steps; if unavoidable, call it out before writing the plan.
- Walk through edge cases: empty input, null/missing state, large inputs,
  concurrent writes, stale caches, interrupted runs, retry behavior, and
  partial failure.
- Verify version-sensitive details. Library APIs, framework idioms, tool
  commands, and language features should come from the codebase's actual
  versions and current docs/tool help, not from memory.
- Check test impact. What existing tests will break? What new tests are
  needed? If tests are nontrivial, give them their own step.
- Compare against the user's original request. If the design drifted, adjust.
- If anything material is still unclear, ask before writing the plan file.

## Phase 4 - Write the plan file

The plan must stand alone. Someone reading it a week later, or another agent
picking up the task, should be able to act on it without the conversation
context.

### Plan surface selection

Do not assume `plans/` is the only plan location. Select the plan surface from
the repository contract and current state.

Check these surfaces in order:

1. Explicit user request: a named plan path always wins if it does not
   conflict with repository rules.
2. Repository route files: `AGENTS.md`, `README.md`, docs indexes, or package
   docs that declare where active plans live.
3. Plan policy files: `.agent/PLANS.md`, `.agents/PLANS.md`, or equivalent
   repo-declared documents that define how execution plans should be written.
4. Existing active plan files: `PLAN.md`, `.agent/PLAN.md`, `.agents/PLAN.md`,
   `plans/*.md`, collection-local plans, package-local plans, or other
   documented planning locations.
5. Existing plan architecture: headings, status fields, slices, ledgers,
   checkboxes, closeout sections, and naming conventions.
6. Fallback: if the repo has no planning convention, create or update
   `.agent/PLANS.md`.

Treat `.agent/PLANS.md` and `.agents/PLANS.md` as policy surfaces only when the
repository clearly uses them that way or provides a separate active plan
surface. Otherwise, `.agent/PLANS.md` is the default active fallback plan
surface.

### Active plan handling

Before writing, decide whether an existing active plan is the same work.

- Same task, same goal, or same module: update the existing plan.
- Same large initiative but new subtask: add a new slice/subplan using the
  existing plan architecture.
- Related but separable task: create a separate plan in the repo's accepted
  plan surface and cross-reference only if useful.
- Different active task: do not overwrite or repurpose it. Create a new plan
  or ask if there is a real conflict.
- Completed, locked, paused, archived, or closeout-only plan: do not revive it.
  Use it as a format reference and create a current plan unless the user
  explicitly asks to reopen it.

When updating an existing plan, preserve unrelated user or agent notes. Change
only the sections needed for the current task.

### Filename

If fallback is needed, use:

`.agent/PLANS.md`

Do not create `plans/` by default. Use a `plans/<prefix>-<short-kebab-name>.md`
file only when the user names that path, repository policy requires it, or an
existing repo pattern clearly uses per-task files. If `.agent/` does not
exist, create it. If `.agent/PLANS.md` already exists and belongs to unrelated
active work or is explicitly a policy-only file, ask before overwriting or
repurposing it.

### Structure

Use the repository's existing plan architecture when one exists. If there is
no repo-specific structure and ExecPlan mode does not apply, write four
sections in this order:

```
# <Title>

## Context
<Why this change is being made: the problem or need, what prompted it, the
intended outcome, selected plan surface, and any relevant active-plan decision.
1-4 sentences.>

## Approach

### 1. <Sub-task title> - `affected/file.ts` (add / modify)

<Explain what this sub-task does and how. Include:>
- Key function/class/interface names and signatures
- Core implementation logic, pseudocode, or key snippet where it clarifies
  intent
- Edge cases or technical risks handled here, and how
- Discovery receipt when useful: symbols, paths, tests, or entry points checked

### 2. <Next sub-task> ...

## Key Files

| File | Change | Notes |
|------|--------|-------|
| `path/to/existing.ts` | modify | <one short clause about what changes> |
| `path/to/new.ts` | add | <what this new file is for> |
| `path/to/legacy.ts` | delete | <why removed> |
| `path/to/related.ts` | no-change | <why intentionally out of scope> |

## Verification

<How to confirm the implementation is correct end-to-end. Include static
checks, targeted tests, broader tests, manual checks, expected outputs, failure
diagnosis, and any closeout destination for durable docs/state.>
```

Title is a noun phrase, not a sentence: `JWT Auth Refactor`, not
`How to refactor JWT`. File paths in Approach and Key Files must be actual
paths from the codebase. The `Change` column should use `add`, `modify`,
`delete`, `rename`, `generated`, `possible`, or `no-change`. If a file is
renamed, list the old path as `delete` and the new path as `add` unless the
repo's plan format has a rename convention.

### Style - plain, no decoration

- No emojis.
- No bold or italic for emphasis. Backticks for paths and identifiers are
  fine.
- No horizontal rules.
- No marketing adjectives such as "seamless", "robust", or "elegant". State
  what happens, not how nice it will be.
- No filler preambles. Start directly.
- Match the user's conversation language for the plan content.

### Length

The plan should be scannable. The fallback plan normally fits in one to two
screens:

- Context: 1-4 sentences.
- Approach: 3-8 numbered sub-tasks.
- Key Files: 3-12 entries; include important no-change boundaries when they
  prevent scope drift.
- Verification: 2-6 concrete commands or checkpoints.

Use a longer plan only when the repo or task genuinely needs a ledger,
multi-slice execution queue, migration checklist, or ExecPlan.

For ExecPlan mode, follow `references/execplans.md` instead of the short
fallback structure. Include `Task State`, maintain `Progress` as durable
execution history, keep `Current Next Action` aligned with the next unchecked
execution step, and put out-of-scope discoveries in `Discovered Follow-ups`
instead of silently expanding current scope.

## Handoff

Once the plan is written, read it back to confirm:

- the selected plan file is the right surface for the repo and task
- all required sections are present
- Key Files or the repo's equivalent file inventory is well formed
- real paths are used throughout
- active plan status was handled without overwriting unrelated work
- no source files were edited
- verification and closeout are concrete enough for execution
- ExecPlan mode, when used, includes maintained `Task State`, `Progress`,
  `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective`
  sections
- ExecPlan `Status`, `Stop Reason`, and `Current Next Action` make it clear
  whether the next agent may continue, must stop for human input, is blocked, or
  is looking at a completed plan that must not be reopened without explicit
  instruction
- ExecPlan progress checkboxes are granular durable history, partial work is
  split into completed and remaining items, and out-of-scope discoveries are
  separated into `Discovered Follow-ups`

Report the plan path and whether it is new, updated, or a subplan. Do not start
implementation unless the user explicitly exits plan mode or asks to execute.

## Maintenance

When changing trigger wording, plan-surface behavior, read-only constraints,
HITL gates, runtime topology, or ExecPlan routing, read
`references/eval-fixtures.md` and rerun representative should-trigger /
should-not-trigger fixtures before landing the change.
Keep formal eval outputs in the eval workspace or review surface as
`review.html`, `benchmark.json`, `feedback.json`, transcripts, and raw outputs.
Do not add a skill-local eval artifact log.

## Source Receipts

Baseline source: MagicCube/helixent `skills/coding-plan/SKILL.md` at
`0fca9272760c457d38082bfa8d4c561ce22e9850`.

Local hardening added repo-discovered plan surfaces, `.agent/PLAN.md` and
`.agents/PLAN.md` handling, active plan status decisions, explicit HITL gates,
runtime topology, ExecPlan `Task State`, session todo vs durable progress
boundaries, discovery receipts, and closeout rules.

Official ExecPlan reference: OpenAI Developers Cookbook, "Using PLANS.md for
multi-hour problem solving", published 2025-10-07:
`https://developers.openai.com/cookbook/articles/codex_exec_plans`.
