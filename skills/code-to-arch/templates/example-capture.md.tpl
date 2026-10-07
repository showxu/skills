# Example Capture: <Name>

## Example Type

Choose one or more:

- Real dry-run artifact
- Accepted architecture example
- Conversation-derived seed
- Codex-summary-derived seed
- Repo-docs-derived example
- Upstream-evidence-derived example
- Synthetic behavior fixture
- Other: <explain>

## Evidence Status

State exactly what is known and what is not known.

Required fields:

- Formal orchestrator run: yes / no / unknown
- Local repo docs validated: yes / no / partial
- Upstream evidence validated: yes / no / partial
- HITL accepted: yes / no / pending
- Architecture truth updated: yes / no / pending
- Publication-level eval proof: yes / no

Required rule:

Do not claim a conversation-derived or summary-derived example was produced by
a formal `code-to-arch` run unless there is actual run evidence.

## Source Inputs

List available inputs:

- Local repo README / AGENTS
- Local `Docs/Architecture`
- Local `Docs/Reference`
- Local `Docs/Proposals`
- Local `Docs/Decisions`
- Local `.agent/code-to-arch-distillation/<topic>/` artifacts
- Other `.agent` plans or reports
- Codex execution summary
- User-provided discussion summary
- Upstream / donor repo
- Official documentation
- Tests / fixtures / examples
- Synthetic fixture text

## Why This Is A Code-to-Architecture Orchestration Example

Explain why this is not generic research, implementation-only work, README
cleanup, or product writing.

The explanation should name the pattern:

```text
donor/upstream evidence
→ extracted capability / semantics
→ rejected baggage
→ local reconstruction
→ HITL / docs truth flow
```

## Local Goal

State the local architecture or framework goal.

Examples:

- Define runtime boundary.
- Define DSL/API shape.
- Separate production runtime from testing/benchmark layer.
- Reconstruct endpoint/gateway/relay boundaries.
- Align docs truth after upstream evidence.
- Plan implementation from accepted architecture.

## Donors / Upstreams

For each donor, include:

- Donor:
  - Donor type:
  - Authority level:
  - What to extract:
  - What to avoid:
  - Evidence status:

Donor types may include:

- official platform/API donor
- official package/library donor
- mature community implementation
- product/UX donor
- protocol/API donor
- test/fixture donor
- naming/documentation donor
- anti-pattern donor

## Extracted Capabilities

List reusable capabilities extracted from donors.

## Extracted Semantics

List reusable semantic models, domain concepts, state models, API meanings,
runtime behaviors, or UX meanings.

## Rejected Baggage

List donor assumptions that should not become local architecture.

Examples:

- product-specific coupling
- donor file layout
- donor dependency graph
- accidental implementation shape
- unstable public API
- donor-specific naming
- visual clutter
- test harness assumptions
- premature runtime complexity

## Local Reconstruction

Explain how extracted ideas become the user's local framework, architecture,
DSL, runtime layer, adapter, product surface, or docs truth.

## HITL Gates That Matter

List relevant gates and whether they are pending, accepted, rejected, or not
applicable.

Use these gate names:

- Scope / Goal Gate
- Donor Set Gate
- Boundary Gate
- Local Reconstruction Gate
- Architecture Truth Gate
- Docs Destination Gate
- Case Capture Gate

For each gate:

- Gate:
  - Status:
  - Decision needed:
  - Safe default:
  - Blocked until answered:

## Architecture Truth Candidates

List conclusions that may become `Docs/Architecture` truth after HITL.

Do not present them as accepted truth unless they are already accepted.

## Artifact / Docs Destination

Specify what belongs where:

`.agent/code-to-arch-distillation/<topic>/`

Task-scoped workflow artifacts. Not architecture truth.

`Docs/Reference/*`

Durable donor evidence, upstream inventories, compatibility notes, or reference
summaries.

`Docs/Proposals/*`

Design-in-progress when reconstruction is not accepted yet.

`Docs/Architecture/*`

Accepted local architecture truth only after synthesis and required HITL gates.

`Docs/Decisions/*`

Accepted architectural decisions and tradeoff records.

Future `knowledge/cases/*`

Curated reusable skill cases only after explicit promotion. Do not create
scaffolded sample cases by default.

## What Still Needs Validation

List missing evidence or unresolved checks.

Examples:

- local repo docs need validation
- upstream repo evidence needs validation
- official docs need validation
- HITL decision pending
- implementation impact unknown
- docs destination unclear

## Promotion Criteria

State what must be true before this example can be promoted to
`knowledge/cases/`.

Required criteria:

- Reusable method lesson is clear.
- Donors and authority levels are clear.
- Extracted capabilities are separated from rejected baggage.
- Local reconstruction is explicit.
- HITL gates are clear.
- Evidence status is honest.
- The example is not merely a chat transcript or project log.
- The example teaches future agents how to run the orchestrator.

## Reusable Lesson

State the generalized lesson.

Use this form:

When <kind of donor situation>, use `code-to-arch` to
<orchestration pattern>, while avoiding <baggage pattern>.

## Follow-up Prompt / Next Action

Include a self-contained next action.

Examples:

- validate against local repo docs
- run a dry-run workspace
- promote accepted reference facts to `Docs/Reference`
- update `Docs/Architecture` after HITL
- convert to knowledge case
- do not promote yet
