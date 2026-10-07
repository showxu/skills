# Information Conservation

## What Counts As Effective Information

Preserve source material when it helps an agent:

- trigger the right skill automatically
- choose a workflow or reject a false match
- apply a decision rule or safety stop
- use a script, template, example, command, or output shape
- validate the result
- diagnose failure
- handle edge cases, permissions, live operations, or authority drift

Do not preserve material merely because it exists. Repository branding,
badges, funding files, install marketing, license files, contributor metadata,
and duplicated prose are usually `non-capability`.

For broad upstream skill-source intake, every in-scope source item must be
accounted for. "Topic already covered" is not enough by itself. A row is
handled only when the ledger records the effective information, local
destination or owner, state, reason, and authority status when applicable.

## Authoring Boundary

Use authoring and packaging rules as quality constraints, not as the
conservation model. They help check whether the local skill result is
structured well:

- **Concise is key**: compress source detail into the smallest local rule that
  keeps the behavior useful.
- **Degrees of freedom**: preserve whether the source expects flexible judgment,
  parameterized procedure, or deterministic scripts.
- **Validation integrity**: preserve concrete checks and avoid unverified claims.
- **Progressive disclosure**: keep `SKILL.md` lean; move long matrices,
  examples, and source-derived practice notes into references.
- **Support resources**: preserve scripts, templates, and assets only when they
  are reusable and have a clear owner.

`skill-distiller` adds the missing content layer:

- source capability inventory
- row-state ledger: `covered`, `compressed`, `moved`, `deferred`, `blocked`, or
  `non-capability`
- section, recipe, example, script, validation, and guardrail parity
- local destination mapping across existing skills, references, scripts,
  templates, docs, or a justified new skill
- authority and drift markers for mutable source claims

This is not permission to create a new skill by default. The target collection
decides whether existing skills, references, scripts, templates, or a new skill
should carry the result.

## Parity Standard

For structured source skills, audit:

- headings and sections
- recipes or named workflows
- examples and negative examples
- scripts and templates
- validation commands
- failure modes
- safety and confirmation rules
- trigger and manual-entry wording

For unstructured source skills, audit:

- actionable instructions
- decision rules
- guardrails
- reusable mechanics
- output expectations
- external authority claims

Information parity is not text parity. A local compressed rule can cover several
source items if it preserves the same decision or behavior and the ledger states
why the compression is safe.

## Non-Negotiable Conservation Rules

- Every in-scope capability, actionable instruction, reusable artifact, or
  failure-prevention rule gets one ledger state: `covered`, `compressed`,
  `moved`, `deferred`, `blocked`, or `non-capability`.
- The state cell is an enum. Never write multiple alternatives such as
  `covered or moved`, `compressed/deferred`, or prose conditions in the state
  cell. Resolve uncertainty into exactly one state:
  - use `blocked` when the blocker must be cleared before judging coverage
  - use `deferred` when a future owner/thread should decide or integrate it
  - use `moved` only when a destination owner is already selected
- Structured source skills require a section / recipe / guardrail parity pass.
  Record each meaningful heading, named workflow, checklist, warning, negative
  example, preferred implementation shape, validation check, and reusable
  artifact, even when several rows compress into one local rule.
- Source-specific human guardrails are capability material. They often exist to
  prevent low-quality agent output, so do not normalize them into generic
  best-practice wording unless the ledger names the concrete local equivalent.
- Code, API, CLI, or tool-name coverage is insufficient. Preserve the practice
  judgment: when to use it, when not to use it, required setup, parameters,
  confirmation gates, failure modes, validation, and fallback behavior.
- `moved` and `deferred` mean the value is retained. They require an owner or
  destination, reason, preserved evidence, and authority status when relevant.
- `blocked` requires a concrete blocker such as ownership, safety, trust,
  missing authority, unavailable tool, inaccessible source, or user scope.
- `non-capability` is limited to material that does not help the agent perform
  or decide the task. Do not use it for permission, setup, failure-mode,
  validation, or edge-case material.
- Mutable platform, API, policy, pricing, availability, and tool-behavior
  claims stay evidence-limited until verified against the target collection's
  accepted official or primary source.
- Upstream freshness, cursor movement, and review-state mutation are outside
  distillation scope. Distillation can produce a coverage receipt
  recommendation after local mapping, but it must not poll HEADs, advance
  upstream cursor fields, or mutate upstream tracking/review state.
- Public collection docs should not expose upstream repo names, source SHAs,
  upstream manifest review state, or temporary copy ledgers unless the document
  is explicitly a review ledger.

## Audit Fields

A distillation pass is incomplete until it can report:

- source item count and ledger row count
- handled rows by state
- missing rows and duplicate mappings
- compressed rows with a concrete preservation reason
- moved and deferred rows with owner, reason, and evidence
- non-skill tool/resource handover rows
- section / recipe / guardrail parity status
- authority gaps and verification followups
- proposed local destinations and validation evidence
- whether an upstream coverage receipt or cursor decision is needed after the
  user approves closeout
