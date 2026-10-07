---
name: any-to-skill
description: Route selected upstreams and input artifacts toward skill distillation or authoring by producing source digests, routing proposals, cursor comparisons, segment summaries, distiller handoff queues, receipt-bundle classifications, target-skill update packets, conservation-review gates, and tracking-state recommendations. Use for upstream skill-source, curated-index, signal-source, MCP/tool/resource, official-doc, workflow-prompt, code, design, documentation, package, or skill-source inputs before a skill update. Do not use for capability extraction, final single-skill edits, trigger hardening, evals, packaging, or repository architecture changes.
---

# Any-to-Skill

## Purpose

Use this skill for the skill-intake routing layer of the skills monorepo. It
routes selected upstreams and other input artifacts toward the correct
distillation, authoring, or collection decision owner. It answers:

- Which registered source changed?
- Which explicit input artifact, such as code, design, documentation, package,
  or skill-source material, should be routed?
- What source type and paths changed?
- What optional source classification metadata means for intake priority and
  routing?
- Which local collection or owner should inspect it?
- What digest, plan, or human decision is needed?
- Which `upstreams.yaml` cursor or review field may move, and when?
- Which distiller receipts should be grouped into one target-skill update packet?
- Which receipt bundle kind determines the final authoring route?
- Whether a final authoring result needs conservation review before closeout?

It does not integrate upstream skill content, deeply distill arbitrary
artifacts, or author final skill files. When the task becomes "what useful
skill behavior should be preserved locally, and how", hand off skill-source
material to `skill-distiller`. When a collection provides a specialized
artifact distiller, such as `swiftpm-distiller`, route non-skill-source
evidence there.

For multiple upstream changes or mixed input artifacts, this skill may
coordinate the orchestration side of the batch: slice independent sources or
segments, select the right distiller owner, prepare handoff packets, classify
receipt bundles, and consolidate distiller receipts by target skill.
`skill-distiller` is the required evidence layer before any `skill-creator` update
packet for skill-source, prompt, workflow, tool, resource, MCP, CLI, app
connector, official-doc, or agent-workflow material. Domain-specific artifact
distillers may provide the evidence layer for their own non-skill-source input
type. The final local skill update belongs to `skill-creator` for one
existing target skill. If receipts point to
multiple existing skills without a boundary change, split them into one packet
per target skill. If receipts imply a new skill, split, rename, move, or
collection-boundary change, prepare a repository architecture packet.

After the final authoring owner produces a result, this skill may coordinate a
post-authoring conservation review through `skill-distiller` before closeout.
The review compares the authoring result against accepted distiller receipts
and update packets; it is not a second authoring pass and does not require the
reviewer to own the single-skill editing workflow.

## Workflow

1. Identify whether the task starts from a registered upstream source or an
   explicit local/remote input artifact. For registered upstreams, read root
   `upstreams.yaml` and the relevant root or source routing docs. For explicit
   code, design, documentation, package, or other artifacts, read the relevant
   local routing docs before selecting a distiller or authoring owner.
2. Resolve a persistent registered-source checkout from the explicit source
   location or the owning workspace's current reference registry and contract.
   Use its authorized checkout-management facility when materialization or
   refresh is needed. Preserve the checkout, branch and local work during fetch;
   fetching does not advance reviewed adoption. Outside a managed workspace,
   use the source URL or another explicit persistent checkout. Do not create
   temporary clones when a registered persistent checkout is available.
3. Compare the source branch HEAD with `last_seen` and, when present,
   `tracking.last_checked_commit` and `review_coverage.reviewed_commit`.
4. Filter or summarize by literal `watch_paths` and `review_segments`.
   Distinguish segment scope from source scope. A segment digest or receipt can
   close only that segment. Source-level closeout requires a source-wide
   inventory that accounts for watched paths, declared segments, and obvious
   untracked in-scope directories or artifacts in the checkout.
5. Classify the source or changed rows by `source-types.md` and interpret
   optional `classification` metadata with
   `references/upstream-classification.md`.
6. Route by local collection ownership. Treat `targets` in `upstreams.yaml` as
   hints only; local `AGENTS.md`, README, and authoring docs decide ownership.
7. Produce a compact digest, route recommendation, scoped intake plan, distiller
   handoff queue, or target-skill update packet. Do not edit local skills from
   this skill. When proposing target-repo distillation artifacts,
   use `<target-repo>/.agent/skill-distillation/` rather than a
   root-level `distillation/` directory. Resolve the owning git repo root, then
   mirror the target's real local path relative to that repo root. Whether that
   path segment is a collection, skill, package, or category directory does not
   change the artifact path. The orchestrator handoff owns the artifact root and
   expected output paths; `skill-distiller` writes evidence artifacts to the
   supplied paths.
8. When source rows are skill-source material that need capability extraction,
   hand off to `skill-distiller` with the source id, checkout path, changed
   paths, candidate owners, and any plan rows already created. When the selected
   input is non-skill-source evidence and a specialized artifact distiller
   exists, route to that distiller with the artifact path, evidence scope,
   candidate owners, and frozen tracking or provenance fields.
   Use `references/orchestrator-distiller-contract.md` for the exact handoff packet.
   For independent sources or literal segments, the orchestrator pass may prepare
   multiple distiller handoff packets. Actually running `skill-distiller` passes
   requires explicit approval in the current request. Each pass must return a
   distillation receipt.
9. Classify the distillation receipt bundle:
   - `single-existing-skill`: produce one target-skill update packet for
     `skill-creator`.
   - `multi-existing-skills`: split into one target-skill update packet per
     existing skill; use repository architecture review only when ownership or
     routing is ambiguous.
   - `new-skill-needed`, `split-existing-skill`, `rename-or-move`, or
     `collection-boundary`: produce a repository architecture packet.
   - `blocked-ownership`: stop with the owner conflict and required decision.
10. When final authoring returns a local result for upstream-derived material,
    prepare a post-authoring conservation-review packet for `skill-distiller`
    that compares that result against the accepted receipts. Running that
    review requires explicit approval unless the current request already
    granted it.
11. Treat a passed conservation review as evidence for closeout, not as
    automatic permission to move tracking state. Before recommending
    source-level `review_coverage` as `reviewed`, `integrated`, or
    `open_items: 0`, verify that a source-wide inventory exists. If only
    selected segments were reviewed, recommend segment-level movement only and
    keep the source-level state `partial` or otherwise open.

## HITL Decision Flow

When an orchestrator pass detects relevant source changes, do not infer
permission to continue into capability extraction or local skill updates. Return
pending decisions when approval is missing:

- run `skill-distiller` for selected sources or segments?
- classify the receipt bundle as single-skill, per-skill fan-out, collection
  routing, or blocked ownership?
- send accepted distiller receipts to `skill-creator` for one existing
  target skill?
- prepare a repository architecture packet because receipts require new skill,
  split, rename, move, marketplace, or collection-boundary decisions?
- run a post-authoring conservation review against the final local result?
- accept the final authoring result and conservation review as the local review
  receipt?
- move `last_seen` or `review_coverage.reviewed_commit` to a specific commit?

`skill-creator` must consume distillation receipts, not raw upstream diffs.
Use raw diffs only to form source/input digests and distiller handoffs.

## Source Handling

- `skill-source`: route the source and identify changed skill paths. Use
  `skill-distiller` for capability ledger, information conservation, section
  parity, compression, and handover audit.
- `curated-index`: treat as discovery only. Follow original linked
  repositories before recommending integration.
- `signal-source`: extract topics or verification questions only. Mutable facts
  need primary or official verification before becoming local guidance.
- MCP, CLI, app connector, tool, official-doc, resource, or agent-workflow rows:
  classify the row and pass only routing-grade facts through the handoff
  packet: source id, path, kind, candidate owner, and why it is not direct
  skill prose. Do not record operations, setup/auth, output shape, safety,
  validation, backend potential, or handover state here; those are
  `skill-distiller` ledger fields.
- `skill-distiller` is the skill-source to local-skill conservation layer for
  upstream skills, prompts, workflows, and copied skill material.
- Domain-specific artifact distillers may own non-skill-source evidence
  extraction before final skill authoring when a collection already provides
  one. For example, `swiftpm-distiller` owns SwiftPM package and Swift library
  evidence-to-skill handoff material. Treat these as specialized distillation
  owners, not upstream tracking owners. These artifact distillers may be
  invoked directly when the user already knows the input artifact and desired
  output, or routed through `any-to-skill` when source discovery, tracking,
  owner routing, or cross-source receipt bundling is needed.

Read `references/source-types.md` for row-kind rules and
`references/upstream-classification.md` for optional source provenance, focus,
domain, and absorption-priority metadata.

## Tracking State

`upstreams.yaml` owns durable source-tracking state:

- `repo`: GitHub `owner/name`.
- `branch`: branch to inspect.
- `feed`: optional Atom URL.
- `last_seen`: cursor for commits that should not be reported as new. Do not
  treat it as proof of review coverage.
- `tracking.last_checked_commit`: freshness evidence that a digest checked a
  commit. This can move after a read-only digest.
- `review_coverage.reviewed_commit`: review evidence for a declared source or
  segment scope. This moves only after the scope was classified, deferred,
  moved, integrated, or closed.
- `watch_paths`: literal changed-path filters.
- `review_segments`: stable literal review units for broad sources.
- `classification`: optional source-routing metadata owned by this skill. It
  records provenance, source focus, local domains, and absorption priority; it
  does not prove review coverage or local capability preservation.

Materialized checkouts are inspection caches, not review state. Cloning,
syncing, or workspace-refs registration does not advance `last_seen`,
`tracking.last_checked_commit`, or `review_coverage.reviewed_commit` by itself.

Source-level review coverage is stronger than segment coverage. Do not mark a
source-level row `reviewed`, `integrated`, or `open_items: 0` merely because all
currently declared `review_segments` are closed. Source-level closeout requires
one of these proofs:

- the source is narrow and the declared `watch_paths` cover the full relevant
  source surface
- a source-wide inventory receipt lists tracked in-scope segments, untracked
  in-scope segments, out-of-scope paths, deferred paths, and moved paths
- the human explicitly constrains the source-level claim to a named subset and
  the manifest keeps source-level coverage `partial` for unreviewed material

When a broad source has untracked but obviously relevant directories, add or
recommend stable literal `review_segments` for them and keep source-level
`open_items` above zero. Final summaries must say "tracked segments complete"
instead of "source complete" unless source-wide inventory proof exists.

Update `last_seen` only after the digest has been reviewed or the user
explicitly asks to mark it seen.

Use the helper for current manifest state:

```bash
skills/any-to-skill/scripts/upstream-status --root .
```

## Human Approval Boundary

An orchestrator pass may:

- poll feeds or HEADs
- compare HEAD with cursors
- classify changed paths
- route candidates
- create digest reports or scoped intake plans
- prepare distiller handoff queues and target-skill update packets
- classify receipt bundles and prepare repository architecture packets
- prepare post-authoring conservation-review packets
- update `tracking.last_checked_commit` only when explicitly allowed by the
  current request and tied to a durable digest or receipt

An orchestrator pass must not do without explicit user confirmation:

- run `skill-distiller` for capability extraction
- run post-authoring conservation review
- run `skill-creator` for local skill edits
- edit local skill files
- perform final single-skill updates, trigger hardening, evals, or packaging
- add, remove, split, or rename skills
- change trigger boundaries
- change root marketplace files or source manifests
- advance `last_seen` after an unreviewed proposal
- mark `review_coverage.reviewed_commit` without a concrete review receipt

## Validation

- Every source in `upstreams.yaml` needs `id`, `repo`, `branch`, `last_seen`,
  `type`, `targets`, and `policy`.
- `type` must be `skill-source`, `curated-index`, or `signal-source`.
- `classification`, when present, must follow
  `references/upstream-classification.md`.
- `review_segments`, when present, must use literal paths.
- Full-source or mixed-input intake plans are temporary execution queues.
  Durable closeout state belongs back in `upstreams.yaml` or accepted target
  repository receipts.
- Source-level closeout recommendations must include a source inventory or a
  reason the source is narrow enough that declared watched paths equal the full
  relevant source. Segment closeout recommendations must not be worded as
  whole-source closeout.
- Orchestration plans must not contain the deep evidence ledger itself. They
  contain source/input inventory, route evidence, approval gates, and distiller
  handoff packets. Skill-source capability ledgers live in `skill-distiller`
  artifacts; non-skill-source evidence reports belong to the selected
  artifact distiller.
- Receipt bundles must be classified before routing to final authoring:
  `single-existing-skill`, `multi-existing-skills`, `new-skill-needed`,
  `split-existing-skill`, `rename-or-move`, `collection-boundary`, or
  `blocked-ownership`.
- Target-skill update packets must contain distiller receipt summaries, source
  state, frozen cursor fields, candidate target skill, approval gates, and any
  required post-authoring conservation-review gate. They must not contain final
  local wording or direct file patches.
- Collection-routing packets must explain the bundle kind, affected skills or
  collections, receipt evidence, and scaffold, manifest, route, or migration
  decisions needed.
- Moving `last_seen` requires human acknowledgement of the digest. Moving
  `review_coverage.reviewed_commit` requires human acceptance of concrete
  distiller receipts, final authoring receipts, and any required
  post-authoring conservation review.
- Source-level `review_coverage` movement requires source-wide inventory proof
  in addition to accepted segment receipts. Without that proof, move only the
  completed segment rows and keep the source row `partial` with explicit open
  items for unreviewed in-scope paths.
- For downstream collection-boundary or manifest edits, include a validation
  gate in the handoff packet. The downstream owner, not this orchestrator, runs
  the repository's declared validation after applying approved edits.

When changing trigger wording, tracking state semantics, literal segment rules,
or distiller handoff boundaries, read `references/eval-fixtures.md` and rerun
representative fixtures before landing the change. Keep formal eval outputs in
the eval workspace or review surface as `review.html`, `benchmark.json`,
`feedback.json`, transcripts, and raw outputs. Do not add a skill-local
eval artifact log.

## Output

Return a compact digest with:

- source id, repo, type, branch, recorded cursor, and current HEAD
- changed paths or segment summary
- candidate local owner and routing evidence consulted
- recommended action: `ignore`, `watch`, `inspect-original`, `compare`,
  `handover`, `distill`, `proposal`, or `blocked`
- whether `skill-distiller` is needed
- receipt bundle kind and whether `skill-creator`, repository architecture
  review, or per-skill fan-out owns the final update path
- whether post-authoring conservation review is needed before closeout
- cursor or coverage fields that must stay unchanged
- source-level versus segment-level closeout scope, including whether
  source-wide inventory proof exists
- human decisions needed before mutation
