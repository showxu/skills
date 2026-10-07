# Anthropic Skill Creator Flow For Codex

Use this reference when running Anthropic-style skill evals, benchmark review,
human feedback, blind comparison, description optimization, or packaging in
Codex.

This is a subordinate host adapter, not an entrypoint and not a fork. Enter
through `SKILL.md`; use this file only when the Anthropic toolchain mechanics
need a Codex equivalent. The source receipt is
`references/source-anthropic-skill-creator.md`; JSON artifact shapes come
from `references/schemas.md`.

Subagent guidance in this file is only for eval executor isolation. Do not use
it as runtime parallel-workflow design guidance for a target skill; use
`references/parallel-workflow-design.md` for that.

## Allowed Codex Substitutions

This list is exhaustive for eval/review/benchmark/description-optimization
flow. A local eval-flow difference is allowed only when the Anthropic toolchain
cannot run in Codex.

- Replace Claude Code command points such as `claude -p` with the adapted
  `codex exec` paths in `scripts/run_eval.py`, `scripts/run_loop.py`, and
  `scripts/improve_description.py`.
- Use `scripts/validate_skill_package.py --package-mode` only as the
  `package_skill.py` fallback when PyYAML is unavailable.

Do not maintain local JSON skeletons or a multi-baseline benchmark shape. Local
fixture standards may define durable input quality, but execution still
materializes Anthropic `evals/evals.json` and follows this flow.

## Eval Workspace

Use the Anthropic source workspace shape:

```text
<workspace>/
└── iteration-1/
    ├── evals/evals.json
    ├── eval-<id-or-name>/
    │   ├── eval_metadata.json
    │   ├── with_skill/
    │   │   └── run-1/
    │   │       ├── outputs/
    │   │       ├── transcript.md
    │   │       ├── timing.json
    │   │       └── grading.json
    │   └── without_skill/
    │       └── run-1/
    │           ├── outputs/
    │           ├── transcript.md
    │           ├── timing.json
    │           └── grading.json
    ├── review.html
    ├── feedback.json
    ├── benchmark.json
    └── benchmark.md
```

For existing-skill improvement, use `old_skill/` instead of `without_skill/`.
The default comparison is exactly two configurations:

- `with_skill` and `without_skill` for new-skill evals
- `with_skill` and `old_skill` for existing-skill improvements

If the target skill already has reusable fixture cases, convert them into
`evals/evals.json`. If not, write `evals/evals.json` directly from the
Anthropic source prompt-generation guidance. In both cases, `evals/evals.json`
is the execution artifact consumed by the flow.

## Codex Run Shape

Codex runs use the same workspace and artifact shape. Only the executor
mechanic changes when the Anthropic toolchain is unavailable. Executor prompts
must not include hidden grading criteria, previous answers, or intended fixes.

For non-interactive `codex exec` runs, reserve `outputs/response.md` for the
host-captured final assistant message. Do not ask the executor to write
`outputs/response.md` when the harness uses `--output-last-message` for that
path; ask it to return the final answer in chat and let the harness capture it.
If the task needs additional files, write them as other named artifacts under
`outputs/`.

For viewer compatibility, make each run prompt discoverable without modifying
the source `eval-viewer/generate_review.py`. Write the executor transcript to
`run-*/transcript.md` or `run-*/outputs/transcript.md`, and prepend it with:

```markdown
## Eval Prompt

<actual executor prompt>
```

Alternatively, place `eval_metadata.json` at the run directory or configuration
directory where the source viewer already looks for it. Do not rely on
`outputs/response.md` for prompt discovery; the source viewer treats that as
an output file, not prompt metadata. Do not patch the viewer just to support a
local transcript shape.

Full benchmark evals require executor isolation. Anthropic uses subagents for
this. In Codex, use an equivalent fresh executor context, such as a separate
`codex exec` invocation or a host-provided independent agent when available.
Codex subagents are acceptable executors only when they are started with a
minimal run prompt and do not inherit the authoring conversation, assertions,
feedback, intended fixes, or grading criteria. If the host exposes a
fork/inherit-context option, disable it for eval executors.
Do not ask a non-interactive `codex exec` executor to spawn nested Codex
subagents. In that host shape, the authoring context must launch one fresh
`codex exec` per run, or explicitly record that full benchmark isolation was
not available.
Do not execute `with_skill` or baseline tasks inline in the current authoring
conversation and treat them as benchmark evidence. If no isolated executor is
available, run only a qualitative sanity check and disclose that the full
benchmark was skipped.

Skill exposure must be configuration-specific:

- `with_skill`: pass the current skill path and instruct the executor to read
  it first.
- `without_skill`: pass no target skill path and instruct the executor not to
  read or use the target skill, its source directory, or host skill-registry
  entry.
- `old_skill`: pass only the old snapshot path and instruct the executor not to
  read or use the current skill.

Executor prompts must use this explicit contract:

- `with_skill`: `Skill path: <current-skill-path>` plus "Read this skill before
  answering."
- `without_skill`: `Skill path: none` plus "Do not read or use the target
  skill, its source directory, or any host skill-registry entry."
- `old_skill`: only the old snapshot path plus a prohibition on reading or
  using the current skill.

If host-level auto-triggering could load the target skill during baseline
execution, record that as residual contamination risk and do not claim a clean
baseline unless the risk is ruled out.
For `without_skill`, run from an isolated workspace where the target skill
source directory is not visible as a parent or sibling path; prompt wording is
not enough to prove a clean baseline when the source tree is discoverable.

## Flow

1. Create `evals/evals.json` and per-eval `eval_metadata.json` using
   `references/schemas.md`.
   "Mocked evals" are still evals: keep the same artifact shape rather than a
   standalone `mock_eval_results.json` or prose-only review.
2. Run paired `with_skill` and baseline executions in isolated executor
   contexts, saving final responses and requested artifacts under each run's
   `outputs/`.
   Save `transcript.md` with `## Eval Prompt` at the top so the source review
   viewer can display the real task prompt instead of `(No prompt found)`.
3. While runs execute, draft or refine objective assertions in
   `eval_metadata.json` and `evals/evals.json`.
4. Write `timing.json` from available timing/token evidence. Use `null` plus a
   note when the host does not expose a field.
5. Grade actual outputs into `grading.json` using `agents/grader.md`. Evidence
   must point to outputs, transcripts, command output, or inspected files.
   Missing child `outputs/response.md`, `timing.json`, or `grading.json` means
   the run is incomplete, even if a wrapper response claims completion.
   If `outputs/response.md` is only a wrapper such as "completed" or "saved to
   path", grade the referenced artifacts directly when they exist; otherwise
   rerun with proper Codex response capture.
6. Aggregate:

```bash
python3 <skill-creator>/scripts/aggregate_benchmark.py \
  <workspace>/iteration-1 \
  --skill-name <skill-name> \
  --skill-path <path-to-skill>
```

7. Generate the review artifact:

```bash
python3 <skill-creator>/eval-viewer/generate_review.py \
  <workspace>/iteration-1 \
  --skill-name <skill-name> \
  --benchmark <workspace>/iteration-1/benchmark.json \
  --static <workspace>/iteration-1/review.html
```

For iteration 2 and later, add
`--previous-workspace <workspace>/iteration-<N-1>`.

8. Read `feedback.json` when the user finishes review, improve the skill from
   benchmark evidence and human feedback, then rerun the affected evals in a
   new iteration.
9. Use `agents/comparator.md` and `agents/analyzer.md` for blind comparison
   when the user asks whether one version is actually better.
10. Optimize descriptions only after behavior is stable, using the adapted
    trigger scripts.

## Description Optimization

Use the Anthropic source description-optimization loop. The Codex adapter
changes only the command runner:

1. Generate should-trigger and should-not-trigger query sets.
2. Review queries with the user using `assets/eval_review.html`.
3. Run `scripts/run_loop.py --runner codex` by default, or `--runner claude`
   only when Claude CLI is intentionally available.
4. In the Codex runner, `scripts/run_eval.py` first uses
   `codex debug prompt-input` to verify the candidate skill is visible in the
   rendered prompt before proxy scoring. This is eval setup evidence only; it
   does not prove runtime skill consultation or native auto-trigger success.
5. Do not replace the optimization loop with direct `scripts/run_eval.py`.
   `run_eval.py` is a leaf evaluator for the loop, or a diagnostic single-pass
   check when no description change is being optimized.
6. If the Codex runner is blocked by sandbox, session, or state-db limits, stop
   and report the blocker. Do not silently fall back to `--runner claude` unless
   the user intentionally selected Claude.
7. Treat Codex trigger scores as proxy evidence unless native host trigger
   selection was actually observed.

## Packaging

Before packaging or presenting a skill as ready, run:

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
