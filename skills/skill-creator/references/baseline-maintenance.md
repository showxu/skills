# Baseline Maintenance

Use this file when refreshing sources, resolving merge conflicts, or preparing
to delete the host official `skill-creator` after this skill has absorbed it.

## Source Baselines

Source baselines are provenance and fidelity anchors. They are not runtime
competitors once vendored into this skill.

These are tracked source baselines, not generic upstream intake. A tracked
source baseline must record the repository, source path, commit, local file
mapping, owned behavior, and patch policy.

Exact source copies should stay raw. Do not rephrase, normalize, compress, or
cross-pollinate source receipts to make them read consistently. If a source
needs interpretation, write that interpretation in the local production layer and keep the
source receipt intact.

Maintain two source families:

- Anthropic source baseline: skill co-development, eval, review, benchmark,
  feedback iteration, description optimization, and package-loop semantics.
- OpenAI source baseline: Codex skill anatomy, trigger contract, progressive
  disclosure, `agents/openai.yaml`, scaffold generation, and UI metadata
  conventions.

For each source refresh:

1. Check the tracked source entry in repository `upstreams.yaml`.
2. Copy source files into their mapped local paths.
3. Reapply only manifest-listed patches or conflict resolutions.
4. Preserve exact-copy files byte-for-byte unless the manifest says otherwise.
5. Update `references/source-baseline-map.md` if a source file is added,
   removed, renamed, or intentionally not used at runtime.
6. Update `references/source-patch-manifest.md` before relying on a new local
   behavior.
7. Update `upstreams.yaml` review coverage when a source path is newly
   absorbed or refreshed.
8. Run the single-skill validator.

## Anthropic Merge Guard

The main merge risk is deleting Anthropic behavior while adding OpenAI
scaffolding. Protect these Anthropic assets as exact source copies unless a
manifest row explicitly says otherwise:

- `agents/analyzer.md`
- `agents/comparator.md`
- `agents/grader.md`
- `assets/eval_review.html`
- `eval-viewer/generate_review.py`
- `eval-viewer/viewer.html`
- `references/schemas.md`
- `scripts/__init__.py`
- `scripts/aggregate_benchmark.py`
- `scripts/generate_report.py`
- `scripts/quick_validate.py`
- `scripts/utils.py`
- `references/source-anthropic-skill-creator.md`

Protect these source-derived patched files by checking the manifest before
editing:

- `SKILL.md`
- `scripts/improve_description.py`
- `scripts/package_skill.py`
- `scripts/run_eval.py`
- `scripts/run_loop.py`

## OpenAI Merge Guard

Protect these OpenAI source files as exact copies unless the manifest says
otherwise:

- `references/source-openai-skill-creator.md`
- `references/source-openai-yaml.md`
- `references/source-openai-agent-openai.yaml`
- `references/source-openai-quick-validate.py`
- `references/source-openai-license.txt`
- `assets/source-openai-skill-creator-small.svg`
- `assets/source-openai-skill-creator.png`
- `scripts/init_skill.py`
- `scripts/generate_openai_yaml.py`

The OpenAI validator is intentionally not installed as runtime
`scripts/quick_validate.py`; that runtime slot remains Anthropic-owned for
package semantics.

## Eval Baselines

Eval baselines are different from source baselines. Keep them isolated:

- New skill evals compare `with_skill` against `without_skill`.
- Existing skill improvements compare `with_skill` against `old_skill`.
- Do not default to a third configuration.
- Baseline executors must not read the target skill, current local source
  directory, intended fixes, assertions, hidden grading criteria, or source
  references.
- If clean isolation is not available, label the run a qualitative sanity check
  rather than a benchmark.

## Deleting Host Official Skill Creator

Only delete or disable the host official `skill-creator` after these are true:

- OpenAI source files and runtime scaffold scripts are vendored here.
- local validation passes.
- local skill no longer instructs the agent to read the host official skill at runtime.
- Trigger wording in local skill covers normal create/update requests.
- Any host update may restore the system skill, so deletion is an environment
  cleanup step, not a source-control guarantee.
