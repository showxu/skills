# Eval Fixtures

These fixtures protect `pyproject-docs` routing, role boundaries, path casing,
generated-output behavior, and canonical current artifacts. They are durable
behavior inputs, not run logs.

## new-python-cli-baseline

Target behavior: scaffold a Python CLI documentation baseline from repository
truth.

Input prompt: "This Python CLI has `pyproject.toml`, a console script, a README,
and tests but no formal docs tree. Add a compact documentation baseline."

Context and files:

- `pyproject.toml`, the console-script entry point, `README.md`, and `tests/`.

Expected output:

- Reads `pyproject.toml` before writing docs.
- Selects the minimal or standard profile from the requested scope.
- Uses lowercase `docs/`, keeps `AGENTS.md` as the agent route, and keeps
  `README.md` as the public manual.
- Documents install, quick start, real command examples, expected output, and
  validation commands that match project tooling.

Forbidden behavior:

- Creates `Documentation/Architecture`.
- Invents a console script or package name.
- Puts temporary execution notes in shipped docs.

Acceptance checks:

- All documented commands and names can be traced to inspected project files.
- Exported paths match the selected profile exactly.

Baseline expectation:

- The old skill may infer names from the directory or introduce non-canonical
  path casing.

Evidence sources:

- Final documentation tree and diff.
- Inspected `pyproject.toml` values.

Owner notes:

- Documentation-owned output only.

## existing-documentation-tree-normalization

Target behavior: normalize a non-canonical documentation tree without turning
temporary execution state into formal truth.

Input prompt: "Normalize this Python repository's documentation structure. It
currently has uppercase `Documentation/` directories and `.agent/PLANS.md`."

Context and files:

- `Documentation/Architecture`, `Documentation/Reference`, and
  `.agent/PLANS.md`.

Expected output:

- Migrates durable documentation to lowercase `docs/architecture` and
  `docs/reference`.
- Preserves active `.agent/PLANS.md` as temporary execution state.
- Records filesystem case-transition risk when relevant.

Forbidden behavior:

- Keeps `Documentation/` as an unexplained permanent exception.
- Promotes `.agent/` content without a role decision.

Acceptance checks:

- Durable documentation uses canonical paths and temporary state remains
  temporary.

Baseline expectation:

- The old skill may preserve existing path casing or merge execution state into
  formal docs.

Evidence sources:

- Final tree and migration diff.

Owner notes:

- None.

## proposal-current-truth-boundary

Target behavior: keep proposals distinct from accepted current architecture.

Input prompt: "Are these docs current? The OpenAPI runtime proposal disagrees
with the architecture guide."

Context and files:

- `docs/proposals/openapi-runtime.md` describes a target state.
- `docs/architecture/README.md` describes the running state.

Expected output:

- Reports the drift and preserves the proposal role.
- Updates architecture truth only when the target state is accepted and
  implemented.

Forbidden behavior:

- Treats proposal text as current truth by default.
- Deletes decision context merely to make documents agree.

Acceptance checks:

- Proposal and current-truth roles remain explicit and internally consistent.

Baseline expectation:

- The old skill may collapse both roles into a single document.

Evidence sources:

- Role-labelled final docs and drift report.

Owner notes:

- None.

## generated-contract-documentation

Target behavior: document generated contracts without hand-editing generated
artifacts.

Input prompt: "Document the architecture of this Python project, including its
generated OpenAPI client and MCP metadata."

Context and files:

- Generated OpenAPI clients, schema metadata, MCP metadata, and their generator
  configuration.

Expected output:

- Labels generated artifacts and documents their regeneration command and
  manual-edit boundary.
- Places current architecture in `docs/architecture/` and durable details in
  `docs/reference/`.

Forbidden behavior:

- Hand-edits generated outputs.
- Moves non-user-facing generator internals into the public README.

Acceptance checks:

- A maintainer can identify the source of truth and reproduce generated docs.

Baseline expectation:

- The old skill may blur generated and hand-maintained ownership.

Evidence sources:

- Documentation diff and regeneration instructions.

Owner notes:

- Generated implementation remains owned by its generator workflow.

## non-documentation-request

Target behavior: decline primary ownership of implementation-only changes.

Input prompt: "Implement a provider and change runtime signing behavior."

Context and files:

- A Python project with existing documentation.

Expected output:

- Routes implementation to the applicable owner and records only a scoped
  documentation follow-up when needed.

Forbidden behavior:

- Reframes implementation as a documentation-normalization task.

Acceptance checks:

- No implementation file is changed under `pyproject-docs` ownership alone.

Baseline expectation:

- The old skill may proceed without an explicit ownership boundary.

Evidence sources:

- Executor response and changed-file list.

Owner notes:

- None.

## canonical-artifact-path-independence

Target behavior: normalize the documentation-owned surface to the accepted
project contract while detecting, but not silently taking ownership of,
cross-surface implementation drift.

Input prompt: "A draft Python CLI gained JSON and YAML export while we were
exploring the feature. The YAML export branch was never accepted; the CLI
contract is JSON export. The released 0.9 storage migration and the external
reader ownership record remain valid. Make the repository documentation and
agent guide current."

Context and files:

- `README.md`, API/reference docs, examples, diagrams, comments quoted in docs,
  and generated documentation inputs mention JSON and YAML, `JSON-only`, or
  `YAML was removed after review`.
- `AGENTS.md` has an `AWithoutB`-shaped instruction and no self-contained
  canonical artifact contract.
- Implementation residue includes `YAMLExporter`, a `--yaml` option,
  `yaml.enabled = false`, schema/generated CLI metadata, a skipped YAML test,
  and YAML fixtures or snapshots.
- A historical migration record covers a previously released YAML schema, and
  a current ownership boundary independently forbids editing an external YAML
  parser.

Expected output:

- Re-derives JSON export as the accepted contract and expresses it directly in
  documentation and the generated target `AGENTS.md`.
- Removes correction-shaped YAML wording, names, examples, diagrams, API prose,
  and other documentation-owned residue with no current contract value.
- Reports implementation, test, option, configuration, schema, and generated
  source drift as a blocking handoff to the implementation owner; it does not
  claim the repository is fully current while that drift remains.
- Preserves the historical migration record and independently current
  ownership boundary in their explicit roles.
- Produces the same active documentation meaning that a direct JSON design path
  would have produced, without inventing a history artifact for the correction.

Forbidden behavior:

- Mutates Python implementation, tests, CLI options, configuration, schemas, or
  generated source under `pyproject-docs` ownership alone.
- Renames the capability to `JSONOnlyExporter`, `ExporterWithoutYAML`, or adds a
  permanent "YAML is unsupported" section solely because the draft changed.
- Leaves current YAML residue and compensates with `removed`, `deprecated`,
  `legacy`, or `no longer supported` narration.
- Deletes a durable migration or still-current ownership constraint.
- Creates a new ADR, migration note, archive, or provenance record merely to
  preserve the correction sequence.

Acceptance checks:

- A reader with no conversation can understand the complete current CLI
  contract without mentally subtracting YAML.
- Active documentation contains no rejected YAML surface unless an independent
  current compatibility, safety, or ownership invariant requires it.
- Cross-surface residue outside documentation ownership is enumerated and
  routed to its owner rather than silently edited or ignored.
- The handoff includes every discovered implementation, option, configuration,
  test, fixture, schema, and generated-source blocker, not only representative
  examples.
- Historical artifact content remains unchanged and role-labelled.
- The unchanged migration and ownership records have no content diff; an agent
  may cite them in the handoff but may not restate them in place.
- `python3 scripts/validate_template_exports.py` passes for both `minimal` and
  `standard` profile exports.

Baseline expectation:

- The old skill may patch prose incrementally, retain `JSON-only` or removal
  narration, miss generated target-guide semantics, or overreach into Python
  implementation and tests.

Evidence sources:

- Final documentation and generated target `AGENTS.md` diff.
- Cross-surface drift or handoff report.
- Historical artifact hashes before and after the run.
- Template export smoke-test output.

Owner notes:

- `pyproject-docs` owns documentation structure, content, and its target-guide
  template. Python implementation, tests, CLI options, configuration, schemas,
  and generated source require their applicable implementation owner.

## project-review-rules

Target behavior: give a Python project's agent guide review rules a reviewer
can apply, written against the project's own documentation paths.

Input prompt: "Our pull requests are reviewed automatically. Normalize the
agent guide for this project."

Context and files:

- `AGENTS.md` has the canonical contract but no `## Code Review Rules`.
- `docs/architecture/versioning-and-release.md` defines the version bump and
  the change record; `pyproject.toml` declares console scripts and
  `requires-python`.
- The project's check command already runs a formatter, a linter, and a type
  checker.

Expected output:

- `AGENTS.md` gains `## Code Review Rules` with `###` groups for compatibility
  and versioning, claims, public documentation, and tests, each naming the
  behavior, the reason, and the safe path.
- The versioning rule routes to `versioning-and-release.md` instead of
  copying its bump rules.
- Formatting, lint, and type errors are left to the check command.
- No `CLAUDE.md` or `REVIEW.md` is created.

Forbidden behavior:

- Review rules that restate the check command, copy the versioning policy, or
  name functions likely to move.

Acceptance checks:

- `scripts/validate_canonical_target.py` passes, including the review-rule
  section and size budget.

Evidence sources:

- Target `AGENTS.md` diff and validator output.

Owner notes:

- The review-rule shape comes from the bundled `rules/code-review-rules.md`.

## Version and Release Scaffold Cases

Run both minimal and standard profile export checks. Review filled output against
these facts; a template containing placeholders is not evidence of implemented
release automation.

| Input | Expected output |
| --- | --- |
| Python static project.version | Preserve the actual single version authority; do not add an App build number or another declaration. |
| Python project.dynamic version from a VCS-aware backend | Name the backend and VCS authority, wheel/sdist and runtime derivation; do not invent project.version. |
| Existing release policy at another repository path | Complete it, adjust the profile target and all routes, and retain one normative entry. |
| New project with no release scripts | Explicitly state that automation is not established; no invented commands or claims of candidate validation. |
| New toolchain or changed check definitions | Previous evidence is invalid for the affected stage and its dependents; retain failure records. |
| Unchanged source and exact accepted package | Reuse only trusted matching evidence; preserve the accepted bytes during publication. |
