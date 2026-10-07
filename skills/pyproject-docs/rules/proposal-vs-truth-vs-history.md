# Proposal vs Truth vs History

Use this rule when classifying documentation under `docs/`.

## Decision Test

- If the content is still being argued, shaped, or compared, it is Proposal.
- If the content states the current canonical model, it is Truth.
- If the content explains what was decided, what changed, or what is retired,
  it is History.

## Proposal

Purpose:

- hold design-in-progress
- capture options, tradeoffs, and open questions

Belongs:

- proposed structures
- candidate naming and placement options
- unresolved design comparisons

Does not belong:

- current canonical repository structure
- completed decisions
- retired material kept only for record

Example:

- "Option A keeps generated contracts under `contracts/`; Option B moves them
  under `schemas/`."

## Truth

Purpose:

- state the current canonical repository model
- tell readers what is true now

Belongs:

- current architecture descriptions
- current document-role boundaries
- current package documentation layout
- accepted generated-artifact ownership

Does not belong:

- unresolved alternatives
- decision logs and migration diaries
- archived or superseded guidance

Example:

- "Generated OpenAPI clients are reproducible outputs and are not hand-edited."

## History

Purpose:

- preserve the why, how, and retired state of changes over time

Belongs:

- `docs/decisions/*`: decision records and rationale
- `docs/migrations/*`: transition plans, cutovers, and migration notes
- `docs/archive/*`: retired or superseded material kept for record and no
  longer authoritative

Does not belong:

- the current canonical architecture description
- active design exploration
- active guidance that should still be treated as current truth

Examples:

- "ADR-004 adopted lowercase `docs/` role directories."
- "Migration 2026-04 moves generated schema docs out of root README."

## Common Failure Modes

- Proposal text left inside `docs/architecture/*` after a decision is made.
- Current truth written into a decision record and never restated in
  `docs/architecture/*`.
- Migration checklists left as the only source of current structure.
- Archived documents linked as if they were current guidance.
- Historical behavior, transition rationale, or temporary comparison notes are
  written as current product truth.

## Normalization Guidance

- If the document contains unresolved options, move or split that material into
  `docs/proposals/*`.
- If the document states what is true now, move or rewrite it into
  `docs/architecture/*`.
- If the document mainly explains why an accepted change happened, move it into
  `docs/decisions/*`.
- If the document mainly explains a durable transition, rollout, or cutover,
  move it into `docs/migrations/*`.
- Keep temporary notes, local evidence, local paths, run-specific artifacts,
  and current-session explanations in `.agent/*` or omit them.
- If the document is retained only for record, move it into `docs/archive/*`
  and mark it as retired and non-current.
- When one file mixes roles, split by section rather than forcing one file to
  carry Proposal, Truth, and History together.
