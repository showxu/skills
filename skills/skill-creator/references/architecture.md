# Skill Creator Architecture

Use this reference when maintaining `skill-creator` itself. Its job is to
prevent three failure modes:

- deleting Anthropic co-development/eval capabilities while absorbing OpenAI
  scaffolding
- replacing OpenAI Codex skill conventions with Anthropic-only assumptions
- turning local production overlays into an untracked third source baseline

## Golden Rule

Preserve source baselines first, compose second, enhance last.

Exact source receipts stay original. Do not normalize Anthropic and OpenAI
source copies into a shared house style. The composition layer may reconcile
conflicts, but the receipts should remain suitable for byte-for-byte refreshes
and source audits.

Anthropic owns the skill co-development loop: intent capture, drafting,
realistic tests, with-skill versus baseline execution, grading, review,
feedback iteration, improvement, blind comparison, description optimization,
benchmark aggregation, and package-loop semantics.

OpenAI owns Codex-native skill shape: frontmatter trigger contract, skill
anatomy, progressive disclosure, `agents/openai.yaml`, scaffold generation, UI
metadata generation, and Codex validator conventions.

Local Production may adapt host mechanics, normalize inputs, add validation, document
non-claims, and compose the two sources into one self-contained workflow. It
must not reorder or replace Anthropic eval/review semantics, erase OpenAI
Codex skill conventions, or add untracked default benchmark configurations.

When unsure, preserve the source file and tighten its boundary instead of
deleting it.

## Ownership Map

### Anthropic Exact Source Copies

These files should stay byte-for-byte aligned with the Anthropic source unless
`references/source-patch-manifest.md` is explicitly changed:

| Local file | Source file | Purpose |
| --- | --- | --- |
| `agents/analyzer.md` | `agents/analyzer.md` | Post-hoc benchmark analysis prompt |
| `agents/comparator.md` | `agents/comparator.md` | Blind comparison prompt |
| `agents/grader.md` | `agents/grader.md` | Assertion grading prompt |
| `assets/eval_review.html` | `assets/eval_review.html` | Trigger-query review UI |
| `eval-viewer/generate_review.py` | `eval-viewer/generate_review.py` | Human eval review generator |
| `eval-viewer/viewer.html` | `eval-viewer/viewer.html` | Human eval review UI |
| `references/schemas.md` | `references/schemas.md` | JSON artifact schemas |
| `scripts/__init__.py` | `scripts/__init__.py` | Script package marker |
| `scripts/aggregate_benchmark.py` | `scripts/aggregate_benchmark.py` | Benchmark aggregation |
| `scripts/generate_report.py` | `scripts/generate_report.py` | Trigger optimization report |
| `scripts/quick_validate.py` | `scripts/quick_validate.py` | Lightweight package validator |
| `scripts/utils.py` | `scripts/utils.py` | Shared parser utilities |
| `references/source-anthropic-skill-creator.md` | `SKILL.md` | Exact source flow receipt |

Maintenance rule: refresh these from source first, then reapply only
manifest-listed patches elsewhere.

### OpenAI Exact Source Copies

These files should stay byte-for-byte aligned with the OpenAI source unless
`references/source-patch-manifest.md` is explicitly changed:

| Local file | Source file | Purpose |
| --- | --- | --- |
| `references/source-openai-skill-creator.md` | `SKILL.md` | Codex skill authoring guide |
| `references/source-openai-yaml.md` | `references/openai_yaml.md` | OpenAI UI metadata schema reference |
| `references/source-openai-agent-openai.yaml` | `agents/openai.yaml` | Source UI metadata provenance |
| `references/source-openai-quick-validate.py` | `scripts/quick_validate.py` | Source validator provenance |
| `references/source-openai-license.txt` | `license.txt` | Source license |
| `assets/source-openai-skill-creator-small.svg` | `assets/skill-creator-small.svg` | Source icon provenance |
| `assets/source-openai-skill-creator.png` | `assets/skill-creator.png` | Source icon provenance |
| `scripts/init_skill.py` | `scripts/init_skill.py` | Runtime scaffold generator |
| `scripts/generate_openai_yaml.py` | `scripts/generate_openai_yaml.py` | Runtime OpenAI metadata generator |

Maintenance rule: do not overwrite Anthropic runtime files with OpenAI files
when filenames conflict. Preserve the source copy and record the conflict
resolution.

### Source-Derived Local Files

These start from one or both source baselines and carry explicit local changes:

| Local file | Patch owner | Allowed difference | Not allowed |
| --- | --- | --- | --- |
| `SKILL.md` | local source composition | Combines OpenAI Codex skill conventions, Anthropic co-development/eval loop, selected multi-skill review boundaries, local overlays, first-principles authoring checks, boundary ownership checks, abstraction-boundary checks, and complex topology decisions | A second eval workflow, loss of normal create/update coverage, skill taxonomy or placement ownership, write-capable subagent authorization, or subagent requirements for clearly narrow work |
| `scripts/improve_description.py` | Host-command replacement | Uses `codex exec` by default, keeps `--runner claude` | Claims native trigger proof from proxy runs |
| `scripts/package_skill.py` | Dependency fallback | Falls back to local validator when PyYAML is absent | Different `.skill` archive shape |
| `scripts/run_eval.py` | Host-command replacement | Uses `codex exec` by default, keeps `--runner claude`, runs Codex prompt-input setup preflight, and fails fast on Codex runner blockers | Claims native host auto-trigger evidence from prompt-input or proxy scores |
| `scripts/run_loop.py` | Host-command threading | Passes selected runner through the loop and records Codex setup evidence in iteration history | Different train/test optimization semantics |

Maintenance rule: every patch must be listed in
`references/source-patch-manifest.md` with a reason and a non-claim.

### Local Production Overlay

These are local quality controls. They are intentionally not source baseline
content, and they should remain subordinate to source-owned semantics:

| Local file | Local capability | Boundary |
| --- | --- | --- |
| `references/eval-and-review-standard.md` | Fixture quality and run-artifact placement | Feeds `evals/evals.json`; does not replace it |
| `references/eval-fixtures.md` | Self-fixture catalog for this adapter | Durable checks only; not a benchmark log |
| `references/hitl-design.md` | User decision gates, host-specific structured question mapping, subagent consent, and topology escalation consent | Does not authorize subagents or fan-out/fan-in designs by itself |
| `references/host-compatibility.md` | Claude/Anthropic-to-Codex compatibility decisions | Does not claim all Claude skills work in Codex |
| `references/parallel-workflow-design.md` | Runtime workflow topology, fan-out/fan-in contracts, sub-skill decomposition, and topology escalation requirements | Does not change Anthropic eval stage order or authorize host-native subagents |
| `references/plugin-distribution.md` | Claude Code and Codex plugin manifests, version labels, install docs, and isolated install checks | Does not install plugins on a machine or decide collection grouping |
| `references/single-skill-validation.md` | Package/present preflight explanation | Does not replace eval evidence or human review |
| `references/skill-design-principles.md` | Production skill authoring quality, first-principles authoring checks, boundary ownership checks, abstraction-boundary checks, canonical-output normalization, complex topology decisions, and least-privilege tool boundaries | Must not override source baselines, erase role-owned provenance, or require subagents by default |
| `scripts/validate_skill_package.py` | Codex package/preflight fallback | Keeps packaging usable when PyYAML is unavailable and validates local metadata | Does not replace source validators as provenance |
| `agents/openai.yaml` | Local UI metadata | Exposes this skill in Codex/OpenAI UI surfaces | Not an exact source copy |

Maintenance rule: if one of these feels too broad, narrow it. Do not delete it
solely because neither source has the same document.

### Governance Documents

| Local file | Purpose |
| --- | --- |
| `references/source-role-map.md` | Source ownership policy |
| `references/source-baseline-map.md` | Source capability ledger and conflict map |
| `references/source-patch-manifest.md` | Allowlist for source differences |
| `references/baseline-maintenance.md` | Refresh, merge, deletion, and eval baseline guardrails |
| `references/anthropic-eval-loop.md` | Codex mechanics and non-claims for Anthropic eval flow |
| `references/architecture.md` | This ownership map |

## Document Hierarchy

`SKILL.md` is the only active workflow entrypoint.

Supporting documents are subordinate:

- `references/source-role-map.md`: decide source ownership.
- `references/source-anthropic-skill-creator.md`: exact Anthropic source
  receipt for fidelity checks.
- `references/source-openai-skill-creator.md` and
  `references/source-openai-yaml.md`: exact OpenAI source receipts for Codex
  skill shape and metadata.
- `references/anthropic-eval-loop.md`: Codex toolchain adapter for executor
  mechanics, trigger-runner substitutions, and non-claims.
- `references/eval-and-review-standard.md`: local quality overlay for
  fixtures, evidence, and review artifacts only.
- `references/skill-design-principles.md`: local production skill-design
  overlay for boundary ownership, first-principles authoring, abstraction
  boundaries, canonical-output normalization, topology decisions, scripts,
  tool permissions, and evidence.
- `references/parallel-workflow-design.md`: local production workflow topology
  overlay for target-skill runtime design only.
- `references/plugin-distribution.md`: local overlay for publishing validated
  skills as Claude Code or Codex plugins.
- `references/source-patch-manifest.md`: allowlist for local differences.
- `references/baseline-maintenance.md`: source and eval baseline maintenance.

If documents conflict, apply this order: `SKILL.md`, source role map, source
baseline receipts, Codex toolchain adapter, local quality overlays, governance
notes. Narrow the lower-priority document rather than changing source-owned
semantics.

## Eval Flow Boundary

The eval flow belongs in `SKILL.md` and must stay aligned with Anthropic:

1. locate user position in the loop
2. capture intent and research gaps
3. draft or revise the skill
4. create eval prompts
5. create the workspace
6. run selected with-skill/baseline configurations
7. draft assertions while runs execute
8. capture timing
9. grade runs
10. aggregate benchmark
11. analyze benchmark patterns
12. generate review artifact
13. read human feedback
14. improve the skill
15. repeat iterations
16. blind comparison when needed
17. description optimization after behavior stabilizes
18. package or present

Local overlays may affect input quality, evidence quality, host commands, and
validation gates. They may not add a second default flow, skip review feedback,
or add default third configurations.

## What To Delete

Safe to delete:

- generated `__pycache__/`, `.pyc`, `.DS_Store`
- dated eval workspaces, transcripts, `review.html`, `benchmark.json`,
  `feedback.json`, and raw outputs accidentally placed in skill source
- local JSON artifact skeleton directories for Anthropic schema shapes

Do not delete without an explicit manifest update:

- Anthropic exact source copies
- OpenAI exact source copies
- local overlay references listed above
- Codex-only scripts and metadata
- source-derived patched files

## Refresh Workflow

1. Fetch or inspect the current Anthropic and OpenAI source skills.
2. Restore exact-copy files from source.
3. Compare source-derived files and reapply only manifest-listed patches.
4. Confirm `SKILL.md` still carries the full Anthropic eval flow and OpenAI
   Codex skill creation conventions.
5. Confirm local overlay docs constrain quality without redefining source
   semantics.
6. Run:

```bash
python3 <skill-creator>/scripts/validate_skill_package.py \
  <skill-creator> \
  --package-mode
```

7. Run any additional validation required by the owning host or package
   workflow.
