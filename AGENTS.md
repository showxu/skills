# Skills Agent Guide

Read root `README.md` first for repository purpose and entry points, then
`docs/README.md` for the documentation index. Apply
this guide before changing repository docs, manifests, scripts, skills, or
automation.

## First-Principles Work

Before changing code, docs, schemas, scripts, templates, examples, governance,
or automation, reduce the task to observable behavior, root cause, invariant,
owner, data flow, and validation.

- Do not silently choose among plausible interpretations. State assumptions,
  surface conflicts, and ask when the decision materially changes the result.
- Deliver the complete requested behavior with bounded design. Do not stop at a
  toy result when production behavior is requested, and do not add abstraction,
  configurability, workflow machinery, or future-facing features unless the
  request, source evidence, or owning invariant requires them.
- Change the owning layer, not the nearest convenient file.
- Keep changes traceable to the request, source evidence, or owning invariant.
- Do not clean up, reformat, rename, or refactor unrelated nearby material
  unless it is required by the request or owning invariant.
- Use the strongest feasible validation for the result. If validation is
  skipped, say what was skipped and why.

Use this check:

1. What behavior is wrong, missing, or at risk?
2. What root cause explains it?
3. What invariant must hold?
4. Which artifact, layer, or workflow owns it?
5. What data or decision flows into that owner?
6. What remains variable, configurable, or case-local?
7. What evidence proves the result beyond one literal case?

## Canonical Artifact Rule

Treat discussion and review as inputs to an edit, not as content to preserve
inside the edited artifact. Recompute the accepted result before finalizing.

- Active skill artifacts depend only on the current contract and their owned
  role, not on the editing path. Apply this to trigger metadata, instructions,
  names, branches, configuration, schemas, scripts, templates, comments,
  tests, fixtures, examples, assets, and normative docs.
- When accepted scope changes from `A + B` to `A`, remove `B` and its residual
  names, branches, examples, fixtures, and explanations. Do not rename the
  result to `A without B` or add a narrative about the rejected path.
- Normalize by semantic identity and artifact role, not by token. A rejected
  current capability does not invalidate a distinct historical fact,
  migration, provenance record, ownership boundary, or safety rule that uses
  the same term.
- Keep historical reasoning only in artifacts that own provenance or history
  and still have durable value,
  such as source receipts, patch manifests, commits, changelogs, migrations,
  archives, and decision records whose rationale still governs current work.
- Do not create a provenance or history artifact merely to preserve a
  correction.
- Preserve role-owned facts unless separate evidence changes them; do not
  rewrite history or ownership merely to make a rejected term disappear.
- Leave an already-correct history, migration, provenance, ownership, or safety
  artifact unchanged when the task does not change its facts. Do not polish or
  restate it merely because it is relevant to the current edit.
- Negative rules are justified only when they express a current boundary,
  compatibility contract, safety invariant, ownership invariant, or realistic
  regression shield.
- A disabled flag, skipped test, dead branch, retained fixture, or prohibition
  created by the rejected attempt is residue, not an invariant. Remove it or
  route it to its owner; do not promote its disabled state into policy.
- Comments add non-obvious current semantics; they do not restate the artifact
  or narrate its editing history.
- Before handoff, verify that a reader without the authoring conversation can
  use the current skill without mentally subtracting a rejected concept.

## Task Route

- Use `docs/README.md` as the root docs index.
- Use `docs/repository-layout.md` and `docs/repo-architecture/` for repository
  shape, placement, linked-checkout policy, migration, validation, and root
  ownership questions.
- Use `docs/collection-taxonomy.md` before adding, moving, grouping, or
  registering skills.
- Use `docs/skill-authoring.md` for repository-wide trigger and manual-entry
  rules. Use `skills/skill-creator/` for single-skill anatomy, production
  quality gates, fixtures, HITL, eval flow, packaging, and one-skill readiness.
- When changing a specific `skills/<name>/`, first read that skill's
  `SKILL.md`, then read `skills/<name>/references/architecture.md` if it
  exists, plus directly relevant skill-local references linked from the
  entrypoint or owning artifact.
- Put skill-specific docs, examples, templates, assets, runtime helpers, and
  workflow policy inside the owning `skills/<name>/` directory.
- Use root `scripts/` only for monorepo infrastructure such as source manifest
  helpers.
  Keep workflow entry points owned by one skill inside that skill.

## Authority

- Root `.claude-plugin/marketplace.json` owns local plugin groups. Groups are
  discovery and install views, not ownership boundaries.
- `upstreams.yaml` owns upstream/source tracking metadata.
- `docs/repo-architecture/` owns current repository-shape and placement
  policy. Historical migration records under `docs/provenance/` are not active
  routing authority.
- A skill directory owns its `SKILL.md`, `agents/openai.yaml`, `references/`,
  `templates/`, `assets/`, `examples/`, and skill-local `scripts/`.
- Do not duplicate inventories in prose when root manifests or marketplace
  metadata already carry the skill surface.

## Boundary Guardrails

After the owner and invariant are clear, classify concrete values by stability,
variability, and ownership before writing reusable artifacts.

Do not promote context-bound values into reusable artifacts. A value is
context-bound if it depends on the current machine, local workspace, current
input, one fixture, one runtime run, one user-specific path, or temporary
execution state.

Use this decision test:

- If a value changes by input, get it from input, spec, config, parameters, or
  an explicit user decision.
- If a value changes by environment, get it from configuration, runtime state,
  environment variables, or local execution notes.
- If a value belongs only to one example, fixture, or run, keep it there. Do
  not generalize it into reusable docs, schemas, templates, scripts,
  validation rules, or automation.
- If the artifact being edited is not the source of truth for the value, do not
  hardcode it there. Pass it in, derive it, configure it, or link to the
  owning artifact.
- Only stable invariants and values owned by the current artifact may be fixed
  in reusable artifacts.

Classify concrete values before writing:

1. Name the variable parts.
2. Decide which artifact owns each variable.
3. Replace context-bound literals with placeholders, parameters, config keys,
   derived values, or links to the owning artifact.
4. Keep concrete literals only inside the artifact that owns them.

## Operating Notes

- Do not add local child collections or grouping folders under root `skills/`.
  Add local skills directly under `skills/<name>/`.
- Do not add root wrapper scripts for skill-local helpers just for convenience.
  Document or run the skill-local command instead.
- For linked external skill families, use source manifests or the referenced
  source checkout before metadata or write-capable follow-ups.
- Keep `AGENTS.md` as a compact agent guide. Put durable manuals,
  architecture details, lifecycle overlays, and provenance in focused docs.
- Run the relevant root checks before finishing repository-level changes:
  `python3 -B scripts/check_repository.py` and `git diff --check`.

## Code Review Rules

### Skill behavior

- Flag a trigger or workflow change that loses a source-backed decision,
  permission boundary, or failure path. Preserve the behavior in its owning
  skill and update a representative fixture; structural validation alone
  cannot prove semantic equivalence.
- Flag examples or defaults that promote one machine, organization, or task
  into reusable policy. Keep those values configurable or in the example
  that owns them.

### Publication and provenance

- Flag changes that expose private research downloads or remove still-valid
  third-party notices. Publish the authored guidance and permitted resources;
  keep source-specific attribution and redistribution terms with their owner.
- Flag readiness claims based only on package validation. Report the actual
  execution or review evidence, and distinguish static checks from host
  installation and behavioral evaluation.
