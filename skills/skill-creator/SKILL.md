---
name: skill-creator
description: Create or update production-ready Codex skills, including new skill scaffolding, SKILL.md authoring, agents/openai.yaml metadata, hardening, evaluation, benchmarking, trigger testing, packaging, plugin distribution, and review. Use for skill creation, revision, selected multi-skill review, batch skill review, Anthropic-style create/test/review/improve loops, with-skill versus baseline evals, eval viewer, feedback iteration, blind comparison, description optimization, fixture normalization, HITL gates, host compatibility, Claude Code and Codex plugin manifests, and single-skill validation. Do not use for broad source intake, skill taxonomy or placement decisions, upstream polling, independent local eval workflows, or installing and managing plugins on a machine.
---

# Skill Creator

## Purpose

Use this skill as the self-contained production entrypoint for creating,
updating, evaluating, packaging, and reviewing one or more selected skills.
Package and readiness validation still run per skill package.

This skill preserves two source baselines before applying local production behavior:
Anthropic's `skills/skill-creator` source owns the skill co-development loop,
evaluation/review/benchmark semantics, feedback iteration, description
optimization, and packaging semantics. OpenAI's Codex `skill-creator` source
owns Codex-native skill anatomy, trigger contract guidance, progressive
disclosure conventions, `agents/openai.yaml`, and creation scaffolding.

The local production layer composes those baselines and adds host compatibility,
durable fixture normalization, HITL gates, package preflight, plugin
distribution, and production quality rules. It must not delete source capabilities during a merge, invent a
separate skill-eval workflow, local JSON template layer, or multi-baseline
benchmark topology.

Keep source receipts raw. Do not rewrite Anthropic or OpenAI source copies to
share terminology, tone, structure, or local policy. Fusion happens only in
this entrypoint, governance references, manifest rows, and local overlay files.

For eval, review, benchmark, and description-optimization flow, local
differences from Anthropic are allowed only when the Anthropic toolchain cannot
run in Codex. Convenience automation, alternate workspace layouts, alternate
viewer behavior, and local benchmark semantics are not valid eval-flow patches.

## Baseline

Before creating, revising, evaluating, or packaging a skill:

1. Read `references/source-role-map.md` to identify which source baseline owns
   the current concern.
2. Use `references/source-openai-skill-creator.md` and
   `references/source-openai-yaml.md` for Codex-native skill structure,
   scaffolding, and UI metadata fidelity.
3. For Anthropic-style co-development, evals, review, benchmark, feedback
   iteration, description optimization, and packaging semantics, use the flow
   in this file and check `references/source-anthropic-skill-creator.md` when
   source fidelity is in doubt.
4. Read `references/source-patch-manifest.md` before editing a source-derived
   or source-composed file. The manifest is the allowlist for local
   differences and conflict resolutions.
5. Use `references/schemas.md` for Anthropic JSON artifact shapes. Do not
   create local JSON skeleton directories for source artifacts.
6. Use local overlay references only after source baselines are preserved:
   fixture catalog quality, HITL gates, host compatibility, architecture
   policy, workflow topology, Codex package validation, and plugin
   distribution.

If a local overlay conflicts with a source baseline, keep the source-owned
semantics and narrow the overlay to host substitution, fixture quality,
evidence quality, validation, or explicit local policy.

## Tracked Git Source Baselines

This skill records its source baselines inside the skill itself. These are
tracked git source baselines, not generic upstream intake. Each source baseline
has a repository, source skill path, commit, local receipt path, and a declared
role in this skill.

- Anthropic source repo: `anthropics/skills`
  Source skill path: `skills/skill-creator/`
  Tracked commit: `d211d437443a7b2496a3dad9575e7dddd724c585`
  Local receipt: `references/source-anthropic-skill-creator.md`
  Role: skill co-development loop, eval/review/benchmark, feedback iteration,
  description optimization, and package-loop semantics.

- OpenAI source repo: `openai/skills`
  Source skill path: `skills/.system/skill-creator/`
  Tracked commit: `af9b54f235d0d56c6b4410be54d578b0fda4ddfc`
  Local receipt: `references/source-openai-skill-creator.md`
  Role: Codex skill anatomy, trigger contract, progressive disclosure,
  `agents/openai.yaml`, initialization scaffolding, and metadata generation.

Use `references/source-baseline-map.md` for file-level mapping and
`references/baseline-maintenance.md` for refresh and deletion guards.

## Document Hierarchy

Use these files in this order:

1. `SKILL.md`: the only active workflow entrypoint. It contains the full eval
   flow to execute.
2. `references/source-role-map.md`: source ownership map for Anthropic,
   OpenAI, and local production responsibilities.
3. `references/source-anthropic-skill-creator.md`: Anthropic source baseline
   receipt. Use it to verify fidelity; do not execute it separately when
   `SKILL.md` already carries the aligned flow.
4. `references/source-openai-skill-creator.md` and
   `references/source-openai-yaml.md`: OpenAI/Codex source baseline receipts
   for skill anatomy, scaffolding, and UI metadata.
5. `references/anthropic-eval-loop.md`: Codex toolchain adapter. Use only for
   host mechanics, trigger-runner substitutions, and non-claims.
6. `references/eval-and-review-standard.md`: local quality overlay for
   fixtures, evidence, and review artifacts. It is not a workflow entrypoint.
7. `references/source-patch-manifest.md`,
   `references/baseline-maintenance.md`, and
   `references/architecture.md`: maintenance governance for
   editing this skill, not run instructions.

## Ownership

Maintain this skill in separate ownership lanes so source alignment work does
not delete Anthropic, OpenAI, or local production capabilities by mistake.

Anthropic source files are byte-for-byte source content and should stay that
way: `agents/analyzer.md`, `agents/comparator.md`, `agents/grader.md`,
`assets/eval_review.html`, `eval-viewer/viewer.html`,
`eval-viewer/generate_review.py`, `references/schemas.md`,
`scripts/__init__.py`, `scripts/aggregate_benchmark.py`,
`scripts/generate_report.py`, `scripts/quick_validate.py`,
`scripts/utils.py`, and `references/source-anthropic-skill-creator.md`.

Anthropic patched files start from source and may only carry manifest-listed
adapter patches: `SKILL.md`, `scripts/improve_description.py`,
`scripts/package_skill.py`, `scripts/run_eval.py`, and `scripts/run_loop.py`.
These files are source-derived plus adaptation. They must not add a local eval
workflow, a local artifact template layer, or a default third benchmark
configuration.

OpenAI source files are byte-for-byte source content unless explicitly listed
as a conflict resolution: `references/source-openai-skill-creator.md`,
`references/source-openai-yaml.md`,
`references/source-openai-agent-openai.yaml`,
`references/source-openai-quick-validate.py`,
`references/source-openai-license.txt`,
`assets/source-openai-skill-creator-small.svg`,
`assets/source-openai-skill-creator.png`,
`scripts/init_skill.py`, and `scripts/generate_openai_yaml.py`.
The OpenAI `scripts/quick_validate.py` source is kept as
`references/source-openai-quick-validate.py` because the runtime
`scripts/quick_validate.py` slot is already occupied by the Anthropic package
validator required by `scripts/package_skill.py`.

Codex-only files are local host adapters or metadata:
`scripts/validate_skill_package.py` and `agents/openai.yaml`. They may validate
packages or expose the skill in OpenAI surfaces, but they do not define the
Anthropic eval stages or replace OpenAI source conventions.

Local self-developed overlays are local production files:
`references/eval-and-review-standard.md`, `references/eval-fixtures.md`,
`references/hitl-design.md`, `references/host-compatibility.md`,
`references/parallel-workflow-design.md`,
`references/plugin-distribution.md`,
`references/single-skill-validation.md`, and
`references/skill-design-principles.md`. They may add fixture normalization,
HITL policy, host compatibility guidance, runtime workflow topology, package
preflight, plugin distribution checks, first-principles authoring checks, and
production quality rules.
They must remain subordinate to the Anthropic stage order.

Governance documents record the boundary:
`references/source-patch-manifest.md`,
`references/source-baseline-map.md`,
`references/source-role-map.md`,
`references/baseline-maintenance.md`,
`references/anthropic-eval-loop.md`, and
`references/architecture.md`. Any new local-only behavior
must be recorded in the patch manifest and architecture map before it is used.

## Local Quality Rules

Start from a real task, failed behavior, repeated workflow, existing skill, or
approved source handoff. Do not invent a production skill from abstract nouns
alone.

Before creating, revising, reviewing, or adding reusable skill behavior, use
the first-principles work check in `references/skill-design-principles.md` as
the initial quality gate. Derive the invariant from the owned artifact, source
baseline, and observed failure before copying a local patch shape,
fixture-specific solution, sibling skill pattern, or host-specific workflow
into reusable instructions.

The frontmatter `description` is the trigger contract. It must state positive
use cases, output ownership, supported inputs, and negative boundaries. Do not
rely on the body to fix a vague description.

Apply the boundary ownership gate from
`references/skill-design-principles.md` when creating, revising, or reviewing a
skill. Use the trigger contract as the activation and output surface, then
identify the artifact, operation, and state the skill owns. Write negative
boundaries as "this skill does not own or produce that" before naming any next
owner. Do not fix a boundary by hardcoding sibling skill names, downstream
workflow commands, or external schema fields unless the target skill owns
routing as an artifact, the user/source packet names them, or the text is an
explicit compatibility stub.

Before writing concrete values into reusable skill materials, apply the
abstraction-boundary check in `references/skill-design-principles.md` as the
concrete value and context-leakage gate. Do not promote local environment
facts, current input details, fixture or run details, or temporary execution
state into reusable skill contracts.

Before drafting or revising a complex skill, run the topology decision from
`references/skill-design-principles.md`. Complex signals include multi-stage
workflows, schema or runtime specs, templates plus examples plus scripts,
runtime artifacts, mixed LLM semantic and deterministic script stages, or
semantic fidelity/evaluation requirements. Classify the target as a leaf skill,
staged workflow, fan-out/fan-in workflow, or orchestrator before writing the
skill. If the decision would upgrade the design to fan-out/fan-in,
orchestrator, subagent-backed phases, or clean-context review stages, use the
topology escalation HITL gate from `references/hitl-design.md` before encoding
that architecture. Leaf skills and staged serial workflows do not require HITL
by topology alone.

Keep `SKILL.md` as the entrypoint. Move long or conditional material to
`references/`, deterministic work to `scripts/`, and reusable output resources
to `assets/`. Do not split content for ceremony.

Use scripts for mechanical checks, schema validation, payload shaping, command
normalization, or repeated fragile work. A script should have a clear input,
output, and failure mode.

Design Human-in-the-Loop gates for missing facts, permissions, irreversible
operations, live accounts, subjective tradeoffs, review feedback, and subagent
consent. The gate must name the question, why it matters, acceptable options,
safe default, allowed work before the answer, and blocked work until the
answer. For structured host tools such as Claude-side `AskUserQuestion` or
Codex structured input when available, treat the tool call as a host-specific
mapping of the same gate, not as portable skill semantics. Use
`references/hitl-design.md`.

When a host supports permission frontmatter such as `allowed-tools`, narrow tool
access to the least privilege that still lets the skill complete its expected
workflow. If the target host does not support that frontmatter, keep the same
boundary in the skill body or host metadata instead of inventing unsupported
fields. Use `references/skill-design-principles.md`.

When adapting Claude or Anthropic skills into Codex, use
`references/host-compatibility.md`. Preserve source capability, but do not
claim native Codex trigger behavior, Claude Code subagent isolation, or
external host support unless it was actually tested.

When designing a target skill that includes subagents, parallel agents, fan-out
work, or runtime workflow topology, use
`references/parallel-workflow-design.md`. For tightly coupled coding work, same
module edits, or any request for multiple agents to edit the same files at the
same time, reject concurrent same-file writes as the execution pattern. Prefer
one implementer context, or restrict parallel work to read-only investigation,
verification, or disjoint write ownership.

Selected multi-skill review is in scope when each target is an explicit skill
review, hardening, or eval candidate. Treat it as repeated skill review, not as
skill taxonomy or placement. For complex or batch review, use clean-context
subagent passes by default unless the task is clearly narrow. Define shared
input, target scope, subtask boundary, output shape, and fan-in merge contract
before dispatch. Default those passes to read-only review, verification, or
semantic evaluation; writes belong to a follow-up edit pass for the owning skill
or explicitly named non-skill owner. Each finding should name the owning skill,
local overlay, source baseline, or external owner.

Before presenting or packaging each skill as ready, run the single-skill
validator documented in `references/single-skill-validation.md`.

## Complete Anthropic Eval Flow

This is the main eval workflow. Keep it aligned with the Anthropic source
baseline.
Codex-specific mechanics are substitutions inside the same stages, not new
stages.

### 1. Locate The User In The Loop

Identify whether the user is asking for:

- a new skill
- an existing draft that needs hardening
- a failed skill behavior
- mocked evals or a benchmark
- human review and feedback iteration
- blind comparison
- description trigger optimization
- packaging or presentation

Start at the relevant point, but preserve downstream eval artifacts.

### 2. Capture Intent And Research Gaps

Extract what the skill should do, when it should trigger, what it outputs, what
tools or files it needs, what sibling skills should win adjacent cases, and
what success or failure looks like.

Ask only for facts that change workflow or evaluation. If independent research
or fixture drafting would materially improve confidence, ask before using
subagents unless the user already requested subagents, parallel agents,
independent agents, or the full Anthropic-style eval flow.

### 3. Draft Or Revise The Skill

Write or revise:

- `name`
- `description`
- `SKILL.md`
- `references/`
- `scripts/`
- `assets/`
- optional host metadata such as `agents/openai.yaml`

For a new skill, use `scripts/init_skill.py` when a fresh Codex skill scaffold
is useful. Generate or refresh `agents/openai.yaml` with
`scripts/generate_openai_yaml.py` after reading `references/source-openai-yaml.md`.

Preserve source-specific guardrails. Do not compress the skill into a generic
API lookup guide.

### 4. Create Eval Prompts

Create 2-3 realistic prompts for a first pass, or 5-10 prompts for complex or
production-critical skills. Cover happy path, near miss, sibling overlap,
missing input, risky action, failure recovery, and expected artifact shape when
relevant.

Save runnable cases to `evals/evals.json`. If a target skill has durable cases
in `references/eval-fixtures.md`, convert selected cases into `evals/evals.json`
for this run. The fixture catalog is a local input normalization layer; it does
not replace `evals/evals.json`.

Do not write assertions yet unless they already exist. Anthropic's flow drafts
or refines assertions while runs are in progress.

### 5. Create The Workspace

Use the Anthropic workspace shape:

```text
<skill-name>-workspace/
├── iteration-1/
│   ├── evals/evals.json
│   ├── eval-<id-or-name>/
│   │   ├── eval_metadata.json
│   │   ├── with_skill/
│   │   │   └── run-1/
│   │   │       ├── outputs/
│   │   │       ├── transcript.md          # Codex capture; viewer prompt source
│   │   │       ├── timing.json
│   │   │       └── grading.json
│   │   └── without_skill/           # new-skill baseline
│   │       └── run-1/
│   │           ├── outputs/
│   │           ├── transcript.md          # Codex capture; viewer prompt source
│   │           ├── timing.json
│   │           └── grading.json
│   ├── review.html
│   ├── feedback.json
│   ├── benchmark.json
│   └── benchmark.md
```

For existing-skill improvement, snapshot or copy the old skill and use
`old_skill/` instead of `without_skill/`.

In Codex, use the same workspace and artifact shape. Apply host-specific
substitutions from `references/anthropic-eval-loop.md`.

### 6. Run The Selected Configurations

Full benchmark evals require executor isolation. Anthropic gets this from
subagents. In Codex, use the equivalent executor rules in
`references/anthropic-eval-loop.md`.

Run exactly one default comparison pair:

- new skill: `with_skill` versus `without_skill`
- existing skill improvement: `with_skill` versus `old_skill`

Do not run `old_skill` and `without_skill` in the same benchmark unless the
user explicitly asks for extra exploratory analysis.

Skill exposure must match the configuration:

- `with_skill`: give the executor the current skill path and tell it to read
  that skill before doing the task.
- `without_skill`: give no target skill path and tell the executor not to read
  or use the target skill, its source directory, or host skill-registry entry.
- `old_skill`: give only the old snapshot path and tell the executor not to
  read or use the current skill.

For Codex prompt wording, workspace visibility, and contamination-risk handling,
follow `references/anthropic-eval-loop.md`.

Each executor prompt must be realistic and must not leak expected answers,
diagnosis, intended fixes, hidden grading criteria, original checkout absolute
paths, or host-local skill registry paths. Save final responses and
requested artifacts under the selected run's `outputs/` directory.

For Codex executor response capture, transcript placement, and viewer prompt
discovery, follow `references/anthropic-eval-loop.md`.

### 7. Draft Assertions While Runs Execute

Do not wait idly. Draft objective assertions for each eval, explain what they
check, and update `eval_metadata.json` and `evals/evals.json`. Good assertions
distinguish correct output from plausible wrong output. Leave subjective
quality for the review artifact.

### 8. Capture Timing

When each run completes, write `timing.json`. Use available fields such as
tokens, duration, start/end timestamps, or `null` plus notes when Codex does not
expose the same completion metadata as Claude Code.

### 9. Grade Runs

Grade every run after outputs are available. Use `agents/grader.md`, inspect
the real outputs, transcript/logs, command output, and generated files, then
write `grading.json`.

The `expectations` array must use the exact fields `text`, `passed`, and
`evidence`. Passing evidence must point to actual run artifacts. Do not accept
scaffolded outputs, synthetic baselines, self-grading, unchanged boilerplate, or
claims based only on the skill body.

For Codex wrapper-response detection and rerun rules, apply
`references/eval-and-review-standard.md`.

### 10. Aggregate Benchmark

Run:

```bash
python3 <skill-creator>/scripts/aggregate_benchmark.py \
  <workspace>/iteration-1 \
  --skill-name <skill-name> \
  --skill-path <path-to-skill>
```

The benchmark uses the Anthropic source aggregation script. Do not adapt the
script for local workspace variants; write artifacts in the source shape.

### 11. Analyze Benchmark Patterns

Use `agents/analyzer.md` for a formal analyzer pass when needed. Identify
assertions that do not discriminate, flaky or high-variance evals, cases where
the skill improves quality but costs more time/tokens, cases where baseline
wins, and repeated executor work that should become a script or resource.

### 12. Generate The Review Artifact

Generate the human review surface:

```bash
python3 <skill-creator>/eval-viewer/generate_review.py \
  <workspace>/iteration-1 \
  --skill-name <skill-name> \
  --benchmark <workspace>/iteration-1/benchmark.json \
  --static <workspace>/iteration-1/review.html
```

For iteration 2 and later, add:

```bash
--previous-workspace <workspace>/iteration-<N-1>
```

Use the live server mode only when a browser flow is intentionally available.
When static mode is used, the feedback button downloads `feedback.json`; copy
that into the workspace before the next iteration.

### 13. Present Results And Read Feedback

Tell the user the review artifact is ready and what it contains: qualitative
outputs, formal grades, benchmark summary, and feedback fields. When the user
finishes, read `feedback.json`. Empty feedback means acceptable for that run;
specific complaints drive skill changes. User feedback wins for subjective
quality.

### 14. Improve The Skill

Revise from benchmark evidence and human feedback. Generalize from failures
instead of overfitting to eval prompts, keep instructions lean, preserve
source-specific guardrails, and replace repeated mechanical work with scripts
when useful.

For boundary-related eval failures, write the repair at the artifact-contract
level before editing prompts or wording. Identify what the skill incorrectly
owned, what it must stop doing, what evidence it may preserve, and whether
routing is core or only advisory. Update fixtures to check that abstract
boundary rather than requiring a hardcoded sibling name, downstream command, or
external schema field.

### 15. Repeat Iterations

Rerun all relevant evals in `iteration-<N+1>/`, include the same comparison
pair, aggregate benchmark, regenerate the review artifact with previous
iteration context, read feedback, and repeat until quality is accepted or the
remaining risk is explicitly deferred.

### 16. Blind Comparison

When the user asks whether one version is actually better, hide which output
came from which skill/version, compare with `agents/comparator.md`, save
`comparison.json`, then use `agents/analyzer.md` to understand why the winner
won and save `analysis.json` when doing a formal pass.

### 17. Description Optimization

Only optimize the description after behavior is stable.

1. Generate should-trigger and should-not-trigger query sets.
2. Review queries with the user using `assets/eval_review.html`.
3. Run the adapted trigger loop with `scripts/run_loop.py --runner codex` in
   Codex, or `--runner claude` only when Claude CLI is intentionally selected.
   Do not replace the optimization loop with a static trigger table, hand-scored
   examples, or direct `scripts/run_eval.py` unless the user explicitly asks for
   a diagnostic single pass.
4. In Codex, the trigger runner first uses `codex debug prompt-input` as eval
   setup evidence that the candidate skill is visible in the rendered prompt.
   This is not runtime skill consultation evidence and does not replace proxy
   trigger scoring.
5. Treat proxy trigger scores as proxy evidence unless native host trigger
   selection was actually observed.
6. If the Codex runner is blocked by sandbox, session, state-db, or process
   limits, stop and report the blocker instead of inventing substitute scores.
   Hand-scored examples may be labeled as preflight reasoning, but they are not
   trigger eval results and must not be presented as benchmark evidence.
7. Apply the best description only when it preserves sibling boundaries and
   source-specific guardrails.

### 18. Package Or Present

Before packaging, installing, syncing, or presenting a skill as ready, run:

```bash
python3 <skill-creator>/scripts/validate_skill_package.py \
  <skill-dir> \
  --package-mode
```

Then package when requested:

```bash
python3 <skill-creator>/scripts/package_skill.py \
  <skill-dir> \
  <output-directory>
```

`package_skill.py` prefers the Anthropic source `quick_validate.py`; the local
validator is only a dependency fallback for environments without PyYAML.

When the skills should also install as Claude Code or Codex plugins, validate
each skill first, then use `references/plugin-distribution.md` for manifests,
version labels, install docs, and isolated install checks.

## Local Resources

- `references/source-role-map.md`: source ownership map for Anthropic, OpenAI,
  and local production responsibilities.
- `references/source-anthropic-skill-creator.md`: exact Anthropic source flow
  copy.
- `references/source-openai-skill-creator.md`: exact OpenAI/Codex source
  authoring guide copy.
- `references/source-openai-yaml.md`: exact OpenAI/Codex UI metadata reference.
- `references/source-patch-manifest.md`: allowlist of local differences and
  source conflict resolutions.
- `references/anthropic-eval-loop.md`: Codex host mechanics, trigger-runner
  substitutions, and non-claims for the Anthropic source eval flow.
- `references/eval-and-review-standard.md`: local fixture and run-artifact
  quality standard. It feeds `evals/evals.json`; it is not another eval flow.
- `references/eval-fixtures.md`: self-fixtures for this skill.
- `references/hitl-design.md`: local HITL gate design.
- `references/host-compatibility.md`: local Claude/Anthropic-to-Codex
  compatibility rules.
- `references/parallel-workflow-design.md`: local runtime workflow topology,
  fan-out/fan-in, and sub-skill decomposition guidance.
- `references/plugin-distribution.md`: local Claude Code and Codex plugin
  manifest, version, and isolated install rules.
- `references/single-skill-validation.md`: local package/preflight checklist.
- `references/baseline-maintenance.md`: source and eval baseline maintenance
  rules.
- `references/architecture.md`: maintenance policy for this
  adapter.
- `references/skill-design-principles.md`: local production skill quality
  overlay.
- `references/schemas.md`: Anthropic source JSON artifact schemas.

Any new local-only behavior must be recorded in the patch manifest before it is
used.

## Output

For implementation requests, make the scoped changes, run the relevant
validator or eval command, and report changed paths plus validation status.

For review-only requests, lead with concrete mismatches from source baselines,
then list the smallest patch needed to remove or justify each mismatch.
