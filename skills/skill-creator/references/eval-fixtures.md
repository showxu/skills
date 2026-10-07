# Eval Fixtures

Fixture catalog for `skill-creator`. These fixtures are durable inputs for
checking this adapter's own behavior. They feed Anthropic-style `evals/evals.json`
runs; they are not an alternate eval format.

Do not store benchmark rows, review conclusions, temp paths, transcripts, or
dated execution artifacts here.

## anthropic-eval-flow-alignment

Target behavior: eval requests use Anthropic's complete create/test/review/
improve loop rather than a local summary workflow.

Input prompt: "Run mocked evals for this skill, generate the review page, and
iterate after I return feedback."

Context and files:

- Current `skill-creator` skill source.
- `references/source-anthropic-skill-creator.md`.
- `references/schemas.md`.

Expected output:

- Uses `references/source-anthropic-skill-creator.md` or the full flow in
  `SKILL.md` as the source workflow.
- Creates or uses `evals/evals.json`.
- Runs `with_skill` and exactly one baseline configuration.
- Grades real outputs into `grading.json`.
- Aggregates `benchmark.json` / `benchmark.md`.
- Generates `review.html`.
- Waits for or reads `feedback.json` before treating subjective feedback as
  accepted.

Forbidden behavior:

- Invents a separate local eval flow.
- Treats "mocked evals" as permission to emit only `mock_eval_results.json` or
  review prose without the source artifact shape.
- Runs three default configurations.
- Uses local JSON skeleton templates.
- Claims native host trigger proof from a Codex proxy run.

Acceptance checks:

- Output names `SKILL.md` or `references/source-anthropic-skill-creator.md`
  as the source workflow for the eval loop.
- Output creates or uses `evals/evals.json` as the execution artifact.
- Output does not satisfy mocked evals with only `mock_eval_results.json` or a
  review-like response.
- Output runs `with_skill` and exactly one baseline configuration.
- Output grades actual outputs into `grading.json`.
- Output aggregates `benchmark.json` or `benchmark.md`.
- Output generates `review.html` and waits for or reads `feedback.json` before
  treating subjective feedback as accepted.
- Output does not introduce local JSON skeleton templates or claim native host
  trigger proof from a Codex proxy run.

Baseline expectation:

- A no-skill baseline is likely to summarize a generic test loop and miss one
  or more Anthropic-specific artifacts or sequencing requirements.

Evidence sources:

- Executor response.
- Generated workspace files when present.
- `grading.json`.

Owner notes:

- This fixture guards against local eval-flow invention.

## fixture-normalization-boundary

Target behavior: local durable fixtures are preserved as reusable inputs but
converted into source run artifacts for execution.

Input prompt: "Use this skill's fixture catalog to run a benchmark."

Context and files:

- `references/eval-fixtures.md`.
- `references/eval-and-review-standard.md`.
- `references/schemas.md`.

Expected output:

- Reads `references/eval-fixtures.md` only as durable input.
- Materializes selected cases into `evals/evals.json`.
- Keeps `review.html`, `benchmark.json`, `feedback.json`, transcripts, and raw
  outputs outside the target skill source.

Forbidden behavior:

- Treats fixture markdown as the execution format.
- Writes dated run artifacts into the skill's `references/` directory.

Acceptance checks:

- Output treats `references/eval-fixtures.md` as a durable input catalog only.
- Output materializes selected fixture cases into `evals/evals.json`.
- Output keeps `review.html`, `benchmark.json`, `feedback.json`, transcripts,
  and raw outputs outside the target skill source.
- Output does not treat fixture markdown as the runtime execution format.
- Output does not write dated run artifacts into the skill's `references/`
  directory.

Baseline expectation:

- A no-skill baseline may treat the markdown catalog as the execution format or
  place run artifacts in the source tree.

Evidence sources:

- Executor response.
- Workspace tree.
- Target skill tree.

Owner notes:

- This fixture protects the boundary between durable fixtures and run outputs.

## codex-response-capture-contract

Target behavior: Codex eval runs keep host-captured final responses, generated
artifacts, transcripts, and viewer prompt metadata in distinct files.

Input prompt: "Run an Anthropic-shaped eval with Codex executors and make sure
the review page shows the real task output, not a wrapper message."

Context and files:

- `references/anthropic-eval-loop.md`.
- `references/eval-and-review-standard.md`.
- `eval-viewer/generate_review.py`.

Expected output:

- Treats `outputs/response.md` as the host-captured final assistant message
  when using `codex exec --output-last-message`.
- Does not ask the executor to write or edit `outputs/response.md` itself.
- Uses separate named files under `outputs/` for task-generated artifacts.
- Writes `run-*/transcript.md` or `run-*/outputs/transcript.md` with top-level
  `## Eval Prompt`.
- Reruns or marks incomplete when `outputs/response.md` is only a wrapper such
  as "completed" or "saved to path" and no real referenced artifact exists.

Forbidden behavior:

- Prompts the executor to save the final answer to `outputs/response.md` while
  the harness also captures `--output-last-message` to that path.
- Grades a wrapper message as the actual eval output.
- Relies on `outputs/response.md` or `prompt.txt` for viewer prompt discovery.
- Patches the source viewer to support a local prompt shape.

Acceptance checks:

- Output states that the harness or host captures `outputs/response.md`.
- Output writes generated task files under names other than `response.md`.
- Output requires `transcript.md` with `## Eval Prompt` for Codex runs.
- Output treats wrapper-only `response.md` content as incomplete unless a real
  referenced artifact exists and is graded directly.
- Output preserves source viewer behavior instead of patching it.

Baseline expectation:

- A no-skill baseline may ask the executor to write `response.md`, then grade a
  wrapper completion message or produce `(No prompt found)` in the viewer.

Evidence sources:

- Executor prompt.
- `outputs/response.md`.
- `transcript.md`.
- Generated `review.html`.
- `grading.json`.

Owner notes:

- This fixture guards a Codex adapter boundary discovered during
  `skill-creator` self-eval.

## candidate-visibility-preflight

Target behavior: identify the temporary candidate in the host-rendered skill
catalog even when Codex shortens descriptions and uses skill-root aliases.

Input prompt: "Check that the trigger-loop setup discovers its actual candidate,
including when an installed skill has the same name."

Context and files:

- `scripts/run_eval.py`.
- `scripts/test_prompt_input.py`.
- Actual `codex debug prompt-input` output for a temporary candidate.

Expected output and acceptance checks:

- The registry entry resolves to the exact candidate SKILL.md for both aliased
  and absolute host path forms; shortened description text is not a failure.
- A same-name installed copy, unknown alias, neighboring file, or user-provided
  path/catalog text does not establish discovery of the temporary candidate.
- The real preflight runs before the unchanged description optimization loop.
- Missing or unverifiable discovery fails setup; it is not a false-trigger
  score. Successful discovery remains setup evidence, not native consultation.

Evidence sources: deterministic regression results and actual rendered host
input. These checks do not replace behavioral evals, trigger scoring, or human
review.

## codex-host-adaptation

Target behavior: Claude Code command points are replaced with Codex equivalents
without changing the Anthropic flow.

Input prompt: "Optimize this skill description and show me trigger eval
results."

Context and files:

- `scripts/run_eval.py`.
- `scripts/run_loop.py`.
- `scripts/improve_description.py`.
- `assets/eval_review.html`.

Expected output:

- Uses `scripts/run_loop.py --runner codex` by default.
- Keeps `--runner claude` available when Claude CLI is intentionally selected.
- Does not replace the optimization loop with direct `scripts/run_eval.py`.
  `run_eval.py` is only a leaf evaluator or diagnostic single-pass check.
- Labels Codex trigger scores as proxy evidence unless native host trigger
  selection was actually observed.
- Reports Codex runner/toolchain blockers instead of scoring them as ordinary
  false-trigger results.

Forbidden behavior:

- Claims `codex exec` proves native auto-trigger loading.
- Falls back from `--runner codex` to `--runner claude` because of a local
  Codex sandbox/session blocker without the user intentionally selecting
  Claude.
- Treats Codex runner/toolchain failure as evidence that the description should
  not trigger.
- Removes the source trigger review step.

Acceptance checks:

- Output uses `scripts/run_loop.py --runner codex` by default in Codex.
- Output keeps `--runner claude` available for intentional Claude CLI runs.
- Output does not replace description optimization with direct
  `scripts/run_eval.py`.
- Output labels Codex trigger scores as proxy evidence unless native host
  trigger selection was observed.
- Output reports Codex runner blockers instead of silently switching to Claude.
- Output does not score Codex runner blockers as false-trigger evidence.
- Output preserves the source trigger review step using
  `assets/eval_review.html`.
- Output does not claim `codex exec` proves native auto-trigger loading.

Baseline expectation:

- A no-skill baseline may either assume Claude CLI is available or overclaim
  Codex trigger evidence.

Evidence sources:

- Executor response.
- Generated trigger eval artifacts when present.
- Script command lines.

Owner notes:

- This fixture is limited to toolchain substitution; it must not justify local
  trigger semantics.

## executor-isolation-and-baseline-cleanliness

Target behavior: full benchmark evals preserve Anthropic subagent-style context
isolation and configuration-specific skill exposure when translated to Codex.

Input prompt: "Run the full benchmark for this skill using Codex subagents, and
make sure the baseline is clean."

Context and files:

- `SKILL.md`.
- `references/anthropic-eval-loop.md`.
- `references/eval-and-review-standard.md`.

Expected output:

- Uses isolated executor contexts for `with_skill` and baseline runs.
- Creates one executor or subagent per eval run.
- Does not fork or inherit the authoring conversation into executor contexts.
- Uses top-level per-run `codex exec` as the isolation primitive when the
  executor is already non-interactive `codex exec`; it does not require nested
  subagents in that host shape.
- Gives `with_skill` the current skill path and tells it to read that skill.
- Gives `without_skill` no target skill path and tells it not to read or use
  the target skill, source directory, or host skill-registry entry.
- Gives `old_skill` only the old snapshot path when evaluating an existing
  skill improvement.
- Records residual contamination risk if host auto-triggering could load the
  target skill during a baseline run.
- Writes prompt-bearing `transcript.md` for each Codex run so the source
  viewer can display the real prompt.

Forbidden behavior:

- Runs benchmark tasks inline in the current authoring conversation and counts
  them as benchmark evidence.
- Passes assertions, grading criteria, design discussion, feedback, intended
  fixes, or diagnosis into executor prompts.
- Gives the target skill path to a `without_skill` baseline.
- Requires a non-interactive `codex exec` executor to spawn nested Codex
  subagents as the only full-benchmark path.
- Claims benchmark completion or clean baseline when child runs are missing
  `outputs/response.md`, prompt-bearing `transcript.md`, `timing.json`, or
  `grading.json`.
- Claims a clean baseline when host auto-trigger contamination risk is present
  but not ruled out.

Acceptance checks:

- Output requires isolated executor contexts and one executor or subagent per
  eval run.
- Output states that Codex subagents must not fork or inherit the authoring
  conversation.
- Output uses top-level per-run `codex exec` when nested subagents are not
  available inside a non-interactive executor.
- Output gives `with_skill` the current skill path and tells it to read that
  skill.
- Output gives `without_skill` no target skill path and tells it not to read or
  use the target skill, source directory, or host skill-registry entry.
- Output gives `old_skill` only the old snapshot path and tells it not to read
  or use the current skill.
- Output does not pass assertions, grading criteria, design discussion,
  feedback, intended fixes, or diagnosis into executor prompts.
- Output records residual contamination risk if host auto-triggering could load
  the target skill during a baseline run.
- Output marks child runs incomplete when required run artifacts are missing.
- Output writes run-local `transcript.md` with `## Eval Prompt`, or otherwise
  puts prompt metadata where the source viewer reads it.

Baseline expectation:

- A no-skill baseline may run inline or fail to separate skill exposure by
  configuration.

Evidence sources:

- Executor response.
- Subagent or executor prompts when present.
- Run metadata and `grading.json`.

Owner notes:

- This fixture was added after reviewing contamination risk in Codex evals.

## runtime-parallel-workflow-positive

Target behavior: production skill design distinguishes target-skill runtime
parallelism from Anthropic eval executor isolation and recommends fan-out/fan-in
only for independent analysis work.

Input prompt: "Create a production skill for exploratory analysis of CSV and
Excel datasets. It should profile the data, discover anomalies, compare
relationships, find interesting facts, and write a Markdown report."

Context and files:

- `references/skill-design-principles.md`.
- `references/parallel-workflow-design.md`.
- `references/host-compatibility.md`.

Expected output:

- Classifies the runtime workflow as staged parallel or fan-out/fan-in.
- Keeps data loading, schema inspection, and quality checks serial before
  parallel work begins.
- Defines independent analysis slices such as univariate profile, bivariate
  relationships, anomaly detection, and interesting-finding discovery.
- Defines fan-out inputs and fan-in output shape for the final report.
- Notes that host-specific subagent frontmatter or tools must be checked before
  claiming the parallel path works in a target host.

Forbidden behavior:

- Treats the Anthropic eval executor isolation rules as the runtime design for
  the target skill.
- Adds `allowed-tools: Agent Task` as a universal requirement.
- Spawns broad parallel work before shared inputs are loaded or normalized.
- Produces unrelated subtask fragments without a merge contract.

Acceptance checks:

- Output names staged parallelism or fan-out/fan-in as the target skill runtime
  topology.
- Output has at least one serial prepare phase, one parallel exploration phase,
  and one serial synthesis phase.
- Output includes explicit fan-out input and fan-in output contracts.
- Output keeps host-specific subagent mechanics conditional on compatibility.
- Output does not cite `anthropic-eval-loop.md` as runtime parallel workflow
  guidance.

Baseline expectation:

- A no-skill baseline may either make the whole EDA process serial or add
  generic subagent language without staged preparation and merge rules.

Evidence sources:

- Drafted skill or review response.
- Referenced local design documents.

Owner notes:

- This fixture protects the new local production design overlay.

## runtime-parallel-workflow-negative-coding

Target behavior: production skill design rejects runtime parallel writes for
high-coupling coding work while allowing bounded read-only exploration or
verification.

Input prompt: "Create a skill that fixes bugs in a single web app module by
editing the component, CSS, and state management together. It should be fast, so
have multiple agents work on the files in parallel."

Context and files:

- `references/skill-design-principles.md`.
- `references/parallel-workflow-design.md`.
- `references/host-compatibility.md`.

Expected output:

- Classifies the implementation workflow as serial or staged serial for write
  work because the files share one behavior surface.
- Allows parallelism only for read-only investigation, independent test triage,
  or verification with disjoint scope.
- Requires one implementation owner for the coupled code change.
- Defines validation after the serial implementation rather than merging
  unrelated code fragments.

Forbidden behavior:

- Encourages multiple agents to edit the same component, CSS, and state logic in
  parallel.
- Treats speed as sufficient justification for runtime parallel writes.
- Uses `allowed-tools: Agent Task` or host subagents to bypass coordination
  risks.
- Confuses target-skill runtime parallelism with eval benchmark executors.

Acceptance checks:

- Output explicitly declines parallel writes across the coupled files.
- Output preserves a serial implementation path for the shared behavior
  surface.
- Output permits only read-only or verification-side parallelism.
- Output does not use Anthropic eval isolation rules as runtime coding
  architecture.

Baseline expectation:

- A no-skill baseline may over-apply parallel-agent advice and split tightly
  coupled files across agents.

Evidence sources:

- Drafted skill or review response.
- Referenced local design documents.

Owner notes:

- This fixture guards against blindly applying parallel workflow advice to
  coding tasks.

## canonical-output-normalization

Target behavior: skill revisions collapse accepted feedback into one canonical
current contract instead of preserving the sequence of corrections in active
skill material.

Input prompt: "Add JSON and YAML export to this skill. Actually YAML is not
part of the feature; make the final skill support JSON export only. Update the
instructions, examples, fixtures, and metadata."

Context and files:

- A target skill whose current draft contains JSON and YAML workflow branches,
  examples, fixtures, and trigger wording.
- `references/skill-design-principles.md`.

Expected output:

- Re-derives the accepted contract as JSON export.
- Produces semantically equivalent active skill artifacts whether the authoring
  path was direct JSON or JSON plus a later-rejected YAML branch.
- Removes YAML trigger wording, workflow branches, names, examples, fixtures,
  and metadata from the current skill surface.
- Describes JSON export directly without labels such as "JSON-only" or
  commentary about the rejected YAML path.
- Retains a YAML exclusion only if the supplied target contract contains a
  current compatibility, safety, or ownership reason for that exclusion.
- Preserves a distinct role-owned migration, provenance, or ownership fact
  that mentions YAML unless separate evidence invalidates that fact.
- Keeps change narration in the review summary or version-control history, not
  in current skill instructions.
- Ensures any target-facing templates generated by the skill carry the same
  path-independent contract without relying on collection-level instructions.

Forbidden behavior:

- Renames the capability to "export without YAML" or adds a permanent
  "never support YAML" rule solely because of the correction.
- Leaves dead YAML examples, fixture cases, schema fields, comments, or
  configuration behind.
- Adds prose such as "previously supported YAML" to `SKILL.md` or target-facing
  reference material without a history-owning artifact.
- Deletes source receipts or patch-manifest history whose explicit role is
  provenance.
- Rewrites a true migration or ownership record merely because it shares the
  rejected capability's vocabulary.
- Creates a new ADR, migration note, or source receipt merely to preserve the
  fact that YAML was considered and rejected.

Acceptance checks:

- A reader who sees only the final target skill infers the JSON export contract
  without needing the authoring conversation or mentally subtracting YAML.
- Current skill materials contain no rejected YAML surface unless a current
  invariant independently requires it.
- A clean export of target-facing templates remains self-contained and conveys
  the same canonical-artifact rule outside the source collection.
- Role-owned provenance remains intact.

Baseline expectation:

- A no-skill baseline may patch the draft incrementally, leaving "JSON-only",
  "without YAML", removal commentary, or stale YAML fixtures behind.

Evidence sources:

- Final target skill tree.
- Executor response and diff.
- Validation and fixture results.

Owner notes:

- This fixture protects canonical output normalization without erasing
  legitimate provenance artifacts.

## plugin-distribution-collection

Target behavior: publishing a skill collection as plugins produces host
manifests that match observed install behavior and proves the result with
isolated installs.

Input prompt: "This repository has a `skills/` folder of finished skills and a
Claude marketplace that groups them. Make the whole collection installable in
Codex as well, and keep Claude working."

Context and files:

- A repository with a `skills/` folder, a grouped
  `.claude-plugin/marketplace.json`, and a README install section.
- `references/plugin-distribution.md`.
- `references/single-skill-validation.md`.

Expected output:

- Adds `.agents/plugins/marketplace.json` and one `.codex-plugin/plugin.json`
  rooted at the repository with `"skills": "./skills/"`.
- Uses the same release version as the Claude marketplace, and leaves Claude
  entry versions unpinned unless every release bumps them.
- Adds a Codex install section next to the existing install routes, with the
  "plugin or direct install, not both" note.
- Verifies with `claude plugin validate` and installs into temporary
  `CLAUDE_CONFIG_DIR` and `CODEX_HOME` homes, then compares cached skill
  folders with the published ones.
- Confirms the real host configuration is unchanged after cleanup.

Forbidden behavior:

- Mirrors the Claude groups as several Codex plugins built from symlinked skill
  folders.
- Installs the plugin into the real host configuration as the test.
- Pins Claude entry versions without a bump rule.
- Claims Git-marketplace refresh behavior or host support that was not
  exercised.

Acceptance checks:

- Every published skill folder appears in each host's isolated cache with its
  `SKILL.md`.
- Manifest versions agree across hosts.
- Real host configuration checksums match before and after the check.

Baseline expectation:

- A no-skill baseline may create one Codex plugin per Claude group with
  symlinks, skip isolated installs, or test against the real host config.

Evidence sources:

- Manifest diff and README diff.
- Isolated install output and cache listing.
- Checksum comparison of real host configuration files.

Owner notes:

- This fixture protects the local plugin distribution overlay.

## plugin-distribution-own-use

Target behavior: the author's own daily use stays on direct skill installs
instead of turning into a plugin.

Input prompt: "I edit these skills every day on this machine. Should I install
them through the Codex plugin we just published?"

Context and files:

- A machine that already installs the same skills directly in edit or link
  mode.
- `references/plugin-distribution.md`.

Expected output:

- Recommends keeping the direct installs, because plugin installs are versioned
  copies that only change through an update.
- States that installing the plugin as well would load each skill twice.
- Keeps the plugin as the distribution route for other machines.

Forbidden behavior:

- Installs the plugin on the machine alongside the direct installs.
- Removes the direct installs to make room for the plugin without a user
  decision.

Acceptance checks:

- The answer keeps one install route per machine and names the double-load
  risk.
- No plugin install or removal command runs.

Baseline expectation:

- A no-skill baseline may install the plugin on top of the direct installs.

Evidence sources:

- Executor response.
- Host plugin list before and after.

Owner notes:

- This fixture protects the route choice in the plugin distribution overlay.
