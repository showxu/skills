# Orchestrator / Distiller Contract

## Ownership Split

`any-to-skill` owns intake routing state:

- source registration in `upstreams.yaml`
- explicit input artifact identification when work starts from local or remote
  code, design, documentation, package, API documentation, or other source
  material instead of a registered upstream row
- persistent checkout resolution and refresh recommendation
- HEAD, `last_seen`, `tracking`, and `review_coverage` comparison
- `watch_paths` and `review_segments`
- source type classification
- optional source classification metadata for provenance, focus, domains, and
  absorption priority
- domain-specific artifact distiller selection when selected material is not
  skill-source but a collection has a better evidence extractor
- local owner routing based on collection docs
- human decision and cursor-movement gates
- handoff packets for distillation
- batch coordination of independent source or segment handoffs
- receipt-bundle classification after distillation
- target-skill update packets that group distiller receipts for the final
  authoring owner
- post-authoring conservation-review packets when final local results need
  receipt-backed closeout

If upstream tracking later splits out, a dedicated tracking owner can own source
discovery, persistent checkout refresh, HEAD/cursor comparison, `watch_paths`,
`review_segments`, changed-path summaries, source health, notifications,
duplicate-source consolidation, and tracking-state recommendations.
`any-to-skill` should then consume that output as routing evidence rather than
re-owning those mechanics.

`skill-distiller` owns source capability conservation:

- source item inventory after a source or segment is selected
- capability ledger rows and states
- section, recipe, example, script, validation, failure-mode, and guardrail
  parity
- tool, resource, MCP, CLI, app connector, and agent-workflow handover rows
- local destination mapping
- compression safety reasoning
- authority gaps and verification followups
- conservation receipt that `any-to-skill` can use for coverage closeout

Domain-specific artifact distillers own evidence extraction for their artifact
type. For example, `swiftpm-distiller` owns SwiftPM package and Swift library
evidence-to-skill handoff material. These distillers may run directly when the
user supplies a clear artifact and goal, or behind `any-to-skill` when source
tracking, owner routing, mixed inputs, receipt bundling, or coverage gates are
needed.

The orchestrator layer never marks a source capability as preserved by itself.
The distiller layer never advances source cursor or review-coverage fields by
itself.
Skill-creator updates must be based on distillation receipts, not raw upstream
diffs, whenever upstream material may change local skill behavior.
When a final local authoring result needs conservation review, the orchestrator
frames the review packet for `skill-distiller`. The reviewer compares the
result against accepted receipts and does not become the authoring owner.

## Artifact Root

For source-to-skill intake, `any-to-skill` sets the artifact layout
before `skill-distiller` runs. Durable intermediate artifacts belong in the
target repository:

```text
<target-repo>/.agent/skill-distillation/
```

Use this directory for distillation receipts, capability ledgers,
receipt-bundle classification packets, target-skill update packets, and
post-authoring conservation reviews tied to that target repository. First
resolve the owning git repo root, then mirror the target's real local path
relative to that repo root. Do not invent collection or skill namespaces; where
the skill lives is the artifact path. If the target skill lives at
`product-management/skills/product-requirements/` inside the owning git repo,
its artifacts live under:

```text
<target-repo>/.agent/skill-distillation/product-management/skills/product-requirements/
```

If `product-management/` is itself the owning git repo and the skill lives at
`skills/product-requirements/`, its artifacts live under:

```text
<target-repo>/.agent/skill-distillation/skills/product-requirements/
```

Collection-level artifacts mirror the real collection path, for example:

```text
<target-repo>/.agent/skill-distillation/product-management/
```

Do not use `<target-repo>/distillation/` for new artifacts.

The orchestrator handoff packet must name the artifact root and expected output paths
for each distiller pass. `skill-distiller` is passive on placement: it writes
the ledger, receipt, or conservation review to the path supplied by the
orchestrator
packet and owns only the evidence content inside that artifact.

## Handoff Packet

When `any-to-skill` hands a source or segment to `skill-distiller`, pass:

- source id
- repo and provider URL
- source type
- branch
- source commit / current HEAD
- recorded `last_seen`
- `tracking.last_checked_commit`, when present
- `review_coverage.reviewed_commit`, when present
- `classification`, when present
- checkout path or source URL
- selected `watch_paths` or `review_segments`
- changed paths or source inventory summary
- owning git repo root used for artifact placement
- target local path relative to that repo root
- expected artifact root, normally
  `<target-repo>/.agent/skill-distillation/`
- expected distiller artifact path under the mirrored target local path
- candidate local owners
- collection rules consulted
- human approval boundaries
- cursor and coverage fields that must not move automatically
- routing-grade source row kind for tool, resource, MCP, CLI, app connector,
  official-doc, or agent-workflow rows when present

Do not include local capability decisions in the handoff packet. Those belong to
`skill-distiller`. Also do not include tool/resource ledger fields such as
operations, setup/auth, output shape, safety boundary, validation path,
backend/adapter potential, owner/destination state, or preserved-evidence
analysis. Those are distiller-owned fields.

When routing to a domain-specific artifact distiller instead of
`skill-distiller`, pass the analogous routing-grade packet: artifact path or
source URL, artifact type, evidence scope, candidate local owners, collection
rules consulted, provenance or tracking fields that must stay frozen, and the
expected handoff output. The specialized distiller owns the artifact evidence
model and report body.

## Distillation Receipt

When `skill-distiller` finishes a reviewed distillation pass, it returns:

- source scope and commit
- target collection rules consulted
- source item count and ledger row count
- rows by state: `covered`, `compressed`, `moved`, `deferred`, `blocked`,
  `non-capability`
- section / recipe / guardrail parity status
- tool/resource handover status
- authority gaps
- proposed or applied local destinations
- validation evidence
- coverage state recommendation for `upstreams.yaml`

Do not treat a distillation receipt as permission to move `last_seen`.
`last_seen` moves only when the digest is acknowledged or the user explicitly
marks the source seen.
Do not treat a distillation receipt as permission to move
`review_coverage.reviewed_commit` either. Coverage movement requires human
acceptance of the receipt and, when a local skill update was needed,
human acceptance of the final authoring result and any required
post-authoring conservation review.

## Receipt Bundle Classification

Before routing receipts to a final authoring owner, classify the bundle:

- `single-existing-skill`: all accepted receipts point to one existing local
  skill and no repo, collection, naming, or route boundary changes are needed.
- `multi-existing-skills`: receipts point to multiple existing local skills,
  but each target can be updated independently and no collection boundary or
  manifest decision is required.
- `new-skill-needed`: useful capability does not fit an existing skill
  boundary and a new skill path, name, trigger contract, or scaffold decision is
  needed.
- `split-existing-skill`: receipts show one existing skill should be divided
  into multiple skills or durable trigger surfaces.
- `rename-or-move`: receipts require a skill path, name, marketplace entry,
  route stub, migration note, or documentation path change.
- `collection-boundary`: receipts affect collection taxonomy, root registry,
  cross-collection ownership, marketplace structure, or linked-checkout shape.
- `blocked-ownership`: local owner or target skill is ambiguous, conflicting,
  or missing.

For `single-existing-skill`, produce a target-skill update packet for
`skill-creator`. For `multi-existing-skills`, split the bundle into one
target-skill update packet per existing skill; use repository architecture review
only for an ownership or route decision. For `new-skill-needed`,
`split-existing-skill`, `rename-or-move`, `collection-boundary`, or
`blocked-ownership`, produce a repository architecture packet.

## Target-Skill Update Packet

When multiple distillation receipts point at the same local skill,
`any-to-skill` may consolidate them into a target-skill update packet for
`skill-creator`.

Include:

- target local skill path and candidate owner
- upstream sources, commits, segments, and checkout paths
- distillation receipt paths or summaries
- receipt counts and open blockers
- source-specific guardrails that `skill-creator` must preserve
- frozen cursor and coverage fields
- user approvals already granted and approvals still needed
- whether post-authoring conservation review is required before closeout
- recommended skill-creator entry mode: revise, harden, eval, or package

Do not include final local wording, file patches, capability ledger rows, or
coverage-state mutations in the update packet. `skill-creator` owns the
single-skill edit, trigger boundary, progressive disclosure, fixture updates,
eval flow, package preflight, and readiness decision. If receipts imply a new
skill, a split, a rename, a move, or collection-boundary changes, prepare a
repository architecture packet instead. If receipts point to multiple existing
skills without a boundary change, split them into separate target-skill update
packets.

The packet is not authorization to run skill-creator. It is the evidence bundle a
human or explicitly approved workflow can hand to skill-creator for the final
single-skill update.

## Repository Architecture Packet

When receipt classification is not `single-existing-skill` or independent
per-skill fan-out, prepare a repository architecture packet.

Include:

- receipt bundle kind
- affected skills, candidate owners, collections, and paths
- upstream source ids, commits, and selected segments
- distillation receipt paths or summaries
- why the issue is new skill, split, rename, move, collection boundary, or
  blocked ownership rather than one existing skill update
- scaffold, manifest, route stub, migration, docs, or linked-checkout decisions
  needed
- frozen cursor and coverage fields
- approvals already granted and approvals still needed

Do not include final skill wording, single-skill patches, or capability ledger
rows. Repository architecture review decides placement, naming, migration, and
repo shape; each resulting single skill still needs `skill-creator` for final
skill content and readiness.

## Post-Authoring Conservation Review Packet

After the final authoring owner returns a local result for upstream-derived
material, `any-to-skill` may request a `skill-distiller` conservation
review before using that result as closeout evidence.

Include:

- target local skill path or repository architecture result
- accepted distillation receipts and target-skill or repository architecture
  packet
- final authoring result, changed file paths, or diff summary
- receipt-row assignment map from each accepted row to the target skill,
  route stub, manifest entry, deferred owner, or other artifact that should
  preserve it
- source-specific guardrails, deferred rows, blocked rows, authority gaps, and
  validation expectations that must still be preserved
- frozen cursor and coverage fields
- the closeout question: `pass`, `needs-repair`, or `blocked`

Run the review per target skill or artifact, then summarize the bundle. A
single-skill update has one review. Multi-skill fan-out has one review per
target skill. New-skill and split flows review each resulting target skill
after `skill-creator` writes it, while collection-level artifacts such as
route stubs, manifests, docs paths, or migration notes get their own artifact
row in the assignment map.

The review checks whether each assigned receipt row is preserved,
acceptably compressed, missing, distorted, still blocked, or still deferred in
the final local result. Do not issue a vague bundle-level pass when any
accepted row lacks an assigned target and verdict. It does not judge prose
style, eval quality, packaging, or repo architecture except where those surfaces
are part of the preserved capability. A failed review returns a repair packet
to the final authoring owner. A passed review is closeout evidence only; cursor
or coverage movement still requires human acceptance through
`any-to-skill`.
