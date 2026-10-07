# Eval Fixtures And Review Artifacts

Use this standard when adding durable evaluation material for a production or
high-risk skill.

This is a local quality overlay, not an entrypoint. Enter through `SKILL.md`;
use this file only for fixture quality, evidence rules, and review artifact
boundaries.

This file does not define a separate eval flow. Runtime execution still uses
Anthropic's `evals/evals.json`, paired configurations, grading, benchmark
aggregation, review artifact, feedback, and rerun loop.

## Terms

- Eval fixture: durable test input for one skill behavior. It includes the
  prompt, setup, expected behavior, forbidden behavior, and acceptance checks.
- Eval run: a dated execution of one or more fixtures against a real skill,
  baseline, or old skill snapshot.
- Benchmark: aggregated result from an eval run.
- Feedback: human review signal from `review.html`, exported feedback, or real
  use.

Fixtures are durable inputs. Eval run artifacts are execution outputs.

## Fixture Placement

Each production or high-risk skill may keep durable behavior fixtures in:

```text
skill/
  references/
    eval-fixtures.md
```

Do not store dated outputs, review pages, benchmark files, transcripts,
feedback exports, or temporary paths in the skill source. Those belong in the
eval workspace.

When running evals, convert selected fixture cases into the Anthropic source
`evals/evals.json` format. `eval-fixtures.md` is only an input catalog.

## Fixture Shape

Each fixture should use this shape:

```markdown
## <stable-fixture-id>

Target behavior: <one behavior under test>

Input prompt: "<realistic user request>"

Context and files:

- <required file, account state, workspace state, or "none">

Expected output:

- <observable expected behavior or artifact>

Forbidden behavior:

- <behavior that should fail the eval>

Acceptance checks:

- <objective check that can become an eval assertion>

Baseline expectation:

- <why no-skill, wrong-sibling, or old-skill should plausibly fail>

Evidence sources:

- <outputs, transcript, generated files, command output, or review feedback>

Owner notes:

- <source receipt, maintenance note, or "none">
```

Rules:

- The fixture id is stable and kebab-case.
- The target behavior covers one behavior class, not a whole workflow suite.
- The input prompt is what the executor sees; it must resemble a real user
  request and must not include hidden grading answers.
- Expected output and forbidden behavior are for fixture authors and graders,
  not extra text to leak into executor prompts.
- Acceptance checks must be observable and should map directly to
  `evals/evals.json` assertions.
- Baseline expectation should explain why `without_skill`, wrong-sibling, or
  `old_skill` is expected to reveal value.
- Evidence sources must be available from run artifacts, not from memory of the
  authoring conversation.
- Owner notes may cite source receipts, but must not become execution
  instructions.

For Codex-captured transcripts, write `run-*/transcript.md` or
`run-*/outputs/transcript.md` and include a top-level `## Eval Prompt` section
before raw executor logs. The source review viewer reads that section when
run-local metadata is absent; without it, the UI falls back to `(No prompt
found)`. Do not rely on `outputs/response.md` or `prompt.txt` for prompt
discovery.

Do not include hidden grading answers in the prompt. A generic no-skill or
wrong-sibling baseline should plausibly fail at least one important expectation.

## Quality Gate

Before accepting a fixture, check:

- The target behavior is specific.
- The prompt resembles real user or source usage.
- The prompt does not leak expected answers or intended fixes.
- Negative boundaries are explicit when sibling overlap or unsafe action is
  possible.
- Acceptance checks are observable from outputs, transcripts, files, or command
  results.
- The likely failure class is diagnosable.
- The fixture can be rerun without stale temp paths or hidden conversation
  context.

Weak fixtures do not prove skill quality. Fix fixture quality before using the
score to justify a skill change.

## Comparative Runs

Default comparative runs use exactly two configurations:

- `with_skill` and `without_skill` for new skills.
- `with_skill` and `old_skill` for existing-skill improvements.

Do not run both `old_skill` and `without_skill` in the same benchmark unless
the user explicitly asks for extra exploratory analysis.

For Codex comparative evidence, use the same Anthropic source workspace and artifact
shape. Avoid leaking hidden grading criteria, previous answers, or intended
fixes into executor prompts.

Full benchmark evidence requires isolated executors. Anthropic gets isolation
from subagents. Codex must use an equivalent fresh executor context; do not use
the current authoring conversation to run `with_skill` or baseline tasks and
then count those outputs as benchmark evidence. Inline runs are qualitative
sanity checks only. Codex subagents are acceptable only when each run receives
a minimal executor prompt and does not inherit the authoring conversation,
assertions, feedback, intended fixes, or grading criteria. If the host exposes
a fork/inherit-context option, disable it for eval executors.
When `codex exec` is the executor, do not require it to spawn nested Codex
subagents. Treat the top-level per-run `codex exec` process as the isolated
executor, or record that the host could not provide isolated benchmark runs.

Configuration exposure is part of the evidence quality:

- `with_skill` evidence must come from an executor that received and read the
  current skill.
- `without_skill` evidence must come from an executor that did not receive,
  read, or use the target skill, its source directory, or host skill-registry
  entry.
- `old_skill` evidence must come from an executor that received only the old
  snapshot and did not read or use the current skill.

Make that boundary visible in prompts and filesystem setup:

- `with_skill` prompts include `Skill path: <current-skill-path>` and require
  reading that skill before answering.
- `without_skill` prompts include `Skill path: none`, prohibit reading or using
  the target skill/source/host registry, and run from a workspace where the
  target skill source directory is not visible as a parent or sibling path.
- `old_skill` prompts include only the old snapshot path and prohibit the
  current skill.

If host auto-triggering could load the target skill in a baseline run, record
that contamination risk and do not treat the baseline as clean evidence unless
the risk is ruled out.

## Evidence Rules

Grade actual outputs into each configuration's `grading.json`. Passing evidence
must cite run outputs, generated artifacts, transcripts, command output, or
inspected files.

For Codex CLI evals, `outputs/response.md` should be the host-captured final
assistant message. Do not make the executor write that file itself when the
harness also captures `--output-last-message` to the same path. If generated
files are part of the task, save them under different names in `outputs/`.

Do not count scaffolded responses, synthetic baselines, self-grading, unchanged
boilerplate, or "the skill says it should" as evidence.
Do not accept wrapper-level completion claims when child run artifacts are
missing. A completed Codex run must have inspectable `outputs/response.md`,
prompt-bearing `transcript.md`, timing evidence, and `grading.json`; otherwise
mark it incomplete and preserve the failure in the benchmark.
If `outputs/response.md` only reports that another file was saved or that the
task completed, treat it as wrapper text and grade the real referenced artifact;
if there is no referenced artifact, rerun the executor.
