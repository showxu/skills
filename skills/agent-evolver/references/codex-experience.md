# Codex Experience

Read this topic when the request selects Codex memory, rollout or session
evidence. Use it within agent-evolver’s common workflow, with the access and
mutation gates below. Read [evidence rules](codex-evidence-rules.md) before
collecting or classifying evidence.

## Purpose

Distill real Codex memory, rollout, session, and project evidence before
recommending skill evolution. The output is a behavior-backed update packet,
no-change/watch decision, or owner handoff; it is not the final single-skill
edit.

This topic exists to help Codex agents self-evolve from repeated behavior,
repeated failures, and repeated workflows. It must not invent skills from
themes alone.

The target repository can be any repository. Use the current `cwd` as the
target unless the user or automation specifies another root.

For one existing target skill, `skill-creator` owns the final local edit:
trigger boundary, `SKILL.md` structure, references/scripts/assets placement,
fixtures, HITL, evals, package validation, and readiness decision. If Codex
evidence affects several existing skills whose responsibilities remain
unchanged, produce one update packet per target. If it implies a new skill,
split, rename, ownership conflict, or collection boundary change, prepare a
repository architecture packet.

## Core Rule

No evidence, no evolution.

Use concrete repo and session evidence. If evidence is weak, recommend no
change or ask for the missing evidence instead of proposing a new skill.

## Trigger Gate

Use this topic only when the request is explicitly about Codex memory/session
evidence and agent self-evolution. Good trigger signals include:

- stale, incomplete, missing, duplicated, or noisy skills evidenced by past
  Codex work
- repeated Codex agent mistakes backed by memory/session evidence
- whether to create, update, split, merge, remove, or schedule audits for
  skills based on accumulated evidence
- recurring Codex session evidence that a separate official-source refresh may
  be needed

Do not use this topic for generic docs, validation, testing, code review,
release, cross-collection feed tracking, monorepo structure checks, static
repository quality, or package-to-skill distillation requests just because
those tasks mention repeated work or project evidence. Route those to their
domain skill unless the user explicitly asks about Codex memory/session
evidence and skill evolution.

If the request is about refreshing a skill from official documentation, API
docs, CLI help, schemas, resource endpoints, or observed host behavior, use
the official-knowledge topic and its source-verification reference. This
experience topic may raise a source-verification question; it does not treat
conversation evidence as proof of an official-source change.

For SwiftPM package distillation, this topic may identify evidence that a
project-local skill is stale, missing, or noisy. It does not perform the package
distillation itself. After an approved evolution decision, hand Swift package
evidence to `swiftpm-distiller`, then apply generic skill hygiene only after
the package-specific trigger, workflow, guardrails, validation, and failure
modes have been extracted and a `skill-creator` update pass is approved.

## Workflow

1. Map the project surface:
   - repo root and current `cwd`
   - `AGENTS.md`, `README.md`, docs, architecture notes, roadmaps, ledgers, or
     validation docs
   - existing project-local skills under `.agents/skills`, `.codex/skills`, or
     `skills`
2. Prefer the bundled inventory helper for the first pass when available:
   - run
     `python3 skills/agent-evolver/scripts/collect_evidence.py --root <project>`
     from this skill's collection, or the equivalent absolute path when the
     skill is installed elsewhere
   - add narrow `--term` values for module names, scripts, commands, or skill
     names that matter to the request
   - when running inside a recurring automation, pass `--automation-id <id>` or
     `--automation-memory <path>` so the helper includes automation-local
     memory as policy/backlog context
   - use `--include-sessions` only when memory and rollout summaries lack
     concrete evidence
   - use `--include-archived-sessions` when archived Codex chats may contain
     repeated project evidence that active sessions no longer show
   - when raw current or archived sessions are scanned from a recurring
     automation, pass an automation-local `--evidence-ledger <path>
     --no-update-evidence-ledger` so already judged repo-scoped sessions are
     skipped on later runs without marking newly scanned files processed before
     triage
   - the helper reports scanned and ledger-skipped raw session files with
     `ledger_key` values; use those keys to report each file's disposition
   - write raw-session ledger entries only after triage with
     `--update-evidence-ledger` plus either a uniform `--ledger-disposition` or
     a `--ledger-disposition-file` keyed by `ledger_key`
   - keep raw session scans repo-scoped by default; use broad/global scanning
     only when the user explicitly asks for cross-repository trends
3. Build the memory/session evidence path manually when the helper is not
   available:
   - runtime memory summary already in context, if present
   - automation-local memory such as
     `$CODEX_HOME/automations/<automation-id>/memory.md`, when this run is a
     recurring automation; use it as operational lessons, prior backlog
     signals, output-format corrections, and ledger-scope lessons
   - `$CODEX_HOME/memories/MEMORY.md` or `~/.codex/memories/MEMORY.md`
   - `$CODEX_HOME/memories/rollout_summaries/` or
     `~/.codex/memories/rollout_summaries/`
   - raw `$CODEX_HOME/sessions/` or `~/.codex/sessions/` only when summaries
     are insufficient
   - raw `$CODEX_HOME/archived_sessions/` or
     `~/.codex/archived_sessions/` only when archived chats may hold missing
     project evidence
4. Search narrowly:
   - repo name and basename
   - exact `cwd`
   - important module, script, command, or skill names
   - repeated failure text or validation commands
5. Treat automation-local memory as an index and policy-history source, not as
   authority for target-repo skill drift. It may route a target-repo
   skill-drift signal only when it names a concrete target repo, skill, and
   evidence pointer; verify that signal against Codex memory, rollout
   summaries, raw sessions, or repo-local evidence before classification.
6. Compare evidence against existing skills before suggesting anything new.
7. Check overlap with installed shared skills after project-local skills:
   - `$CODEX_HOME/skills`
   - `$CODEX_HOME/skills/public`, when present
   - `~/.codex/skills` when `CODEX_HOME` is unset
   Do not reject a project-local skill only because a shared skill exists.
   Project-specific paths, validation rules, ownership boundaries, or failure
   shields can still justify a local specialization.
8. If Codex evidence points to a stale official-source claim, classify it as an
   official-knowledge question for source verification in its own evidence phase.
9. Classify each candidate as:
   - update existing skill
   - add reference/rule/script to existing skill
   - new skill candidate
   - no-change / do not create
10. Route accepted candidates:
   - one existing target skill: behavior-backed update packet for
     `skill-creator`
   - several independently updatable existing skills: one packet per target
   - new skill, split, rename, ownership conflict, or collection boundary:
     repository architecture packet
   - package-specific distillation: handoff to the owning distiller before any
     generic skill-creator hardening
11. Return a compact decision report with evidence, destination owner, and owner
   decisions needed.

## HITL Gates

- Interactive runs ask for a short scope confirmation before evidence
  collection, even for read-only checks. Skip the question only when the user
  explicitly named the target repo/evidence scope in the current request, or
  when a scheduled prompt already defines the target, read-only boundary, and
  allowed evidence sources.
- Broad/global memory scans, raw current-session scans, archived-session scans,
  ledger writes, or cross-repository audits require explicit approval or a
  scheduled prompt that permits that scope. Safe default: use repo-local docs,
  existing skills, memories, and rollout summaries only.
- Subagents or parallel evidence review require explicit user request for
  subagents, parallel agents, independent agents, broad audit, or a scheduled
  prompt that permits read-only fan-out. Safe default: run serially.
- Running `skill-creator`, editing skill files, changing triggers, adding
  fixtures, running evals, packaging, staging, committing, or moving collection
  boundaries requires explicit approval and the destination owner. Safe default:
  emit an update packet only.
- Missing routing facts that change the destination owner require a routing
  decision. Safe default: mark `needs owner decision`.

## Parallel Evidence Path

Subagents are optional and require the HITL gate above unless a scheduled prompt
already permits read-only fan-out. Ask whether to use subagents only after the
lead agent has identified concrete independent evidence slices.

Use subagents when at least one of these is true:

- The request or scheduled prompt names multiple target repositories.
- One target repo has independent evidence groups, such as project-local skill
  groups, memory windows, rollout-summary groups, or raw-session batches.
- The evidence review needs different search terms or long transcript/log
  inspection that would pollute the lead context.
- A scheduled or user-approved broad Codex evidence audit asks for parallel
  read-only evidence collection.
- The user explicitly asks for subagents, parallel agents, independent agents,
  or a broad memory/session audit.

Do not use subagents when:

- The request targets one repository and the needed evidence is already in
  current repo docs, existing skills, memory, or rollout summaries.
- The target repo, evidence scope, search terms, or destination owner is unclear.
- Raw or archived session access, ledger writes, or cross-repository scanning
  has not been approved.
- The work is final authoring, trigger rewriting, fixture creation, eval,
  packaging, staging, committing, or any file edit.
- Multiple workers would inspect and decide the same memory/session batch
  without distinct responsibilities.

The lead agent prepares the scope and assigns each worker: target repo, evidence
sources, exact search terms, ledger policy, forbidden actions, and output schema.

Worker output must include `target_repo`, `evidence_source`, `matched_skill`,
`observed_pattern`, `evidence_pointer`, `decision`, `confidence`, `proposed_owner`,
and `blockers`. Workers must not edit files, write ledgers unless the prompt
explicitly authorized it, run `skill-creator`, or decide collection
placement. The lead agent deduplicates evidence, applies the evidence
thresholds, and writes one behavior-backed update packet per accepted target.

## Scheduled Mode

Use scheduled mode when this topic runs from a recurring Codex automation or
other periodic job.

The automation's `cwd` or `cwds` selects the target repository. A scheduled run
over this skill's collection is just one possible target; the same skill can
audit Swift, web, operations, product, or other repositories.

Scheduled runs must be read-only by default:

- collect bounded evidence with `scripts/collect_evidence.py`
- read automation-local memory when the run is attached to a recurring
  automation; extract operational lessons and routed signals, then verify
  target-repo signals before classifying them as skill drift
- scan memory and rollout summaries every run; scan raw current or archived
  sessions only when summaries are insufficient
- use a processed-evidence ledger for raw session scans so archived sessions
  already handled for the same target repo and unchanged content are not
  rescanned on every run
- collect raw sessions with the ledger in read/skip mode first; assign every
  scanned raw file a disposition before writing ledger entries
- never ledger `untriaged/incomplete` raw-session candidates
- compare current evidence against existing local and shared skills
- report new, stale, repeated, or no-change findings
- produce behavior-backed update packets for later approved `skill-creator`
  or repository architecture passes
- never create, edit, delete, split, merge, stage, commit, push, or open PRs
  unless a later human request approves a specific mutation

Suggested cadence:

- weekly for active projects with frequent Codex sessions
- monthly for stable projects
- on demand after major workflow migrations or repeated agent failures

Scheduled reports should include:

- time window or evidence horizon used
- skipped evidence sources and why
- automation-local memory lessons and routed signals, if any
- processed-evidence ledger path and raw sessions skipped by the ledger when
  raw sessions were scanned
- raw session files scanned and skipped by the ledger, with per-file
  disposition and unledgered `untriaged/incomplete` candidates called out
- high-confidence recommendations
- low-confidence observations to watch
- explicit no-change decisions
- destination owner for each accepted update packet
- owner decisions needed before any mutation

Scheduled results are triaged through
`references/codex-evidence-rules.md#result-triage`; treat them as backlog items, not
approved mutations.

Do not conflate scheduled Codex experience reports with package distillation
inboxes. A package distillation inbox inventories packages, imports, and
package-local evidence gaps; `swiftpm-distiller` owns that workflow. This topic
owns evidence-backed decisions about whether existing local skills should be
updated, split, merged, removed, or left unchanged based on actual Codex
behavior.

## References

Paths below are relative to the skill root.

- `references/codex-evidence-rules.md`: evidence model, candidate thresholds,
  no-change rules, and output rubric.
- `references/licenses.md`: attribution notes for retained material.
- `scripts/collect_evidence.py`: bounded local evidence inventory helper.
- `templates/codex-experience-audit.md`: reusable prompt for recurring Codex
  automations.

## Decision Rules

- Prefer updating existing skills over creating new ones.
- Recommend a new skill only when the workflow is repeated, distinct, and
  reusable.
- Recommend no change when the evidence is a one-off bug, a broad topic, or a
  generic model capability.
- Do not bulk-load all memories or raw sessions. Start from summaries and open
  raw JSONL only for missing concrete evidence.
- Treat the target repository as the default evidence grain. Raw current or
  archived sessions must match the target repo path, repo basename, or explicit
  narrow search terms before they count as project evidence.
- Do not mutate skills inside this workflow. When a user approves a specific
  one-skill change, hand the behavior-backed update packet to
  `skill-creator`. When the approval concerns placement, new skills, splits,
  renames, or collection boundaries, prepare a repository architecture packet.
- When naming new candidates, prefer short hyphen-case names that describe the
  workflow. Use project prefixes only when they improve clarity.

## Output Format

```text
Codex Experience Audit

Evidence reviewed:
- ...

Automation-local memory:
- lessons:
- routed signals:

Existing skills:
- skill: current scope, observed drift

Repeated workflows / failures:
- pattern: evidence, frequency, impact

Official-knowledge verification questions:
- skill/source area: Codex evidence for possible official-source refresh

Suggested updates:
- skill:
  evidence:
  proposed change:
  destination owner: skill-creator | repository architecture
  update packet:
    observed behavior:
    affected trigger or workflow:
    guardrails to preserve:
    recommended skill-creator entry mode:
  priority:

Suggested new skills:
- name:
  trigger:
  evidence:
  core workflow:
  resources:
  risks:
  owner decision needed:

Do not create:
- candidate:
  reason:

Priority order:
- ...

Owner decisions needed:
- ...
```

## Failure / Uncertainty Handling

- If memory or session history is unavailable, label the audit evidence-limited
  and rely on repo-local docs and current worktree evidence.
- If the project has no existing skills, still report candidate thresholds and
  no-change decisions.
- If a requested change is ordinary coding or review work, say it is outside
  this topic and identify whether any repeated workflow evidence was found.
- If the user approves a proposed one-skill mutation, hand the update packet to
  `skill-creator` instead of editing the skill inside this workflow.
