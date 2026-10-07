# Example Capture Guide

## Purpose

Example capture gives `code-to-arch` a reusable teaching artifact
for future orchestrator behavior. It records why a task is a
Code-to-Architecture Distillation, what evidence exists, which donor ideas are
usable, which donor baggage is rejected, how local reconstruction works, which
HITL gates matter, and where artifacts or docs should live.

Example captures are policy and method artifacts. They should make future runs
consistent and auditable without pretending to be formal eval evidence or
accepted architecture truth.

## Artifact Distinctions

```text
Example capture
= structured teaching artifact for future orchestrator behavior.

Dry-run artifact
= task-scoped workflow output under `.agent/code-to-arch-distillation/<topic>/`.

Formal eval proof
= reproducible evaluation evidence, usually with explicit fixture, run result, and expected behavior.

Architecture truth
= accepted local truth under `Docs/Architecture`, after required HITL gates.

Knowledge case
= curated reusable pattern under `knowledge/cases/`, promoted only after the example has durable method value.
```

Example capture != formal eval proof.

Example capture != architecture truth.

Example capture != knowledge case by default.

## Accepted Sources

An example capture may be derived from:

- real `code-to-arch` dry-run artifacts
- accepted architecture changes after HITL
- user-provided architecture discussion summaries
- Codex execution summaries
- local repo docs and `.agent` plans
- upstream or donor references
- official documentation
- tests, fixtures, and examples
- synthetic behavior fixtures

The capture must state which source types were used and whether each source was
validated, partially validated, or unvalidated.

## Evidence Honesty

Every example capture must state exactly what is known and what is not known.
Use `templates/example-capture.md.tpl` and fill the evidence status fields
directly.

Required rules:

- Do not claim a conversation-derived example was produced by a formal skill run.
- Do not treat example captures as architecture truth.
- Do not promote every example to knowledge/cases/.
- Do not capture ordinary implementation-only tasks.
- Do not capture generic research with no local reconstruction goal.
- Do not capture README cleanup or package-doc normalization.
- Capture only examples that teach donor selection, extraction, rejected baggage, local reconstruction, HITL, artifact flow, or docs truth flow.
- Keep examples compact and operational.
- Preserve .agent/code-to-arch-distillation/<topic>/ as the workflow artifact path.
- Use knowledge/cases/ only for curated reusable patterns.

If the source is a conversation summary or Codex summary, mark formal
orchestrator run evidence as `no` or `unknown` unless actual run artifacts
exist. A summary can seed an example capture; it cannot retroactively become
formal run evidence.

## When To Capture

Capture an example when the work teaches future agents how to run the
orchestrator. Good capture candidates show one or more of these method lessons:

- choosing donor or upstream authority levels
- extracting capabilities before implementation shape
- extracting semantics before naming or file layout
- rejecting donor baggage
- reconstructing a local architecture, DSL, API, runtime boundary, adapter, or
  docs truth flow
- applying HITL gates before accepted architecture changes
- separating `.agent` workflow artifacts from durable docs
- deciding whether a draft should remain an example or be promoted to
  `knowledge/cases/`

An example can be captured before the architecture is accepted, but it must
label pending gates and unresolved validation honestly.

## When Not To Capture

Do not capture a task only because it involved code, docs, or research. Skip
example capture when the task is:

- implementation-only work against accepted architecture
- generic repo exploration with no local reconstruction target
- README cleanup, package-doc normalization, or formatting
- product writing or market/design messaging
- a chat transcript with no reusable orchestrator method lesson
- donor research that never reaches extraction, rejected baggage, or local
  reconstruction
- a formal eval fixture where the right artifact is eval evidence, not a
  teaching capture

## Promotion To `knowledge/cases/`

Promotion is optional and gated. Promote only when all criteria are true:

- Reusable method lesson is clear.
- Donors and authority levels are clear.
- Extracted capabilities are separated from rejected baggage.
- Local reconstruction is explicit.
- HITL gates are clear.
- Evidence status is honest.
- The example is not merely a chat transcript or project log.
- The example teaches future agents how to run the orchestrator.

Promotion should produce a compact curated case, not a copy of the entire
example capture. `knowledge/cases/` is for durable reusable patterns after the
Case Capture Gate, not for every draft example. Do not keep scaffolded sample
cases in `knowledge/`; create the directory and case file only as part of an
explicit promotion.

## Conversation-Derived Examples

Conversation-derived examples are allowed only as seeds. They must:

- identify the conversation or summary as the source type without embedding a
  transcript
- mark formal orchestrator run status as `no` or `unknown` unless actual
  `.agent/code-to-arch-distillation/<topic>/` evidence exists
- separate remembered intent from validated local docs or upstream evidence
- list the validation still needed before docs truth or case promotion
- avoid presenting inferred decisions as HITL-accepted truth

Use conversation-derived examples to preserve a method lesson, not to create a
retrospective run record.

## Synthetic Fixtures

Synthetic behavior fixtures are allowed when they test orchestrator behavior
without requiring access to real repos or private architecture facts. They must:

- label themselves as synthetic
- state that donor facts are fixture text, not validated upstream evidence
- avoid architecture-truth claims
- focus on expected orchestrator behavior such as gating, routing, extraction,
  baggage rejection, artifact flow, or docs destination
- remain eligible for formal eval only when paired with explicit fixture input,
  expected behavior, and run evidence

Synthetic fixtures may inform example capture, but they do not prove real-world
donor correctness.

## Avoid Transcript-Style Examples

Do not preserve historical chat in example captures. Convert source material
into operational fields:

- source inputs
- local goal
- donor authority
- extracted capabilities
- extracted semantics
- rejected baggage
- local reconstruction
- HITL gate state
- docs destination
- validation gaps
- reusable lesson
- next action

Remove incidental chronology, conversational phrasing, personal notes, and
project-log detail that does not teach the orchestrator method.

## Relation To Future `code-to-arch-distiller`

`code-to-arch` owns local truth scan coordination, donor/upstream
findings coordination, main-agent synthesis, HITL gates, docs update planning,
accepted architecture truth promotion, and optional case capture.

A future `code-to-arch-distiller` may later own per-source code, docs, tests,
and example evidence extraction. Do not create that future skill as part of
example capture. Until such a skill exists, example captures should describe
per-source evidence at the level needed to teach orchestration behavior, while
keeping final synthesis, HITL, artifact flow, and docs truth promotion in this
skill.
