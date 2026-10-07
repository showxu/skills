---
name: agent-evolver
description: "Evolve agent instructions and skills from official documentation, OpenAI or Anthropic best practices, SDK/CLI evidence, and Codex memory, rollout or session experience. Use for knowledge refreshes, AGENTS.md improvements, repeated agent mistakes, evidence-backed skill candidates, and manual or scheduled evolution audits. Produces per-target evidence decisions, authorized improvements, validation and pending work. Select the relevant evolution topic; installation and link management remain separate."
---

# Agent Evolver

Evolve the knowledge and operating guidance an agent actually uses. Preserve
accurate official knowledge, concrete engineering judgment, counterexamples,
and accepted project principles. A shorter file or newer timestamp is not an
independent success criterion.

## Ownership and Inputs

This skill owns a bounded evolution batch: target selection, authoritative
source and experience comparison, protected-rule mapping, update packets,
authorized instruction repairs, skill-authoring handoffs, and the resulting
validation/pending state.
It supports both a manual target/source request and a scheduled profile.

Accept supplied articles or excerpts, official docs and resource endpoints,
tool help and schemas, SDK/compiler/package evidence, scoped Codex memory,
rollout summaries or sessions, existing skills and AGENTS.md files, and an
optional local maintenance profile. Resolve the actual repository, source
owner, installed identity, version, and relevant rules before
making a change. Do not infer ownership from an installation directory.

Select the relevant topics from the request or configured scope, then load only
their references:

| Topic | Evidence and purpose | Required reference |
| --- | --- | --- |
| `official-knowledge` | Official docs, supplied practices and tool/platform evidence; verify changed facts and applicable guidance. | [Source verification](references/source-verification.md) |
| `codex-experience` | Codex memory, rollout summaries and scoped sessions; identify repeated failures, successful practices and evidence-backed skill candidates. | [Codex experience](references/codex-experience.md), then its evidence rules |

A task can use both topics. Keep authoritative facts and observed experience
distinct; an experience signal can raise a source question without proving the
source changed. A knowledge refresh does not implicitly request session access.

Choose the entry mode from the request:

- **Evidence audit:** inspect the named evidence and return per-target packets,
  no-change/watch decisions, or owner questions. It does not edit targets.
  `source-audit` selects this mode for official-knowledge work.
- **Evolution batch:** continue the already-authorized inspection, bounded
  editing, validation, and state update. A profile selects targets and permitted
  actions; it cannot grant permissions the user or host did not provide.

Codex experience audits produce recommendations by default. Their scheduled
scope, raw-session access, ledger writes and target mutation gates remain in
the topic reference. A general evolution batch does not approve implementing
every newly discovered behavior recommendation; a concrete approved change can
continue through the authoring owner.

When scope is missing, clarify only facts that change the owner, writable
targets, or evidence access. A named target/source request or configured
scheduled scope already supplies that context. Optional account access, broad
unscoped discovery, costly scans, and live mutations need their own authorization.

## Workflow

1. Read the target repository entry and instruction hierarchy, then the target
   skill and its maintenance architecture. For workspace-governed operations,
   follow that workspace's actual CLI contract.
2. Load only the selected profile, current target records, and relevant
   references. Temporary downloads and probes belong in cache; accepted
   progress and recovery evidence do not. See [State and recovery](references/state-and-recovery.md).
   For collection-wide upkeep, discover the current skills within the supplied
   source and installation scope on every run before selecting the batch.
   Reconcile source identity, real path and declared name with prior records:
   new targets start pending, changed targets retain their prior validation
   revisions, and missing targets retain history until their disposition is
   established. A failed scope scan cannot establish absence. Prior inventory
   is progress, not a target whitelist; the deep-review cap applies after
   discovery. Explicitly named target audits can keep their exact selection.
3. Select the smallest useful batch. Scheduled runs honor the configured cap,
   prioritize real failures and known changes, and advance the oldest eligible
   pending verification. Review due existing knowledge even without a new
   article. Record a retry condition for unavailable sources or environments.
4. Identify the exact local claim or repeated behavior and apply the selected
   topic's evidence rules. A fetch, directory listing, source inventory or
   matching session line is not a completed knowledge or behavior review.
5. Compare the verified evidence and local contract. Record accept-update,
   no-change, watch, or needs-owner-decision with evidence and applicability.
   Several independently repairable targets receive separate packets; a split,
   rename, new skill, ownership conflict, or collection-boundary change requires
   an explicit architecture decision.
6. Preserve the affected principles, source receipts, patch policies, examples,
   scripts, templates, compatibility paths, and acceptance criteria before
   editing. Apply the rules in
   [Instruction and skill changes](references/instruction-and-skill-changes.md).
7. In evolution mode, finish the authorized repair within the topic's mutation
   scope. This caller may compose an evidence packet with capability conservation
   and the existing skill-creation workflow; it does not turn an evidence-only
   leaf workflow into an editor.
   Use skill-creator for final skill authoring and its existing per-skill
   validation/review flow. Instruction repairs remain with the instruction
   owner. Evidence-audit mode stops at its requested packet.
8. Validate the changed behavior and record actual results. Reuse valid evidence
   for unchanged versions; expand or repeat tests only for new changes,
   failures, or unresolved concerns. Do not replace required human feedback,
   lower criteria, or invent benchmark results.
9. Update the selected state records only after triage. Keep source inspection,
   package revision, compilation, runtime, human feedback, pending decisions,
   and recovery distinct. Report any installation follow-up to its owner.

## Adjacent Responsibilities

- Broad external-source intake belongs to any-to-skill. Package-to-skill evidence
  belongs to its domain distiller; compiler interface output is evidence, not
  authority to decide skill placement.
- skill-distiller preserves capabilities when consolidation needs a conservation
  pass. Use it when relevant, not as a mandatory stage for every small edit.
- skill-cli owns installed source requirements, materialization, and links.
  Emit the affected source, skill, scope, agent, mode, and readiness when
  synchronization is needed. Do not implement a second installer here.
- Product code, dependency upgrades, publishing, plugin lifecycle changes, and
  changes to the user's authority or production rules need their own owners
  and authorization.

## Scheduled Use

The scheduler supplies this skill, topics, a profile or explicit targets, and
the invocation mode. Cadence, machine paths, enabled directions, batch size, and
notification preference belong to that invocation/profile, not duplicated
copies of this workflow.

Use the same source and validation standards as manual work. Finish authorized
local work, preserve dirty targets, and continue independent targets when one
is blocked. Do not reopen a completed execution plan or permanent Goal for
routine runs. Use parallel agents only when explicitly authorized and when
their read-only evidence slices are independent.

## Result

Return a concise result with:

- targets and source evidence actually inspected;
- selected topics, observed behavior, confidence and evidence access limits;
- per-target decision and the claim affected;
- changed artifacts and validation actually completed;
- pending knowledge, unavailable environments, or owner decisions;
- installation follow-ups for the corresponding owner;
- state and exact recovery evidence, if files changed.

For a quiet scheduled profile, notify only on an actual update, actionable
failure, or required decision, deduplicated by source/target/decision. An
unchanged record is not a new notification. Never report all knowledge current
when only entries or a subset of their references were reviewed.
