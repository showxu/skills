---
name: forking-dog
description: Orchestrate HITL-governed fork/adoption work from upstream and donor sources into a local product or repository. Use for upstream intake, reference governance, donor classification, capability and semantic matrices, local architecture mapping, accept/reject/defer decisions, local truth promotion, implementation handoff, validation closeout, and multi-skill coordination for fork/adoption projects. Do not use for shallow research, copy-only vendoring, one-off code review, generic implementation without donor evidence, generic docs normalization, or skill/package creation by itself.
---

# Forking Dog

## Purpose

Drive fork, adoption, and donor-distillation work to a governed local
deliverable without copying upstream structure by inertia.

This skill owns the adoption workflow:

```text
source intake
-> donor classification
-> evidence distillation
-> capability / semantic matrix
-> local architecture mapping
-> accept / reject / defer decisions
-> local truth promotion
-> implementation handoff
-> validation closeout
```

It is an orchestrator. It does not replace lower-level skills that own
documentation normalization, donor-to-architecture distillation, CLI design,
skill authoring, or implementation planning.

## When To Use

- Adopting or forking an upstream project into a local repository.
- Comparing multiple upstream repos, donor implementations, MCP servers,
  skills, CLIs, SDKs, probes, or docs sources before local implementation.
- Maintaining a local fork while deciding which upstream capabilities,
  semantics, tests, or architecture patterns to absorb.
- Producing a durable `.agent/upstream-adoption/<topic>/` packet that a later
  planning or implementation workflow can execute.
- Closing the loop between upstream evidence, local architecture truth,
  accepted scope, docs updates, implementation plan, and validation.

## When Not To Use

- Do not use for shallow "find some repos" research with no local adoption
  target.
- Do not use to copy upstream code, file layout, naming, or product boundaries
  without local reconstruction.
- Do not use for implementation-only coding after the accepted architecture and
  plan already exist.
- Do not use for documentation normalization alone.
- Do not use for skill creation alone.
- Do not use for release automation, CI design, or generic product strategy.

## Inputs To Inspect

- User scope, target repository, explicit non-goals, and expected final product
  or artifact.
- Local truth first: `AGENTS.md`, `README.md`, docs architecture/reference
  roots, public APIs, command surfaces, generated contracts, tests, plans, and
  repository invariants.
- Workspace or repo governance for upstream refs, cloned references,
  checked-in references, generated files, and temporary `.agent/*` artifacts.
- Candidate donors: upstream repos, forks, official APIs, mature
  implementations, MCP servers, skills, docs, examples, tests, fixtures,
  package metadata, and operational evidence.
- Existing local capability inventory, architecture mapping, docs truth, and
  implementation plan if present.

## Default Artifact Root

Keep process artifacts in:

```text
.agent/upstream-adoption/<topic>/
```

Default packet:

```text
.agent/upstream-adoption/<topic>/
  README.md
  state.md
  scope.md
  refs.md
  local-truth.md
  donor-set.md
  findings/
  capability-matrix.md
  local-architecture-mapping.md
  decisions.md
  docs-promotion.md
  implementation-handoff.md
  validation-closeout.md
```

Formal docs are updated only after the docs promotion decision. Do not put raw
upstream wording, local paths, run notes, or donor comparisons into shipped
docs. Rewrite internal analysis terms such as donor, upstream, superset, parity
or "exceeds upstream" into what the product does and supports.

## Workflow

1. Scope Gate.
   - Identify target product, local repository, source set, non-goals, output
     mode, and expected closeout.
   - If scope is unclear, ask before broad collection.
2. Local Truth Scan.
   - Read local route files, README, architecture/reference docs, tests,
     generated metadata, public APIs, and current plans.
   - Record the local axes that adoption must respect.
3. Source Intake.
   - Register or inspect upstream refs according to local workspace governance.
   - Do not hand-edit governed refs metadata.
   - Record donor type, status, baseline, and reason for inclusion.
4. Donor Distillation.
   - For each donor, extract capabilities, semantics, tests, fixtures,
     runtime behavior, docs patterns, and rejected baggage.
   - Use clean-context subagents for bounded independent donor scans when
     available and useful.
5. Capability / Semantic Matrix.
   - Maintain a matrix from donor concepts to local status:
     `accepted`, `already-covered`, `partial`, `deferred`, `rejected`, or
     `out-of-scope`.
   - Track evidence, local owner, and validation for each row.
6. Local Architecture Mapping.
   - Map accepted donor concepts to local architecture axes discovered from the
     repo. Do not hardcode universal axes.
   - Preserve local product language and boundaries.
7. Boundary Gate.
   - Confirm what to absorb, reject, defer, and exclude before formal docs or
     implementation planning.
8. Docs Promotion.
   - Promote only accepted local truth to the repository's formal docs using
     the appropriate docs skill or repo convention.
   - State promoted facts in product language, without internal analysis terms.
   - Keep process evidence under `.agent/*`.
9. Implementation Handoff.
   - Produce a planning prompt or handoff for the local planning workflow.
   - Do not write implementation plans directly unless the user explicitly
     asks for that workflow.
10. Validation Closeout.
    - Record commands, checks, remaining external blockers, deferred donor
      rows, and next adoption slices.

## HITL Gates

- Scope Gate: target product, local repo, and non-goals are unclear.
- Donor Set Gate: adding or removing donors changes the adoption scope.
- Boundary Gate: accept/reject/defer decisions affect product contract or
  architecture truth.
- Docs Promotion Gate: `.agent` findings are ready to become formal docs.
- Implementation Planning Gate: architecture truth is accepted and a coding
  plan should be written.
- Execution Gate: implementation should start after planning.
- Closeout Gate: final status claims depend on live credentials, external
  services, or unrun validation.

## Skill Coordination

Use the minimal supporting skill set:

- Use workspace governance when refs or upstream metadata are governed.
- Use donor-to-architecture distillation for per-source findings and local
  architecture reconstruction.
- Use the relevant docs skill for formal documentation normalization or truth
  promotion.
- Use CLI creation guidance when the local deliverable is a durable CLI.
- Use skill creation guidance when the local deliverable includes a reusable
  skill.
- Use the local planning workflow for implementation ExecPlans.

The orchestrator links outputs. Lower-level skills do not need to know each
other exists.

## Decision Rules

- Upstream is evidence, not truth.
- Local product capability is the adoption contract.
- Copy semantics only after local reconstruction. Do not copy route shape,
  file layout, dependency graph, object model, naming, or UX unless it is
  explicitly accepted.
- Keep accepted, rejected, deferred, and out-of-scope decisions durable.
- Record why each rejected donor concept is not local product behavior.
- Treat "already covered" as a decision that still needs evidence and
  validation.
- Keep process artifacts in `.agent/*` until they are promoted.
- Do not claim donor parity when only accepted local scope is complete.
- Do not claim local implementation completeness when evidence is only a
  matrix or plan.

## Required Outputs

For a full adoption run, produce:

- adoption scope and non-goals
- source/ref inventory
- local truth scan
- per-donor findings
- capability / semantic matrix
- rejected baggage
- local architecture mapping
- accept / reject / defer decisions
- docs promotion record
- implementation handoff
- validation closeout

For a smaller run, produce the smallest subset that resolves the user's
decision without pretending the full packet exists.

## Validation

At closeout, report:

- refs validation or source access status
- matrix row counts by decision
- local architecture truth files changed or intentionally unchanged
- docs promotion status
- implementation plan handoff status
- tests, linters, contract checks, or dry runs actually executed
- remaining live-service, credential, or external blockers

## Failure / Uncertainty Handling

- If governed refs cannot be cloned or validated, keep the blocker in the
  adoption packet and do not silently replace it with ungoverned source.
- If donor evidence conflicts, inspect source before synthesizing.
- If local truth and donor behavior conflict, stop at Boundary Gate unless the
  user already gave a clear decision rule.
- If formal docs destination is unclear, keep output in `.agent/*`.
- If implementation planning is requested, hand off to the planning workflow
  with concrete scope, paths, risks, validation, and deferred rows.
