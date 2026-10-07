# Skill Design Principles

Use this reference for local production-quality skill design. These principles
are an overlay on skill authoring quality. They must not override Anthropic's
eval stage order.

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

Use this decision test:

1. Name the behavior that is wrong, missing, or at risk.
2. Name the root cause, not just the symptom.
3. Name the invariant that must hold after the change.
4. Name the artifact, layer, or workflow that owns that invariant.
5. Name the data or decision flow into that owner, including producer,
   transformer, consumer, and validator when applicable.
6. Name what remains variable, configurable, or case-local.
7. Change the owning layer only. If the current artifact is not the owner,
   route, derive, configure, or link to the owner instead of copying the rule
   here.
8. Validate the invariant across representative cases, not one literal
   example.

A reusable change is valid only if it preserves the invariant without moving
responsibility to the wrong layer. Do not encode a solution because it appeared
in a nearby skill, a successful one-off run, a convenient script, or a current
review discussion. First state the invariant and ownership boundary, then
choose the least specific reusable instruction, script, fixture, or gate that
enforces it.

## Trigger Contract

After the invariant and owner are clear, write the trigger contract around the
artifact this skill owns.

The frontmatter `description` is the primary trigger surface. It should state:

- when to use the skill
- what the skill produces or changes
- supported inputs
- important constraints
- explicit negative boundaries
- sibling skills or tools that should win adjacent cases

## Boundary Ownership

Before tightening a skill boundary, identify the artifact class the skill owns.
Good boundaries say what this skill may produce or mutate, where it stops, and
what evidence it may preserve. They do not use a sibling skill name as a
substitute for the current skill's own contract.

Use this distinction:

- Leaf skill: owns a domain artifact such as an audit, ledger, checklist,
  implementation pattern, report, or validation output. It may name a needed
  owner by responsibility, but should not hardcode downstream skill names or
  execute a downstream workflow.
- Route stub: exists because users may arrive through an old or adjacent entry.
  It may name a concrete next entrypoint when the skill taxonomy or migration
  history requires it, but it should remain short and non-executing.
- Orchestrator skill: owns routing artifacts such as digests, intake plans,
  handoff queues, bundle classifications, owner decisions, or migration plans.
  It may know concrete downstream owners because routing is its product.

When an eval failure exposes a boundary bug, abstract the failure before
patching:

1. Name the behavior that failed.
2. Name the artifact, operation, or state the skill incorrectly owned.
3. Rewrite the boundary in terms of this skill's own artifact contract.
4. Add only advisory handoff language unless routing is part of the owned
   artifact.
5. Update fixtures so they test the abstract boundary, not a hardcoded sibling
   name, downstream command, or external schema field.

## Abstraction Boundary / Context Leakage

After owner and invariant are clear, check whether each concrete value belongs
in reusable skill material.

Before writing concrete values into reusable skill docs, schemas, scripts,
templates, examples, or eval rubrics, identify which values are stable, which
are variable, and which artifact owns them.

Do not promote context-bound values into reusable skill contracts. A value is
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

When in doubt, use a placeholder, parameter, configuration key, or owned source
of truth instead of a literal value.

## Canonical Output / Conversation-State Leakage

Treat the authoring conversation as a sequence of edits to a target contract.
Before writing or revising reusable skill material, derive the complete
currently accepted contract and express that contract directly.

Path independence is the invariant: two authoring histories that end with the
same accepted contract and artifact roles must produce semantically equivalent
active skill surfaces.

Canonicalization is semantic, not lexical. Removing a current capability does
not authorize erasing a distinct provenance fact, migration, ownership
boundary, safety rule, or regression invariant merely because it uses the same
term. Preserve role-owned facts unless separate evidence changes them.
When an existing role-owned artifact is already correct and the task does not
change its facts, leave its contents unchanged. Semantic relevance to the edit
is not a reason to polish or restate it.

A disabled option, skipped test, dead branch, retained fixture, or prohibition
created by the rejected attempt remains part of that edit path. Disabled state
alone does not turn it into a reusable compatibility, safety, or ownership
invariant.

If an intermediate request produced `A + B` and later feedback rejects `B`,
the final skill should describe `A`. It should not describe `A without B`, add
a general prohibition against `B`, or retain an explanation of why `B` was
removed unless the absence of `B` is itself a current safety, compatibility,
or ownership invariant.

Apply this normalization across the whole owned skill surface:

- trigger description and manual-entry metadata
- workflow steps and decision rules
- references, examples, templates, and assets
- scripts, schemas, fixtures, and validation language
- names for artifacts, fields, methods, and configuration

Remove residual branches and vocabulary for rejected concepts. Do not preserve
authoring chronology in current guidance. Source receipts, patch manifests,
changelogs, migrations, archives, and accepted decision records may retain
history when that is their explicit role.

Comments and explanatory prose should add current semantic information: domain
meaning, invariants, units, ownership, lifecycle, side effects, failure
behavior, concurrency, or a still-operative design rationale. They should not
restate names or explain the sequence of user corrections.

Before handoff, evaluate the skill as if the reader had never seen its creation
or review conversation. The skill passes only when the reader can execute the
current workflow without reconstructing earlier states.

## Progressive Disclosure

Keep `SKILL.md` as the entrypoint. Move long, conditional, or source-heavy
material to `references/`. Move deterministic fragile steps to `scripts/`.
Keep reusable output resources in `assets/`.

Do not split content just to create folders. Split only when it reduces context
load or makes repeated work safer.

## Workflow Topology

For complex skills, classify the workflow topology before drafting: serial,
staged serial, fan-out/fan-in, or orchestrator plus sub-skills. Use runtime
parallelism only when subtasks are independent enough to run with clean
contexts and a clear merge contract.

Run the topology decision when the skill has multi-stage workflows, schema or
runtime specs, templates plus examples plus scripts, runtime artifacts, mixed
LLM semantic and deterministic script stages, or semantic fidelity/evaluation
requirements. Identify:

1. The artifact, operation, or state the skill owns.
2. Whether the skill is a leaf skill, staged workflow, fan-out/fan-in workflow,
   or orchestrator.
3. Which stages require LLM or agent semantic judgment.
4. Which stages are deterministic script or validation steps.
5. Which artifacts are stable skill source, examples, templates, runtime
   workspace output, or eval output.
6. Which validation belongs to deterministic checks versus LLM semantic
   evaluation.
7. What the skill explicitly does not own.

If the topology decision upgrades the skill from leaf or staged serial into
fan-out/fan-in, orchestrator, subagent-backed phases, or clean-context review,
use the topology escalation gate in `references/hitl-design.md` before encoding
that architecture. Do not ask for HITL just because a staged serial workflow is
complex.

Use `references/parallel-workflow-design.md` for parallel candidates,
non-candidates, fan-out/fan-in contracts, staged parallelism, and sub-skill
decomposition. This is production skill design guidance, not a change to the
Anthropic eval stage order.

## Scripts

Use scripts for repeatable or fragile work:

- frontmatter or package validation
- artifact schema checks
- command output normalization
- payload shaping
- source inventory
- format conversion

The skill should say when to run the script and what failure means.

## Tool Permission Boundary

When the target host supports permission frontmatter such as `allowed-tools`,
use it to narrow the skill to the least privilege that can complete the
expected workflow. This is especially useful for read-only audit skills,
single-purpose script runners, packaging/validation skills, and skills that
must avoid live account mutation.

Good permission boundaries are concrete:

- allow only read/search tools for review-only skills
- allow only specific command prefixes for deterministic scripts
- require HITL before writes, installs, publishing, live API mutations, or
  destructive operations
- avoid broad tool access when the skill only needs files, schemas, or one
  script

Do not add unsupported frontmatter just because another host uses it. If the
target host does not support `allowed-tools`, preserve the same boundary in the
skill body, host metadata, or HITL gate instead. Do not over-narrow permissions
so far that the skill cannot complete its documented workflow.

## Evidence

Production readiness should be supported by at least one of:

- real task evidence
- durable fixture coverage
- Anthropic-style eval run artifacts
- human review feedback
- deterministic validation commands

Do not claim broad readiness from one narrow run.
