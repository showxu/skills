# Cleanup

Apply only the findings the user approved. Work in the owning repository's
task worktree and follow its guide, authoring contract and delivery flow.

## Before Editing

- Read each target's `SKILL.md`, its maintenance architecture and the
  references, scripts and templates the change touches.
- Keep engineering choices, counterexamples, failure modes, validation
  routes, source receipts and needed compatibility. Do not reduce a skill to
  an API index or a thin router.
- Prefer a focused reference change while the trigger and responsibility stay
  correct; revise the description and manual-entry metadata together when the
  task boundary changes.
- Confirm each approved item has a fixture that would catch a regression in
  the behavior being changed. Add a minimal fixture first where it is missing:
  cases that must trigger, cases that must not, and one output case.
- Record the baseline: listing size per host, trigger eval results, and the
  validation commands' results at the base revision.

## Order

Keep one change per step so each can be reviewed on its own:

1. **Correctness and safety.** Wrong facts, broken examples, unsafe defaults,
   contradictions between items.
2. **Structure.** Ownership between items, one-way references, maintainer
   material in the files that own it, and repository checks for frontmatter,
   links, cycles and listing size.
3. **Descriptions.** Fit every description into each host's listing budget.
   Lead with the framework or task, keep distinctive triggers and only the
   boundaries a neighbour could blur; move the rest into the body. Enforce the
   budget with the repository's check when it has one.
4. **Bodies.** Move long sequences and reference material into references,
   put gates and safety rules early in the body, and cut what the current
   model does without being told. Keep only the permission and validation
   guards that the item's own contract or practice requires; do not add the
   same generic restrictions to every skill.

Before retiring an item, confirm its receiver covers the retained capability
under real discovery and use, then update references and installation through
their owners. Keep correct provenance records.

Renaming a skill is breaking: record the rename and the upgrade step in the
repository's changelog.

## Accounting for Removals

For every removed or moved block, add a row to the change's description:

| File | Removed or moved block | Where the information is now, or why it is dropped |
| --- | --- | --- |

A dropped block needs evidence that it is wrong, unused or duplicated.

## Validation

- The repository's checks and `git diff --check`.
- Trigger evals on the same host version as the baseline: no case may
  regress. Report new hits and remaining misses.
- With/without comparisons for any item whose body was cut substantially.
- Typecheck or run changed examples against the SDK or tool version they
  target.

## Delivery

- One candidate per repository for the requirement, with the steps above as
  separate commits.
- One independent review of the whole candidate, then one review of the
  fixes.
- The repository releases once, after the requirement is complete, following
  its own versioning rules.
