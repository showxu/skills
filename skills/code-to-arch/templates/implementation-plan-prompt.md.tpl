# Implementation Plan Prompt: <Topic>

Turn the accepted distilled design into an implementation plan for
<local project/module>.

Do not assume hidden conversation context. Read the architecture truth and local
code before planning. Do not implement code unless explicitly requested after
the plan is accepted.

## Read First

- Architecture truth: <Docs/Architecture / Decisions paths>.
- Accepted distillation synthesis:
  <.agent/code-to-arch-distillation/<topic>/synthesis.md or proposal path>.
- Donor evidence: <.agent/code-to-arch-distillation/<topic>/ upstream intake
  paths>.
- Reference facts: <Docs/Reference paths, if any>.
- Per-source findings:
  <.agent/code-to-arch-distillation/<topic>/findings/* paths, if useful>.
- Local modules and APIs: <paths>.
- Tests and fixtures: <paths>.
- AGENTS.md / README routing: <paths>.

## Planning Requirements

- Preserve module and repo boundaries.
- State phase / stage judgment.
- Define phased implementation slices.
- Name affected files or file families.
- Identify key implementation seams.
- Define runtime, DSL, adapter, renderer, host, or test-harness boundaries.
- List non-goals and intentionally deferred work.
- Include risks and mitigation checks.
- Include test plan and validation commands.
- Include acceptance criteria.
- Reference architecture truth for each major design choice.
- Cite local file paths and upstream evidence when available.
- If the plan would change architecture truth, stop and ask for the
  Architecture Truth Gate before planning implementation.

## Output

Return:

- plan summary
- affected files
- phased implementation steps
- test plan
- risks and non-goals
- acceptance criteria
- architecture truth references
- open questions
