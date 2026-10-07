# Source Role Map

Use this file before changing `skill-creator` behavior. It decides whether
a concern belongs to Anthropic source fidelity, OpenAI source fidelity, local
composition, or local production overlays.

## Role Order

1. Preserve Anthropic source baseline semantics.
2. Preserve OpenAI Codex source baseline semantics.
3. Compose the two baselines into one self-contained production workflow.
4. Apply local production enhancements only after the source-owned behavior is
   intact.

## Fusion Policy

Keep each source family original at the receipt layer:

- Do not rewrite exact source copies for shared terminology.
- Do not delete source-specific examples, tone, host assumptions, or guardrails
  just because the other source expresses the idea differently.
- Do not make Anthropic files sound like OpenAI files, or OpenAI files sound
  like Anthropic files.
- Do not merge source receipts into one blended reference file.

Fuse only in local-production-owned files:

- `SKILL.md`
- `references/source-role-map.md`
- `references/source-baseline-map.md`
- `references/source-patch-manifest.md`
- `references/baseline-maintenance.md`
- local overlay references

When the sources overlap, cite both as evidence and let the local production layer decide
the operating rule. The source receipts remain provenance, not prose to be
normalized.

## Tracked Source Baseline

A tracked source baseline is stronger than a generic upstream reference. It has
all of the following:

- repository identity
- source skill or resource path
- commit or checksum
- file-level local mapping
- explicit owned behavior in this skill
- manifest rows for every patch or conflict resolution
- repository-level tracking in `upstreams.yaml` when a public source repo
  exists

Do not treat tracked source baselines as loose inspiration. If a merge touches
behavior owned by a tracked source, check the source baseline map and patch
manifest before editing.

## Anthropic Owns

Anthropic owns the skill co-development and improvement loop:

- intent capture, interview, and research handoff
- skill drafting and revision heuristics
- realistic test prompt design
- with-skill versus `without_skill` or `old_skill` execution semantics
- eval workspace and artifact shapes
- assertion drafting, grading, and evidence expectations
- benchmark aggregation and variance-aware review
- human review viewer and feedback iteration
- blind comparison with comparator/analyzer passes
- description optimization loop
- `.skill` package semantics
- host fallback semantics for Anthropic environments when preserved as source

Do not remove or simplify these capabilities while absorbing OpenAI source
files. Host-command substitutions are allowed only when documented in
`references/source-patch-manifest.md`.

## OpenAI Owns

OpenAI owns Codex-native skill shape and scaffolding:

- frontmatter `name` and `description` as the primary trigger contract
- Codex skill anatomy: `SKILL.md`, `references/`, `scripts/`, `assets/`,
  and `agents/openai.yaml`
- progressive disclosure expectations for Codex skills
- `agents/openai.yaml` field definitions and UI metadata conventions
- `scripts/init_skill.py` scaffold behavior
- `scripts/generate_openai_yaml.py` metadata generation behavior
- basic validator conventions from the Codex system `skill-creator`

Do not replace these conventions with Anthropic-only assumptions. When an
OpenAI source file conflicts with an Anthropic runtime slot, preserve the
OpenAI source copy and record the conflict resolution.

## Local Production Owns

Local Production owns composition and production readiness:

- one self-contained entrypoint that no longer depends on reading the host
  system `skill-creator`
- Codex host substitutions for Anthropic command points
- source conflict resolution and patch bookkeeping
- durable fixture normalization
- HITL gate design
- host compatibility non-claims
- package preflight fallback
- boundary ownership rules
- parallel workflow topology guidance
- plugin distribution manifests and isolated install checks
- single-skill readiness validation

Local Production must not claim source authority for behavior it only composes or
adapts.

## Overlap Rules

- Codex file structure, UI metadata, and scaffold commands follow OpenAI.
- Co-development, evaluation, review, comparison, feedback, and package-loop
  semantics follow Anthropic.
- Shared principles such as concise `SKILL.md`, scripts for deterministic
  tasks, and references for large material may be cited from both sources.
- Local enhancements may be stricter, but they must be labeled as overlays and
  must not erase source behavior.
