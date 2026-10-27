# Instructions

## Where Instructions Come From

Find how the scope's instruction files are produced before judging them:

- **Rendered from units.** A declaration lists instruction units from the
  project and from shared sources; a lock pins their revisions; a tool renders
  the instruction files (AGENTS.md, CLAUDE.md, nested files, global files).
  Evaluate and edit the units. Never edit a rendered file.
- **Hand-written.** Evaluate and edit the file in its own repository.

Inspect the global, project and nested levels as each target host actually
discovers and combines them. Similar wording in two files does not prove they
share a source; check the declaration or the synchronization mechanism.

Instruction files own agent guidance. Repository architecture and reference
documents keep their own authority; link to them instead of restating them.

## What a Unit States

A unit states what an agent must do. Background, rationale, evidence,
validation status and dates belong in the owning workflow or reference
documents; a unit points to such a document only when the agent must consult
it to act. Values that change by environment or project come from their owner,
not from a copy in the unit.

## Dimensions for Units

Apply the five dimensions of the upgrade audit with these readings:

1. **Capability gain:** whether the current model still needs the directive.
   Settle doubtful cases with a with/without check on tasks the directive
   governs.
2. **Trigger quality:** for path-scoped units, whether their paths match where
   the rule applies.
3. **Context cost:** global files load in every session of every host;
   measure their size per host and report it.
4. **Conflicts and duplication:** the same intent stated at several levels or
   in several repositories, and contradictions between levels. Name the one
   source each shared intent should come from.
5. **Freshness:** commands, paths, tool names and versions that no longer
   exist.

## Changing Instructions

- Repair stale paths, commands and navigation at the owning unit or file.
- Keep effective project principles verbatim unless the user approves a
  change. Keep each repository usable on its own.
- Propagate shared content only through its source and the supported
  rendering mechanism; keep local differences local.
- A change to the user's principles, authority, permissions, validation
  standards or ownership needs the user's decision: present the exact diff and
  its impact first, and continue with unrelated approved repairs.
- Do not turn a rejected idea into a new prohibition.
- Global instruction sources may be frozen by the user; list proposed changes
  for them as decisions instead of editing.

## Verifying a Change

- Render the instructions, then render again: the second run reports no
  changes.
- Run the instruction tool's doctor for the affected scope.
- Read back in a fresh session on each target host, with no tools: the session
  lists the headings in order and quotes the rules the change affected.
- `git diff --check` and the repository's checks.
