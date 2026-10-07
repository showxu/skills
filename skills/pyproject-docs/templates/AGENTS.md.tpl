# Agent Guide

Read `README.md` first, then the relevant file under `docs/architecture/`
before changing public behavior, generated contracts, provider behavior,
source bundles, MCP behavior, bundled skills, packaging, or documentation
truth.

## Repository Invariants

- `pyproject.toml` is the project fact source for package name, supported
  Python versions, dependency groups, build backend, and console scripts.
- Treat conversation, review feedback, plans, and intermediate attempts as
  editing input. Recompute the complete accepted result before finalizing.
- Active artifacts depend only on that result and their repository role, not
  on the editing path. Apply this to implementation, names, options, branches,
  errors, configuration, schemas, generated sources, scripts, templates,
  comments and docstrings, tests, fixtures, snapshots, examples, and normative
  docs.
- If an intermediate result is `A + B` and the accepted result is `A`, express
  `A` directly. Remove `B` and its residual surface rather than retaining names
  such as `AOnly` or `AWithoutB`, or prose such as "B was removed."
- Normalize by semantic identity and artifact role, not by token. A rejected
  current capability does not invalidate a distinct historical fact,
  migration, ownership record, or safety boundary that uses the same term.
- Keep a negative constraint only when excluding `B` is independently required
  by a current compatibility, safety, or ownership invariant.
- A disabled B flag, skipped B test, dead B branch, retained B fixture, or
  "do not add B" rule is residue when it exists only because B was attempted;
  disabled state alone is not an invariant.
- Keep change history only in commits, pull requests, changelogs, release
  records, migrations, archives, or accepted decision records with durable
  value. Do not create a history artifact merely to preserve a correction.
- Preserve role-owned facts unless separate evidence changes them; do not
  rewrite history or ownership merely to make a rejected term disappear.
- Leave an already-correct history, migration, provenance, ownership, or safety
  artifact unchanged when the task does not change its facts. Do not polish or
  restate it merely because it is relevant to the current edit.
- Before handoff, verify that a new agent with no editing conversation can
  derive the complete current behavior, boundaries, and operating guidance
  without mentally subtracting a rejected concept.
- Public documentation uses lowercase `docs/` paths.
- Current architecture truth lives in `docs/architecture/*`.
- Temporary execution notes, evidence, and plans live in `.agent/*`.
- Generated files stay generated. Do not hand-edit generated clients, schemas,
  metadata, or API documentation output.

## Task Route

- Before changing versions, dependencies, packaging or release workflows, read
  `docs/architecture/versioning-and-release.md` and use its existing project check entry points.

- For public behavior, update implementation, tests, docs, and generated
  contracts in the same slice.
- For documentation structure, preserve AGENTS/README separation and role
  boundaries.
- For long-running work, use `.agent/PLANS.md` as temporary execution state.

## Code Review Rules

### Compatibility and versioning

- Flag a change to public API, console scripts, or observable behavior,
  including a raised `requires-python`, without the change record and version
  bump `docs/architecture/versioning-and-release.md` requires. Safe path:
  record the change under the next version with that bump.

### Claims

- Flag README, `docs/`, or release-note statements that the code and tests do
  not support: capabilities that do not exist, existing behavior described as
  new, or Python versions CI does not test. Safe path: describe what the code
  shows.

### Public documentation

- Flag a new public module, class, or function without a docstring, and public
  prose that compares the project with other projects or describes internal
  process. Safe path: write the docstring, and describe only this project's
  own behavior.
- Flag a public API change that leaves authored API documentation or a
  generated contract stale. Safe path: update the authored page, or
  regenerate the contract with its owning command.

### Tests

- Flag a behavior change without a test that would fail before the change.
  Safe path: add the test beside the existing tests for that behavior.

## Validation

Use the smallest relevant subset while editing:

```bash
<lint-command>
<test-command>
```

Replace placeholders with repository-native commands from `pyproject.toml` or
the project docs.
