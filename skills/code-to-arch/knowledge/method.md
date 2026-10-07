# Code-to-Architecture Distillation Method

Code-to-Architecture Distillation is donor-driven framework design. It starts
from upstream projects, official APIs, donor repositories, mature community
implementations, product references, tests, fixtures, and protocol behavior,
then reconstructs the useful ideas into the local framework.

This is not copy/paste design. Upstream is evidence. Local docs decide final
architecture truth.

## Principles

- Prefer official, mature, production-proven, or strongly aligned upstreams.
- Read local truth before upstream conclusions.
- Extract semantics before implementation details.
- Extract the why and shape before extracting code.
- Preserve local repo, product, module, and runtime boundaries.
- Do not let upstream file layout, naming, runtime assumptions, dependency
  graph, or product shape automatically become local truth.
- Keep upstream notes in references unless the local architecture intentionally
  accepts or forks them.
- Produce outputs that a future Codex session can use without hidden
  conversation context.
- Support docs-only architecture work first, then later implementation planning
  when requested.

## Process

1. Read local truth first.
   Inspect `Docs/Architecture`, `Docs/Reference`, `Docs/Proposals`,
   `Docs/Decisions`, `AGENTS.md`, README indexes, public API docs, and existing
   module boundaries before forming donor conclusions.

2. Inventory upstream / donor candidates.
   List official APIs, mature implementations, product references, protocol
   docs, tests, fixtures, examples, naming sources, and anti-pattern donors.

3. Classify each donor.
   Use `upstream-taxonomy.md` to decide whether a donor contributes platform
   semantics, API shape, UX behavior, test contracts, naming, or warning
   evidence.

4. Extract reusable capabilities.
   Capture capabilities, semantics, API ergonomics, interaction models,
   fixture contracts, failure behavior, naming concepts, and architecture
   boundaries. Prefer declarative statements over copied code.

5. Identify donor baggage.
   Reject product coupling, file-layout inertia, runtime assumptions,
   deployment assumptions, dependency baggage, visual clutter, test harness
   assumptions, and names that only make sense in the donor.

6. Reconstruct local architecture.
   Decide whether the local result should be a DSL, semantic model, runtime
   abstraction, protocol/facade, adapter layer, renderer boundary, test harness,
   docs truth, or phased implementation plan.

7. Update architecture truth.
   Decide whether each output belongs in `Docs/Architecture`,
   `Docs/Reference`, `Docs/Proposals`, `Docs/Decisions`, `AGENTS.md`, README
   indexes, or an execution plan. Current truth and donor evidence should not
   be mixed without labels.

8. Recommend case capture when useful.
   When the work teaches a reusable distillation pattern, propose a Case Capture
   Gate instead of writing a curated case automatically. Before that gate is
   accepted, keep any lesson as a recommendation, example-capture draft, or
   task-scoped note. Case captures record method lessons, not chat transcripts.

## Output Standard

A complete result should name:

- local truth consulted
- donor list and classifications
- extracted capabilities and semantics
- rejected baggage
- local reconstruction pattern
- architecture truth updates
- phase / stage judgment
- risks, non-goals, and open questions
- self-contained Codex follow-up prompt

If implementation is requested later, the implementation plan must reference
architecture truth and preserve module boundaries. The method should not ask a
future agent to infer hidden context from the original conversation.
