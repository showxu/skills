---
name: pyproject-docs
description: Scaffold, audit, normalize, and export Python project documentation structure from pyproject.toml-backed repositories. Use for Python documentation baselines, documentation drift audits, AGENTS/README route separation, AGENTS.md Code Review Rules, docs/architecture current truth, docs/proposals design-in-progress, docs/decisions history, docs/migrations transition records, docs/archive history, docs/reference placement, generated documentation boundaries, GitHub/community-health documentation, profile-based template output, and .agent/PLANS.md execution-state aids for large documentation migrations. Do not use for Python implementation, feature specs, product roadmaps, packaging/release automation, CI design, runtime architecture changes, or generic task orchestration.
---

# Pyproject Documentation

## Purpose

Shape Python repositories so documentation roles are explicit, repo-native, and
easy to maintain from the project facts declared by `pyproject.toml`.

This skill keeps the common repository documentation semantics and applies
them to Python facts: `pyproject.toml`, package layout, console scripts,
dependency groups, test tooling, generated contracts, and Python documentation
tooling.

## When To Use

- Scaffold a documentation-first or public-repo-complete baseline for a Python
  package, CLI, tool, service, MCP server, library, or mixed repository.
- Audit an existing Python repo against the documentation role model.
- Normalize misplaced documentation into route, index, proposal, truth, history,
  governance, generated, or reference roles.
- Export target-repository documentation from skill-local template sources.
- Emit `templates/.agent.PLANS.md.tpl` to the target repository as
  `.agent/PLANS.md` for large normalize, migration, or export work.

## When Not To Use

- Do not use for feature specification workflows.
- Do not use for product requirements, roadmap planning, or task management.
- Do not use for Python implementation, runtime architecture changes,
  dependency upgrades, packaging changes, release automation, or CI workflow
  design.
- Do not use for generic upstream adoption, donor distillation, or
  implementation planning.

## Inputs To Inspect

- Project facts: `pyproject.toml`, `uv.lock`, `requirements*.txt`,
  `setup.cfg`, `setup.py`, package manager metadata, and console script entry
  points when present.
- Root documentation: `AGENTS.md`, `README.md`, `CONTRIBUTING.md`,
  `GOVERNANCE.md`, `SECURITY.md`, `SUPPORT.md`, `LICENSE`, and `CODEOWNERS`
  when present.
- Canonical documentation tree: `docs/README.md`,
  `docs/architecture/*`, `docs/proposals/*`, `docs/decisions/*`,
  `docs/migrations/*`, `docs/archive/*`, and `docs/reference/*`.
- Non-canonical documentation trees such as `Documentation/*`, `doc/*`, or
  mixed-case role paths. Treat them as normalization input, not accepted final
  shape.
- Source and support trees that influence docs: `src/*`, top-level package
  directories, `tests/*`, `scripts/*`, `contracts/*`, `schemas/*`,
  `generated/*`, `docs/api/*`, and bundled skill or MCP directories when
  present.
- Agent temporary state: `.agent/PLANS.md` and task-scoped `.agent/*`
  artifacts. Do not treat `.codex/*` or installed skill configuration as
  temporary execution state.
- GitHub surface: `.github/*`, issue templates, pull request templates, and
  GitHub-facing policy files.
- Skill internals when editing this collection: `rules/`, `templates/`,
  `profiles/`, `examples/`, and `references/`.

## Workflow

Both existing profiles include one compact version and release policy scaffold:
`docs/architecture/versioning-and-release.md`, from
`templates/docs.architecture.versioning-and-release.md.tpl`. Populate it from actual project declarations,
build configuration, scripts and accepted rules. Include component version
authority, derived fields, dependency compatibility, candidate acceptance,
evidence reuse/invalidation, real entry points and artifact retention.

For an existing repository, find the document already owning these rules first.
Complete that document and adjust the profile target, indexes and AGENTS route
to that single entry. Do not generate a competing policy. Distinguish implemented
automation from manual procedures and missing release capability. Unknown
commands remain explicitly unestablished; the scaffold does not create them.
This is documentation work; changes to release implementation belong to the
project's release owner.

1. Start with an audit when a target repo already exists.
2. Read `pyproject.toml` before deciding docs shape. Identify package type,
   console scripts, dependency groups, build backend, test/lint tools, and
   generated artifacts.
3. Classify files by role before editing content.
4. Normalize role collisions before exporting template output.
5. Use canonical lowercase Python documentation paths under `docs/`.
6. Choose the smallest profile that fits the requested baseline:
   `minimal` for documentation-first, `standard` for public-repo-complete.
7. Compose scaffold and export outputs from explicit profile guidance, not
   ad-hoc file lists.
8. For long-running normalize, migration, or export work, create
   `.agent/PLANS.md` from `templates/.agent.PLANS.md.tpl` and keep it current.
9. When iterative feedback or a rejected implementation is part of the input,
   read `rules/canonical-artifacts.md` before editing. If `AGENTS.md` is in
   scope, also read `templates/AGENTS.md.tpl`, merge its complete canonical
   artifact contract with valid repository routes, and run
   `scripts/validate_canonical_target.py` before handoff.
10. Inventory every conflicting implementation, option, test, fixture,
    snapshot, configuration, schema, generated source, and example found
    outside documentation ownership. Report each remaining file or category;
    do not reduce the handoff to representative examples.

## Role Model

Each role from `rules/route-vs-index.md` maps to one location in a Python
repository:

- Agent Guide (agent route and edit guardrails): `AGENTS.md`
- Review Rules: the `## Code Review Rules` section of the root `AGENTS.md`,
  and of a nested `AGENTS.md` for one area
- Tool Entry Files: none by default; a `CLAUDE.md` or `REVIEW.md` only when a
  tool in use needs one, importing or derived from `AGENTS.md`
- Reader Manual: root `README.md`, the GitHub-facing landing manual
- Index: `docs/README.md`, `docs/architecture/README.md`,
  `docs/reference/README.md`, and directory `README.md` files
- Current Truth: `docs/architecture/*`
- Proposal: `docs/proposals/*`
- History: `docs/decisions/*`, `docs/migrations/*`, `docs/archive/*`
- Governance: `.github/*` and root policy files
- Reference: `docs/reference/*`
- Python API Reference: `docs/api/*` when generated or intentionally authored
- Generated Output: generated clients, schema metadata, API docs build output,
  coverage reports, and built documentation sites
- Agent Temporary State: `.agent/*`, especially `.agent/PLANS.md`

Role directories use the casing in `rules/path-casing.md`.

## Reference Files To Consult

Read only the files relevant to the selected operation:

- `rules/route-vs-index.md`: document roles and authority, including agent
  route, edit guardrails, review rules, and tool entry files.
- `rules/code-review-rules.md`: the `## Code Review Rules` section and the
  files that carry it to a specific reviewer.
- `rules/proposal-vs-truth-vs-history.md`: proposal, truth, and history
  classification.
- `rules/architecture-description-primacy.md`: current architecture
  description ownership.
- `rules/canonical-artifacts.md`: current-artifact normalization after
  iterative feedback or superseded implementation attempts.
- `rules/architecture-doc-format.md`: lightweight arc42-style architecture
  document shape.
- `rules/decision-record-format.md`: lightweight ADR/MADR-style decision
  record shape.
- `rules/proposal-doc-format.md`: lightweight proposal document shape.
- `rules/governance-vs-documentation-placement.md`: GitHub and governance
  placement.
- `rules/path-casing.md`: canonical lowercase Python documentation path casing
  for scaffold, normalize, and export work.
- `rules/readme-layering.md`: root README, directory and documentation
  indexes, and where detailed content belongs.
- `rules/python-api-docs-placement.md`: Python API docs, generated docs output,
  generated client docs, and generated artifact boundaries.
- `rules/python-project-facts.md`: how `pyproject.toml`, package layout,
  console scripts, tests, generated code, and documentation tooling affect the
  docs tree.
- `profiles/minimal.md` and `profiles/standard.md`: profile composition.
- `examples/`: small reference previews and target-tree examples.
- `references/codex-exec-plans.md`: when deciding whether a task needs a
  session-spanning `.agent/PLANS.md` execution aid.
- `scripts/validate_template_exports.py`: materialize the `minimal` and
  `standard` output maps and verify target `AGENTS.md` invariants.
- `scripts/validate_canonical_target.py`: verify an edited target `AGENTS.md`
  carries the complete contract and Code Review Rules within the 32 KiB
  budget, and flag correction-shaped prose in active documentation roles.

`route-vs-index.md`, `readme-layering.md`, and `code-review-rules.md` are
bundled copies derived from the `repository-docs` skill; edit them there and
re-derive.

External foundations:
[ISO/IEC/IEEE 42010](https://www.iso-architecture.org/ieee-1471/ads/),
[arc42](https://arc42.org/documentation/), [MADR/ADR](https://adr.github.io/madr/),
and [Diataxis](https://diataxis.fr/) inform the skill's semantics and boundary
rules. They do not directly dictate the repository tree. Agent and reviewer
file conventions follow the tools' own documentation: OpenAI's
[AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md) and
[Codex code review](https://learn.chatgpt.com/docs/third-party/github), and
Anthropic's [Claude Code memory](https://code.claude.com/docs/en/memory) and
[Claude Code Review](https://code.claude.com/docs/en/code-review).

## Decision Rules

- Keep Agent Guide and README entry roles separate. `AGENTS.md` carries
  first-principles work, task route, authority boundaries, guardrails, and
  Code Review Rules; it does not explain the tree or serve as a user manual. `README.md` explains
  public entry points, installation, quick start, expected output, and links to
  deeper docs.
- Keep root `README.md` as the GitHub-facing landing manual and entry index.
  It should cover what the project does, requirements, installation or setup,
  quick start, common commands or examples, expected output, and links to
  deeper documentation.
- Keep shipped documentation focused on current product facts, supported
  behavior, operating guidance, and accepted architecture truth. Keep temporary
  implementation notes, local evidence, local paths, run-specific artifacts,
  and historical upstream comparison notes out of shipped docs.
- Normalize accepted feedback across the complete active documentation
  surface. Rejected intermediate concepts must not survive as labels,
  qualifiers, examples, or explanatory prose unless their exclusion is a
  current compatibility, safety, or ownership invariant.
- Normalize by semantic identity and role, not by matching text. A rejected
  current capability does not invalidate a distinct released-format history,
  migration, ownership fact, or safety boundary that uses the same term.
  Preserve those artifacts unless separate evidence changes their facts. If
  they are already correct and the task does not change their facts, leave
  their contents unchanged rather than polishing or restating them.
- Keep Code Review Rules to judgments a reviewer must make about this
  project, each with its reason and safe path. A deterministic check, such as
  formatting, lint, type checking, or forbidden paths, belongs in the
  project's check commands or CI, not in the review rules.
- When canonicalizing an existing `AGENTS.md`, replace correction-shaped
  feature guidance with the self-contained canonical-artifact contract carried
  by `templates/AGENTS.md.tpl`; do not treat a feature bullet such as
  `A without B` as already current.
- Inspect implementation, tests, configuration, schemas, generated sources,
  and examples for contract drift that would make normalized documentation
  false. Report that drift as a blocking handoff to its implementation owner;
  do not mutate Python implementation artifacts unless the user separately
  requests that work and the applicable implementation owner is active.
- Treat a disabled option such as `yaml = false`, skipped test, dead branch,
  retained fixture, or feature-specific prohibition as drift when it exists
  only because the rejected capability was attempted. Disabled state alone is
  not a reason to preserve or document it as a current invariant.
- Keep current truth in `docs/architecture/*`, not in decision logs,
  migration notes, archives, proposals, `.agent/*`, or README files.
- Keep design-in-progress in `docs/proposals/*`. Proposal space is neither
  current truth nor historical record.
- Keep historical context in `docs/decisions/*`, `docs/migrations/*`, and
  `docs/archive/*`, not in current architecture files.
- Keep reference material in `docs/reference/*`.
- Keep generated Python API documentation under `docs/api/*` only when the
  repository intentionally publishes generated or authored API reference there.
  Generated API output must be clearly marked as generated or reproducible.
- Keep GitHub-facing policy and templates in `.github/*`.
- Keep CODEOWNERS at `.github/CODEOWNERS` in generated defaults.
- Keep agent temporary execution artifacts in `.agent/*`. The standard active
  plan surface is `.agent/PLANS.md`. Do not place agent plans at repository
  root, in `docs/*`, or in `.github/*`.
- Preserve canonical Python documentation path casing. Use lowercase role
  directories such as `docs/architecture`, `docs/proposals`,
  `docs/decisions`, `docs/migrations`, `docs/archive`, `docs/reference`, and
  `docs/api`.
- Treat `Documentation/*`, `documentation/*`, `Doc/*`, and mixed-case role
  paths as non-canonical input. Normalize them to `docs/*`; do not preserve
  them as a long-term exception.
- Keep generated files generated once generators exist. Do not hand-edit
  generated clients, generated schemas, generated API docs, generated MCP
  metadata, or generated capability metadata.
- Treat exported output as downstream only. It must trace back to this skill
  and the normalized repo structure.
- Author template source files from the target repository's perspective, not
  from this skill collection's perspective.
- Do not expose collection-internal production terminology in generated target
  templates.
- Treat `minimal` as the documentation-first baseline: the smallest stable repo
  shape that makes Agent Guide, Index, Truth, and Governance explicit.
- Treat `standard` as the first public-repo-complete baseline: it extends
  beyond `minimal` with fuller proposal, history, reference, and
  GitHub/community-health coverage.
- Keep the `minimal` / `standard` distinction intentional unless product
  strategy changes deliberately.
- Favor crisp README navigation over long essays, but do not collapse the root
  README into a pure documentation-tree directory. Summarize common public
  usage in the root README and link to deeper reference or API documentation
  for exhaustive option tables, architecture details, failure catalogs, or API
  docs.
- Allow target trees to vary by profile. Minimal and standard trees are both
  valid when the role boundaries stay intact.

## Validation Rules

- The selected profile matches the emitted or changed file set.
- `pyproject.toml` facts align with README usage, package names, console
  scripts, dependency groups, test commands, and generated-output boundaries.
- Agent guides do not become indexes, and README-class files do not become
  routing contracts.
- Root `README.md` stays outward-facing, keeps public manual essentials for
  the repository's primary audience, and does not restate detailed
  architecture rules that belong under `docs/architecture/*`.
- Shipped documentation states current product facts and usage without
  temporary implementation notes, run-specific artifacts, or historical
  comparison notes.
- Current docs stand alone without the editing conversation and contain no
  residual names, examples, or correction narratives for rejected intermediate
  concepts.
- Current docs have the same meaning as a direct accepted design and do not use
  `only`, `without`, `removed`, `rejected`, `legacy`, `deprecated`, or
  `no longer supported` merely to narrate the editing path.
- Existing history, migration, ownership, and safety artifacts remain
  unchanged unless task-specific evidence independently changes their facts.
- An unchanged role-owned artifact has no content diff; mentioning it in the
  handoff does not justify editing it.
- Generated schemas, help, API output, and metadata are regenerated by their
  owner or reported as blocking drift; they are not hand-edited.
- Canonical documentation paths and Markdown filenames use lowercase Python
  docs conventions unless they are conventional root or GitHub files such as
  `README.md`, `AGENTS.md`, `LICENSE`, or `CODEOWNERS`.
- Non-canonical `Documentation/*` or mixed-case docs paths are either migrated
  or explicitly recorded as unfinished normalization work in `.agent/PLANS.md`;
  they are not considered a compliant final state.
- Ordinary Python repositories do not emit `.github/README.md` by default, and
  GitHub's surfaced repository README resolves to root `README.md`.
- Python projects with intentionally published API documentation use
  `docs/api/*` or a clearly documented equivalent; generated output is marked
  generated and reproducible.
- `docs/architecture/*` states current truth explicitly after proposal or
  decision changes.
- Proposal, decision, migration, archive, and reference materials do not
  redefine current truth on their own.
- Target-facing templates and exported files do not mention skill-local
  `rules/`, `examples/`, profile mechanics, or source/export internals.
- `python3 scripts/validate_template_exports.py` materializes both profiles and
  verifies that each exported `AGENTS.md` carries the complete path-independent
  canonical-artifact contract and a Code Review Rules section with `###`
  groups.
- After canonicalizing an existing repository, run
  `python3 scripts/validate_canonical_target.py <repository>`. Use
  `--allow-path` only for a reviewed active file whose negative wording is
  independently required by a current compatibility, safety, or ownership
  invariant, and state that rationale in the handoff.
- `.agent/PLANS.md`, when emitted, is treated as temporary execution state
  only. It is not architecture truth, a proposal, a decision record, a
  migration record, reference material, GitHub governance, or `.codex` skill
  material.

## Output Format

For audits or normalize/export slices, return:

1. Phase / stage judgment
2. Inputs inspected
3. Files changed
4. What changed
5. Findings or drift assessment
6. Validation performed
7. Risks / constraints
8. Recommended next steps
9. Code diff or key hunks, if files changed

## Failure / Uncertainty Handling

- Stop and ask when the requested work crosses into product planning,
  implementation workflow, release automation, or non-documentation
  architecture.
- If file ownership is ambiguous, classify by role before editing.
- If current-capability feedback appears to contradict a historical or
  ownership artifact, do not infer that the artifact is false. Preserve it and
  report the semantic distinction or request implementation-owner resolution.
- If an existing root `PLAN.md` or `PLANS.md` appears, treat it as legacy or
  ambiguous execution state; preserve active content before normalizing the
  active plan surface to `.agent/PLANS.md`.
- If the current truth only appears in supporting artifacts, update or request
  an explicit `docs/architecture/*` source of truth.
- If a profile does not cover a requested output, call that out rather than
  silently expanding the profile.
