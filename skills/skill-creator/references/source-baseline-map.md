# Source Baseline Map

Use this ledger to confirm that `skill-creator` preserves both source
families before applying local production overlays.

## Source Families

### Anthropic Skill Creator Source

Source: `https://github.com/anthropics/skills`, `skills/skill-creator/`, commit
`d211d437443a7b2496a3dad9575e7dddd724c585`.

Anthropic owns the skill co-development loop: intent capture, drafting,
realistic test prompts, with-skill versus baseline execution, grading, review
viewer, feedback iteration, improvement heuristics, blind comparison,
description optimization, benchmark aggregation, and package semantics.

| Anthropic component | Local component | Status |
| --- | --- | --- |
| source `SKILL.md` flow text | `references/source-anthropic-skill-creator.md` | exact source copy |
| create/test/review/improve loop | `SKILL.md` | source-composed flow written into local skill |
| JSON artifact schemas | `references/schemas.md` | exact source copy |
| grader prompt | `agents/grader.md` | exact source copy |
| analyzer prompt | `agents/analyzer.md` | exact source copy |
| comparator prompt | `agents/comparator.md` | exact source copy |
| benchmark aggregation | `scripts/aggregate_benchmark.py` | exact source copy |
| review viewer | `eval-viewer/viewer.html`, `eval-viewer/generate_review.py` | exact source copy |
| trigger-eval review UI | `assets/eval_review.html` | exact source copy |
| description optimization | `scripts/run_eval.py`, `scripts/run_loop.py`, `scripts/improve_description.py`, `scripts/generate_report.py` | Codex default runner, Claude selectable |
| packaging | `scripts/package_skill.py` | source archive shape, PyYAML fallback preflight |

### OpenAI Codex Skill Creator Source

Tracked source: `openai/skills`, `skills/.system/skill-creator/`, commit
`af9b54f235d0d56c6b4410be54d578b0fda4ddfc` in repository
`upstreams.yaml`.

OpenAI owns Codex-native skill shape: frontmatter trigger contract, skill
anatomy, progressive disclosure as Codex expects it, `agents/openai.yaml`,
interface metadata guidance, initialization scaffolding, UI metadata
generation, and basic validator conventions.

| OpenAI component | Local component | Status |
| --- | --- | --- |
| source `SKILL.md` authoring guide | `references/source-openai-skill-creator.md` | exact source copy |
| `references/openai_yaml.md` | `references/source-openai-yaml.md` | exact source copy |
| `agents/openai.yaml` | `references/source-openai-agent-openai.yaml` | exact source copy for provenance |
| icon assets | `assets/source-openai-skill-creator-small.svg`, `assets/source-openai-skill-creator.png` | exact source copies for provenance |
| `scripts/init_skill.py` | `scripts/init_skill.py` | exact source copy, runtime scaffold |
| `scripts/generate_openai_yaml.py` | `scripts/generate_openai_yaml.py` | exact source copy, runtime metadata generator |
| `scripts/quick_validate.py` | `references/source-openai-quick-validate.py` | exact source copy; runtime filename intentionally not used |
| source license | `references/source-openai-license.txt` | exact source copy |

## Conflict Resolutions

- `scripts/quick_validate.py` remains the Anthropic source validator because
  `scripts/package_skill.py` uses it for `.skill` package semantics. The
  OpenAI validator is preserved as `references/source-openai-quick-validate.py`.
- `agents/openai.yaml` is local production metadata, not an exact OpenAI source copy.
  The source copy is preserved separately as
  `references/source-openai-agent-openai.yaml`.
- The local `SKILL.md` is a source-composed entrypoint. It may combine Anthropic
  loop semantics and OpenAI Codex conventions, but source-specific behavior
  must stay traceable to this map and `references/source-patch-manifest.md`.

## Non-Claims

- Codex proxy trigger tests do not prove native host auto-trigger loading.
- Local fixture markdown is not an alternate execution artifact.
- Local validators do not replace eval evidence or human review.
- OpenAI source scaffolding does not redefine Anthropic benchmark or review
  semantics.
