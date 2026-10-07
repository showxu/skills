# Architecture Review Prompt: <Topic>

Review whether the current local architecture docs align with the
Code-to-Architecture Distillation method.

Do not implement runtime code. Make docs edits only if this prompt explicitly
asks for edits; otherwise return findings and recommended changes.
Use this template only when upstream or donor evidence is being compared
against local architecture truth. For ordinary docs cleanup with no donor
reconstruction goal, use the repository's normal docs workflow.

## Context

- Local project/module: <project/module>.
- Local docs to inspect first: <Docs/Architecture, Docs/Reference,
  Docs/Proposals, Docs/Decisions, AGENTS.md, README paths>.
- Upstreams / donors to compare: <upstreams>.
- Per-source findings or synthesis reports to inspect:
  <.agent/code-to-arch-distillation/<topic>/findings/* or
  .agent/code-to-arch-distillation/<topic>/synthesis.md, if present>.
- Current phase / stage assumption: <phase, or ask Codex to judge>.

## Review Requirements

- Phase / stage judgment.
- What local docs currently say.
- What upstream evidence suggests.
- Local file paths and upstream evidence cited where available.
- Alignment gaps.
- Over-copying risks.
- Under-absorption risks.
- Boundary risks.
- Recommended doc changes.
- HITL gate required before any architecture truth change.
- Non-goals and deferred decisions.

## Edit Requirements

If edits are requested:

- Preserve local repo and module boundaries.
- Update architecture truth only after main-agent synthesis and required HITL
  gates.
- Put current truth in `Docs/Architecture` or accepted decision docs.
- Keep donor evidence in the staged workspace; put accepted reference facts in
  `Docs/Reference` in product language.
- Put options in `Docs/Proposals`.
- Keep execution plans out of architecture truth unless the repo explicitly
  uses that path for plans.
- Include a key diff section focused on the main fragments changed.

## Output

Return findings first, then recommended changes, then key diff if edits were
made.
