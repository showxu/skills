---
name: agent-evolver
description: "Re-evaluate agent skills and instruction units for a new model, host or agent-tool version, or for newly published official agent guidance. Use for upgrade audits of a skill collection or of AGENTS.md/CLAUDE.md instruction units, for deciding what new official guidance to adopt, and for applying the findings the user approves. Produces an audit report with measured context cost, ranked findings and per-item recommendations, then an ordered cleanup; changes nothing until the user approves. Not for authoring one skill from scratch or installing skills."
---

# Agent Evolver

Skills and instructions written for one model drift as models, hosts and agent
tools change. This skill re-evaluates them against the current model and
current official practice. Improve task performance, information density and
maintainability; a smaller collection or a lower token count is not a goal by
itself.

## Modes

| Mode | When | Output | Stops at |
| --- | --- | --- | --- |
| Upgrade audit | A model, host or agent tool changed, new official agent guidance was published, or the user asks | Audit report for one scope | The user's decision on the findings |
| Approved cleanup | The user approved findings from an audit | Changes in the owning repository through its delivery flow | The repository's merge decision |

## Inputs

- **Scope:** one skill collection (a repository's skills root), named skills
  within one, or one instruction source (its units, declaration and generated
  targets). Audit one scope at a time; several scopes get separate reports.
- **Versions:** the model, host and agent-tool versions the scope is being
  evaluated for. Read them from the hosts; do not assume them.
- **Owners:** the repository guide, its authoring contract, its validation
  commands and, for instructions, the tool that renders them.
- **Evidence access:** usage counts parse session logs for tool calls and
  print only aggregates; reading past session content to build eval cases
  needs the user's permission. See [Evidence](references/evidence.md).

Ask only for facts that change the scope, the owner or evidence access.

## Upgrade Audit

Read-only. Do not edit files, create branches or worktrees, or run checks that
write outside system temporary directories. Write the report to a file only
when the user asks for one.

1. Resolve the scope's repository, owners and validation commands. Read the
   repository guide and authoring contract before judging any item.
2. Establish the host facts for the target versions from official
   documentation and bounded local probes: how skills and instructions load,
   listing budgets, description limits, what survives context compaction.
   Date each fact and name its source.
3. Inventory every item in scope and measure it: always-visible metadata,
   loaded body, on-demand references, and the scope's share of each host's
   listing budget. When a number cannot be measured, state the estimate method.
4. Gather behavior and usage evidence where available: existing fixtures,
   trigger evals, local usage counts, upstream changes for vendored material.
5. Evaluate each item on the five dimensions in
   [Upgrade audit](references/upgrade-audit.md): capability gain over the
   current model, trigger quality, context cost, conflicts and duplicated work,
   and freshness.
6. Classify each finding as Confirmed Defect, Optimization Candidate or Needs
   Verification, and recommend Keep, Simplify, Verify or Retire for each item.
   Do not recommend retirement because the model "should manage now"; require
   a with/without comparison. Keep domain knowledge, compatibility and safety
   constraints. When the benefit is unclear, keep the status quo.
7. Write the report in the format in [Upgrade audit](references/upgrade-audit.md)
   and stop for the user's decision.

For instruction units, apply [Instructions](references/instructions.md) in
steps 3–6.

When the trigger is new official guidance rather than a version change, run a
guidance audit instead of a full one: extract the guidance's concrete
recommendations with their conditions, map each to the items it actually
concerns, evaluate only those items, and report a decision per
recommendation. See [Upgrade audit](references/upgrade-audit.md). Run a full
audit for model, host or agent-tool changes, or when the user asks.

## Approved Cleanup

Change only what the user approved, in the owning repository's task worktree,
through that repository's delivery flow. Follow
[Cleanup](references/cleanup.md): order the work as correctness, structure,
descriptions within listing budgets, then body trimming; account for every
removed block; compare trigger and behavior evals before and after; deliver
one candidate per repository for the requirement.

Use skill-creator for single-skill anatomy, fixtures and eval flow. Edit
instruction units, not generated instruction files, and regenerate through
the project's instruction tool.

## Boundaries

- Installation and links belong to the installation owner; report needed
  follow-ups instead of installing.
- Publishing, releases, dependency upgrades and product code need their own
  owners and authorization.
- Changes to the user's principles, permissions or validation standards are
  the user's decision; show the exact proposed change and its evidence.
- Preserve unrelated working-tree changes in every repository.
- A failed or interrupted run reports what completed and what can resume; it
  never presents a partial result as complete.

## Result

Report the scope and versions evaluated, what was inspected and how, findings
with evidence and confidence, recommendations, blind spots, and the decisions
the user needs to make. Never report a scope as current when only part of it
was inspected.
