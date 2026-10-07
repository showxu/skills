# Source Patch Manifest

Use this manifest as the allowlist for local differences from source baseline
files. When refreshing sources, copy the source files first, then reapply only
the patches or conflict resolutions listed here. Any new local behavior must
add a row before it is relied on.

## Sources

Anthropic source:
`https://github.com/anthropics/skills`, `skills/skill-creator/`, commit
`d211d437443a7b2496a3dad9575e7dddd724c585`.

OpenAI source:
`openai/skills`, `skills/.system/skill-creator/`, commit
`af9b54f235d0d56c6b4410be54d578b0fda4ddfc`, tracked in repository
`upstreams.yaml`.

## Policy

- Preserve source baseline semantics before applying local overlays.
- Keep Anthropic co-development, eval, review, benchmark, feedback iteration,
  description optimization, and package-loop semantics intact.
- Keep OpenAI Codex skill anatomy, trigger-contract guidance, progressive
  disclosure conventions, `agents/openai.yaml`, and scaffold behavior intact.
- Prefer exact source copies when no Codex host incompatibility or source
  conflict exists.
- Patch source-derived files only for host-command replacement, source
  composition, conflict resolution, local package/preflight behavior, or
  documented non-claims.
- Do not maintain local artifact skeletons for Anthropic JSON shapes. Use
  `references/schemas.md` and the source flow examples directly.
- Local overlay documents must not redefine Anthropic eval stage order or
  OpenAI Codex skill anatomy.
- Use `references/source-role-map.md` and
  `references/architecture.md` before deleting or
  compressing source or local-only files.

## Anthropic Exact Source Copies

| Source file | Local file | Reason |
| --- | --- | --- |
| `scripts/__init__.py` | `scripts/__init__.py` | Package marker; no Codex change needed. |
| `scripts/aggregate_benchmark.py` | `scripts/aggregate_benchmark.py` | Benchmark aggregation is host-neutral when Codex emits the source `run-*` layout. |
| `scripts/generate_report.py` | `scripts/generate_report.py` | Description optimization report generation is host-neutral. |
| `scripts/quick_validate.py` | `scripts/quick_validate.py` | Lightweight Anthropic validator retained with its PyYAML dependency and package semantics. |
| `scripts/utils.py` | `scripts/utils.py` | Shared parser utility is host-neutral. |
| `agents/analyzer.md` | `agents/analyzer.md` | Post-hoc analysis prompt is host-neutral. |
| `agents/comparator.md` | `agents/comparator.md` | Blind comparison prompt is host-neutral. |
| `agents/grader.md` | `agents/grader.md` | Grader prompt is host-neutral; Codex evidence caveats live in local references. |
| `assets/eval_review.html` | `assets/eval_review.html` | Trigger-query review UI is host-neutral. |
| `eval-viewer/generate_review.py` | `eval-viewer/generate_review.py` | Human eval review generator is host-neutral. |
| `eval-viewer/viewer.html` | `eval-viewer/viewer.html` | Human review UI is host-neutral. |
| `references/schemas.md` | `references/schemas.md` | Artifact schema reference is host-neutral. |
| `SKILL.md` | `references/source-anthropic-skill-creator.md` | Exact source flow copy for fidelity checks. |

## OpenAI Exact Source Copies

| Source file | Local file | Reason |
| --- | --- | --- |
| `SKILL.md` | `references/source-openai-skill-creator.md` | Codex-native skill authoring and scaffold guidance. |
| `references/openai_yaml.md` | `references/source-openai-yaml.md` | Codex UI metadata field definitions. |
| `agents/openai.yaml` | `references/source-openai-agent-openai.yaml` | Provenance copy; this skill owns its runtime metadata separately. |
| `assets/skill-creator-small.svg` | `assets/source-openai-skill-creator-small.svg` | Provenance copy of source icon. |
| `assets/skill-creator.png` | `assets/source-openai-skill-creator.png` | Provenance copy of source icon. |
| `scripts/init_skill.py` | `scripts/init_skill.py` | Runtime Codex skill scaffold generator. |
| `scripts/generate_openai_yaml.py` | `scripts/generate_openai_yaml.py` | Runtime Codex UI metadata generator. |
| `scripts/quick_validate.py` | `references/source-openai-quick-validate.py` | Provenance copy; runtime `scripts/quick_validate.py` is Anthropic-owned. |
| `license.txt` | `references/source-openai-license.txt` | Source license copy. |

## Source-Derived Local Files

| Source file | Local file | Patch type | Reason | Non-claim |
| --- | --- | --- | --- | --- |
| Anthropic `SKILL.md` and OpenAI `SKILL.md` | `SKILL.md` | Source composition | Route production skill authoring through OpenAI Codex conventions plus Anthropic co-development/eval flow, selected multi-skill review boundaries, local production gates, first-principles authoring checks, boundary ownership checks, abstraction-boundary checks, and complex topology decisions. | Does not define a second eval workflow, replace Codex skill anatomy, own skill taxonomy or placement decisions, authorize write-capable subagents, or require subagents for clearly narrow work. |
| Anthropic `scripts/improve_description.py` | `scripts/improve_description.py` | Host-command replacement | Use `codex exec` by default and keep `--runner claude` compatibility. | Codex runner is proxy evidence, not native host trigger proof. |
| Anthropic `scripts/package_skill.py` | `scripts/package_skill.py` | Dependency/preflight adapter | Prefer Anthropic `quick_validate.py`; fall back to `validate_skill_package.py --package-mode` when PyYAML is unavailable. | Archive shape stays source zip-based `.skill`. |
| Anthropic `scripts/run_eval.py` | `scripts/run_eval.py` | Host-command replacement | Use `codex exec` by default, keep `--runner claude` compatibility, run Codex prompt-input setup preflight, resolve rendered skill-root aliases to the exact candidate file when descriptions are shortened, and fail fast on Codex runner blockers. | A same-name installed entry or a user-mentioned path does not establish candidate visibility. Codex prompt-input proves rendered prompt visibility only; Codex runner remains proxy evidence, not native host auto-trigger loading. |
| Anthropic `scripts/run_loop.py` | `scripts/run_loop.py` | Host-command threading | Pass `runner` through eval and improvement loop, make model optional for host defaults, and preserve Codex setup evidence in iteration history. | Does not alter train/test optimization semantics or claim native trigger proof. |

## Local-Only Files

| Local file | Responsibility | Reason | Non-claim |
| --- | --- | --- | --- |
| `references/source-patch-manifest.md` | Patch bookkeeping | Record the exact allowlist of source differences. | Not an execution procedure. |
| `references/source-baseline-map.md` | Source capability ledger | Map Anthropic and OpenAI source capabilities to local files and conflict resolutions. | Not an execution procedure. |
| `references/source-role-map.md` | Source ownership policy | Decide whether behavior belongs to Anthropic, OpenAI, local composition, or local overlay. | Not a runtime workflow. |
| `references/baseline-maintenance.md` | Refresh and deletion guard | Keep source baselines and eval baselines distinct. | Does not authorize deleting host system skills by itself. |
| `references/anthropic-eval-loop.md` | Codex host adapter | Translate only Anthropic host mechanics to Codex commands and non-claims. | Source flow remains `source-anthropic-skill-creator.md`. |
| `references/eval-and-review-standard.md` | Fixture/run artifact standard | Keep durable fixture inputs distinct from Anthropic run artifacts. | Does not replace `evals/evals.json` or `review.html`. |
| `references/eval-fixtures.md` | Self-fixture catalog | Durable checks for this adapter's behavior. | Not a benchmark result log. |
| `references/hitl-design.md` | HITL overlay | Standardize user decision gates, host-specific structured question mapping, subagent consent, and topology escalation consent. | Does not authorize subagents or fan-out/fan-in designs by itself. |
| `references/host-compatibility.md` | Host compatibility overlay | Preserve Claude/Anthropic capabilities while adapting host-specific mechanics. | Does not claim all Claude skills are Codex-compatible. |
| `references/parallel-workflow-design.md` | Parallel workflow overlay | Capture runtime serial/parallel topology, fan-out/fan-in contracts, sub-skill decomposition guidance, and topology escalation requirements for production skills. | Does not change Anthropic eval stage order or claim host-native subagent support. |
| `references/plugin-distribution.md` | Plugin distribution overlay | Publish already-validated skills as Claude Code or Codex plugins using observed manifest, version-label, and cache behavior. | Does not install or manage plugins on a machine, choose collection grouping, or claim host behavior beyond the isolated install checks. |
| `references/single-skill-validation.md` | Codex preflight docs | Explain single-skill validation and package fallback. | Does not replace eval evidence or human review. |
| `references/architecture.md` | Maintenance architecture | Distinguish source baselines, source-derived files, conflict resolutions, and local overlays. | Not a separate authoring workflow. |
| `references/skill-design-principles.md` | Local quality overlay | Capture production skill design checks, first-principles authoring checks, boundary ownership checks, abstraction-boundary checks, canonical-output normalization, complex topology decisions, and least-privilege tool-boundary guidance. | Must not override source baselines, erase role-owned provenance, or require subagents by default. |
| `scripts/validate_skill_package.py` | Codex single-skill preflight | Validate source frontmatter rules plus resource roots, UI metadata, scripts, and package warnings. | Not a substitute for eval evidence or human review. |
| `scripts/test_prompt_input.py` | Codex visibility-preflight regression checks | Exercise shortened descriptions, aliased and absolute registry paths, and false-positive candidate identities. | Does not score triggers or replace the source eval loop. |
| `agents/openai.yaml` | Local OpenAI UI metadata | Manual entry surface for this skill in Codex. | Not a second trigger contract or exact source copy. |

## Refresh Checklist

1. Compare Anthropic and OpenAI source files against their mapped local files.
2. Restore exact-copy files from source.
3. Reapply only the source-derived patch rows above.
4. Recheck local-only files against their named responsibilities.
5. Update this manifest for any deliberate new difference before using it.
6. Run the single-skill validator and any additional validation required by the
   owning host or package workflow.
