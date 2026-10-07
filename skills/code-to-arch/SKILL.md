---
name: code-to-arch
description: Orchestrate upstream code, donor repositories, official APIs, product references, mature implementations, tests, UX patterns, protocol behavior, or per-source findings into local architecture truth, local framework boundaries, documentation update plans, and follow-up Codex prompts. Use when donor or upstream evidence must be synthesized into a local semantic model, DSL, API, architecture, docs truth, implementation plan, or case capture. Do not use for shallow repo discovery, generic research, generic refactoring, README cleanup, pure API docs, bug fixing, implementation-only coding when local architecture truth is accepted and no new donor evidence needs orchestration, generic skill-source conservation, marketplace registration, runtime implementation, or product/design decisions that are not architecture reconstruction work.
---

# Code-to-Arch

## Purpose

Use this skill to orchestrate upstream and donor evidence into local
architecture. The goal is not to copy upstream code, file layout, product
coupling, or naming. The goal is to coordinate local truth scan, donor findings,
main-agent synthesis, HITL gates, docs update planning, and approved
architecture truth promotion.

## Mandatory Artifact Flow

Before writing any distillation artifact or promoting donor evidence into durable
docs, read `knowledge/artifact-flow.md`. Default complex or donor-backed runs to
the staged workspace:

```text
.agent/code-to-arch-distillation/<topic>/
```

Use that workspace for local truth scans, per-source findings, synthesis, HITL
gate notes, and docs update plans. Do not write `Docs/Architecture` until the
Architecture Truth Gate is accepted. Do not write `Docs/Reference` just because
donor evidence exists. Donor notes, upstream inventories and source comparisons
stay in the staged workspace; shipped docs, including `Docs/Reference`, state
accepted product facts after synthesis and a docs destination decision. Rewrite
internal analysis terms such as donor, upstream, superset, parity or "exceeds
upstream" into what the product does and supports. Do not put raw upstream
wording, local paths, run notes, or donor comparisons into shipped docs.

## Future Split

- `code-to-arch-distiller` may become a lower-level evidence extraction skill
  for per-source code/docs/tests/examples analysis.
- `code-to-arch` remains the top-level workflow skill for orchestration,
  synthesis, HITL gates, docs update planning, architecture truth promotion,
  and example capture.

## When To Use

- A task starts from upstream projects, donor repositories, official APIs,
  product references, mature community implementations, fixtures, or competitor
  systems.
- The user wants capability extraction, semantics extraction, API-shape
  comparison, test-pattern extraction, UX flow extraction, or architecture
  boundary filtering.
- A local framework, DSL, architecture doc, reference doc, proposal, decision,
  README, or AGENTS.md route needs to absorb useful upstream ideas.
- A Codex follow-up prompt is needed for research, architecture review,
  implementation planning, or case capture.
- Ambiguous research or review requests include a local reconstruction goal:
  local architecture truth, local framework boundaries, docs truth, or an
  implementation plan based on accepted distillation.

## When Not To Use

- Do not use this skill to copy upstream file layout, product architecture, or
  implementation structure into the local repo.
- Do not use this for shallow "find GitHub repos" research, generic research
  summaries, normal README cleanup, simple code generation, generic refactoring,
  compile-error fixes, or bug fixing with no upstream/donor analysis.
- Do not use this for final runtime implementation unless the user explicitly
  asks for implementation after the distilled architecture is accepted.
- Do not use this for implementation-only coding when local architecture truth
  is already accepted and no new upstream/donor evidence needs to be distilled.
  Use the local coding or planning workflow instead.
- Do not use this to write repo-local `PLAN.md`, ExecPlan, or implementation
  plan artifacts. This skill may produce architecture-derived implementation
  notes or follow-up prompts after donor distillation; durable implementation
  plan artifacts belong to the local planning workflow.
- Do not use this for package documentation normalization, Swift package docs
  routing, product writing, repo health checking, simple skill creation, or
  skill-source conservation unless donor/upstream evidence must become local
  architecture truth.
- Do not use this for generic skill-source conservation or skill package
  hardening. That is a separate skill-authoring workflow.
- Do not use this for product strategy, market messaging, visual design critique,
  or store operations unless the current output is local software architecture.

## Inputs To Inspect

- Local architecture truth first: `Docs/Architecture`, `Docs/Reference`,
  `Docs/Proposals`, `Docs/Decisions`, `AGENTS.md`, README indexes, package
  docs, and public API docs.
- Candidate upstreams and donors: official APIs, mature implementations,
  donor repos, protocol docs, product references, fixtures, tests, examples,
  and anti-patterns.
- Existing local module boundaries, dependency graph, naming, tests, runtime
  layers, and documentation indexes.

## Workflow

Use the **Code-to-Architecture Distillation** workflow:

1. Artifact flow check: read `knowledge/artifact-flow.md`, choose the staged
   `.agent/code-to-arch-distillation/<topic>/` workspace or explicitly state why
   the run is small enough to return findings inline.
2. Local truth scan: read current local architecture, reference docs, proposals,
   decisions, route files, public API docs, module boundaries, tests, and
   existing plans before accepting donor conclusions.
3. Upstream intake: identify candidate donors, classify source type, and record
   why each donor matters.
4. Capability / semantics extraction: extract capabilities, semantics, API
   ergonomics, interaction models, tests, fixtures, naming, and architectural
   boundaries before implementation details.
5. Boundary filtering: reject donor baggage, product coupling, runtime
   assumptions, dependency baggage, file-layout inertia, and naming that does
   not clarify local concepts.
6. Local framework reconstruction: rebuild the accepted ideas into the local
   semantic model, DSL, API, architecture, runtime layer, adapter, renderer, or
   docs structure.
7. Architecture truth update: decide which local docs become current truth,
   reference evidence, proposals, decisions, or execution plans.
8. Example or case capture recommendation: preserve reusable method lessons and
   follow-up prompts without turning the artifact into a chat transcript,
   architecture truth, formal eval proof, or curated case before the Case
   Capture Gate.

For complex distillation, use the orchestration flow:

```text
Scope / Goal Gate
-> Local repo truth scan
+ Upstream repo/docs/examples/tests scan
-> Per-source findings
-> Main-agent synthesis
-> Boundary Gate
-> Local Reconstruction Gate
-> Architecture Truth Gate
-> Docs/Architecture update
-> Optional Docs/Reference promotion
-> Optional case capture
```

Use single-agent mode for small tasks or one donor. Default to subagent mode for
clearly scoped evidence collection when the task includes multiple donor
categories, mixed source types, or parallel evidence gathering, subject to host
capability and user/system policy. Do not ask a separate HITL question only to
dispatch bounded collection subagents when the collection scope is already
clear. Subagents collect evidence, extraction, and risk; the main agent performs
synthesis, local reconstruction, and final architecture truth updates. Do not
let subagents directly edit `Docs/Architecture`.

For subagent mode, prefer `gpt-5.3-codex` with `xhigh` reasoning effort when
the host supports explicit model and effort selection. If that runtime is not
available, continue with the host default and preserve the same role boundaries.
When multiple donor/source questions are independent, dispatch the focused
subagent briefs in parallel. Keep main-agent synthesis, HITL decisions, docs
destination choices, and architecture truth updates serial in the main context.

Use HITL before material scope, boundary, or architecture-truth decisions. Do
not wait until final docs edits if the goal itself is ambiguous. Goal unclear:
ask at Scope / Goal Gate before running the distillation. Boundary unclear:
stop at Boundary Gate before local reconstruction. Truth unclear: stop at
Architecture Truth Gate before editing `Docs/Architecture`. Do not ask after
every minor step.

When asking Scope / Goal Gate, do not force the user to choose exactly one
target. Ask for the primary target, secondary targets, explicit non-goals, and
output mode: gate decision only, dry-run workspace, docs update plan, or
implementation plan.

## Required Outputs

Every run should produce the smallest useful set of these outputs:

- donor classification and evidence summary
- extracted capabilities and semantics
- rejected baggage and boundary risks
- local framework reconstruction recommendation
- architecture truth update plan or docs edits
- phase / stage judgment
- risks and non-goals
- Codex follow-up prompt for research, architecture review, implementation, or
  case capture
- example-capture or case-capture recommendation when the work teaches a
  reusable method lesson

Place these outputs according to `knowledge/artifact-flow.md`: staged `.agent`
artifacts first for complex or donor-backed work, then durable docs only after
the relevant HITL gate and destination decision.

## Rules For Avoiding Shallow Copying

- Extract semantics before code.
- Extract capability, API ergonomics, fixtures, and interaction behavior before
  file layout or naming.
- Treat upstream as evidence, not local truth.
- Preserve local repo, module, product, and runtime boundaries.
- Do not let one donor's dependency graph, host assumptions, or product shape
  define the local framework unless the user explicitly accepts that decision.
- Prefer reconstructing a local API, DSL, facade, runtime abstraction, test
  harness, or docs truth over importing donor structure.

## Rules For Example And Case Capture

- Use `templates/example-capture.md.tpl` for structured teaching artifacts
  that may later become formal cases.
- Use `references/example-capture-guide.md` to distinguish example capture,
  dry-run artifacts, formal eval proof, architecture truth, and knowledge
  cases.
- Do not treat example captures as architecture truth, formal eval proof, or
  `knowledge/cases/` entries by default.
- Do not claim a conversation-derived or summary-derived example was produced
  by a formal orchestrator run unless actual run evidence exists.
- Capture only when the work teaches donor selection, extraction, rejected
  baggage, local reconstruction, HITL, artifact flow, or docs truth flow.
- Keep example captures compact, concrete, and operational.
- Do not create `knowledge/cases/` or curated case files by default. Create
  them only after an explicit Case Capture Gate and durable method value are
  clear.
- Use `templates/case-capture.md.tpl` only when the user explicitly asks for a
  curated reusable case after the Case Capture Gate.

## Reference Files

- `knowledge/method.md`: detailed method and process.
- `knowledge/upstream-taxonomy.md`: donor categories and inspection questions.
- `knowledge/boundary-rules.md`: boundary filtering rules.
- `knowledge/reconstruction-patterns.md`: common local reconstruction patterns.
- `knowledge/orchestration.md`: single-agent, subagent, and HITL execution
  modes.
- `knowledge/hitl-gates.md`: scope, donor-set, boundary, reconstruction,
  architecture truth, and case-capture gates.
- `knowledge/subagent-roles.md`: standard evidence collection roles and
  subagent boundaries.
- `knowledge/artifact-flow.md`: mandatory before file writes or docs promotion;
  defines findings, synthesis, docs, and case-capture artifact destinations.
- `references/example-capture-guide.md`: policy for example captures, dry-run
  artifacts, formal eval proof, architecture truth, and knowledge cases.
- `references/eval-fixtures.md`: durable behavior fixtures for trigger,
  boundary, docs-truth, and case-capture regression checks.
- `templates/`: intake, research, review, implementation-plan, and case-capture
  prompt templates, plus example-capture, subagent brief, findings report, and
  synthesis report templates.
- `checklists/`: donor evaluation, boundary filtering, local framework design,
  and docs truth update checks.

## Validation Rules

- Confirm `knowledge/artifact-flow.md` was read before writing distillation
  artifacts or promoting docs.
- Confirm complex or donor-backed runs used
  `.agent/code-to-arch-distillation/<topic>/`, or record why inline output was
  sufficient.
- Confirm local truth was read before donor conclusions were accepted.
- Confirm each donor has a classification and a reason to inspect it.
- Confirm extracted ideas are separated from rejected baggage.
- Confirm the final recommendation names local boundaries and docs truth.
- Confirm generated Codex prompts are self-contained and do not rely on hidden
  conversation context.
- Confirm findings are produced before synthesis, synthesis before architecture
  truth, and HITL before accepted architecture changes.

## Output Format

For research or design work, return a compact report with:

- phase / stage judgment
- local truth consulted
- donors inspected and classifications
- extracted capabilities
- rejected baggage
- local reconstruction recommendation
- architecture truth updates
- risks, non-goals, and open questions
- next Codex prompt

For approved docs edits, make the scoped changes and report validation status.
