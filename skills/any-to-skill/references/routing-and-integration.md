# Routing And Intake

## Routing Order

1. Identify whether the task starts from a registered upstream row or from an
   explicit input artifact.
2. For registered upstream rows, use `targets` and optional `classification`
   in `upstreams.yaml` only as hints.
3. For explicit artifacts, identify the artifact type first: skill-source,
   codebase, SwiftPM package, design artifact, documentation/wiki, API docs,
   tool, or resource.
4. Identify plausible local owners by subject, workflow, safety boundary,
   output shape, and existing skills.
5. Read the target repo's `AGENTS.md`, README, and authoring docs.
6. If mutable external facts are involved, require the target owner's
   official or primary-source authority gate.
7. Recommend a route, handoff, digest, intake plan, or block.

Upstream metadata can explain where a source was noticed, why it is important,
and which domains may inspect it first. It does not decide local ownership.

## Batch Coordination

When several upstream sources, review segments, or explicit input artifacts can
affect the same local skill, `any-to-skill` may coordinate the
orchestration-side batch:

- split the batch into independent literal sources or segments
- prepare one `skill-distiller` or specialized artifact-distiller handoff
  packet per independent slice
- keep cursor and review fields frozen during evidence collection
- collect distiller receipts
- classify the receipt bundle before choosing the final authoring route
- group receipts by target local skill when they can be updated independently
- produce target-skill update packets or a repository architecture packet
- request `skill-distiller` post-authoring conservation review when a final
  local result needs receipt-backed closeout

This coordination is not permission to make local skill edits. Use
`skill-creator` for the final update to one existing target skill. Split
multi-existing-skill bundles into per-skill packets when no collection decision
is needed. Use repository architecture review as the reference surface when
receipts imply a new skill, a skill split, rename, move, marketplace changes,
ownership conflict, or collection-boundary changes.

When approval is missing, stop at the next decision packet instead of advancing
the workflow. Common decision packets are:

- whether to run `skill-distiller` for selected sources or segments
- how to classify the receipt bundle after distillation
- whether to send accepted distiller receipts to `skill-creator`
- whether a receipt bundle needs repository architecture review
- whether to run post-authoring conservation review
- whether to accept the final authoring result and conservation review as a
  review receipt
- whether to move `last_seen` or `review_coverage.reviewed_commit`

## Source-Level Closeout Guard

Treat source-level closeout as a separate claim from segment closeout.

A segment receipt, bundle classification, and post-authoring conservation
review can close only the selected literal segment. They do not prove that the
whole upstream source has no other useful local capability.

Before recommending source-level `review_coverage.status` as `reviewed` or
`integrated`, or source-level `open_items: 0`, require one of:

- a source-wide inventory receipt that lists tracked segments, untracked but
  in-scope segments, out-of-scope paths, deferred paths, moved paths, and
  blocked paths
- proof that the source is narrow and all relevant source material is covered
  by declared `watch_paths` and `review_segments`
- an explicit human-scoped statement that the closeout claim applies only to a
  named subset, while the source row stays `partial`

If a broad source has untracked but obviously relevant directories, add or
recommend stable literal review segments and leave source-level coverage
`partial` with open items. Final summaries must say "tracked segment complete"
or "selected subset complete" rather than "source complete".

## Receipt Bundle Classification

Classify accepted distiller receipts before final authoring:

| Bundle kind | Route |
| --- | --- |
| `single-existing-skill` | One target-skill update packet to `skill-creator`. |
| `multi-existing-skills` | One target-skill update packet per existing skill; use repository architecture review only for ownership or route ambiguity. |
| `new-skill-needed` | Repository architecture packet for path, name, scaffold, and manifest decisions. |
| `split-existing-skill` | Repository architecture packet for split, migration, route stubs, and per-skill handoffs. |
| `rename-or-move` | Repository architecture packet for path/name/manifest/docs migration. |
| `collection-boundary` | Repository architecture packet for taxonomy, root registry, linked-checkout, or cross-collection ownership decisions. |
| `blocked-ownership` | Stop with the conflict, candidate owners, and the human or collection decision needed. |

## Handoff To Skill Distiller

Use `skill-distiller` when the source is actual skill material and the user asks
to distill, compare capability coverage, preserve useful behavior, or prepare a
local integration proposal.

The handoff should include:

- source id, repo, branch, commit, and checkout path
- changed upstream paths or selected review segment
- candidate local owners and collection rules consulted
- source type and any tool/resource rows that need explicit handling
- current cursor and review coverage fields that must not move automatically
- whether a temporary `PLAN.md` already exists

For the full packet and receipt contract, use
`references/orchestrator-distiller-contract.md`.

`any-to-skill` owns the source queue and route. `skill-distiller` owns
the information-conservation ledger and local capability mapping.
Store target-repo skill-source distillation receipts and review artifacts under
`<target-repo>/.agent/skill-distillation/`, mirroring the target's real local
path relative to the owning git repo root.

When a specialized artifact-to-skill distiller exists, such as
`swiftpm-distiller` for SwiftPM package evidence, route to it for the
artifact-specific evidence pass. It may also be used directly when the user
already provides the artifact and goal. Use `any-to-skill` around it when the
task needs upstream tracking state, mixed-source routing, owner decisions, or
receipt bundle coordination.

## Handoff To Skill Creator

Use `skill-creator` when one target skill needs to absorb one or more
distiller receipts.

Do not route raw upstream diffs directly to `skill-creator` for local skill
updates. Capability extraction must pass through `skill-distiller` first unless
the task is only a freshness digest and no local update is being considered.

The update packet should include:

- target skill path and current owner
- source ids, commits, and selected paths or segments
- distiller receipt summaries and open blockers
- source-specific guardrails to preserve
- expected edits by surface: `SKILL.md`, `references/`, `scripts/`,
  `templates/`, `agents/openai.yaml`, or fixtures
- validation and eval expectations
- cursor and review coverage fields that must not move automatically

The packet should not include final local wording or patches. Skill-creator owns
the single-skill trigger contract, progressive disclosure, HITL boundaries,
fixture updates, eval flow, validation, package readiness, and final edit
quality.

After skill-creator returns a result for upstream-derived material,
`any-to-skill` should prepare a `skill-distiller` post-authoring
conservation-review packet when the receipts carried guardrails, recipes,
validation checks, authority gaps, deferred rows, or blocked rows that could be
lost during compression. The review asks whether the final local result
preserves the accepted receipt evidence. Run this review per target skill or
artifact and summarize the bundle; every accepted receipt row needs an assigned
target and verdict. Failures go back to the final authoring owner for repair.

## Repository Architecture Packet

Use repository architecture review as the reference surface when receipt
bundle classification shows a new skill, split, rename, move,
collection-boundary change, or blocked ownership.

The repository architecture packet should include:

- receipt bundle kind
- affected skills, candidate owners, collections, and paths
- source ids, commits, selected paths or segments, and receipt summaries
- why the issue is not a single existing skill update
- scaffold, manifest, route-stub, migration, docs, or linked-checkout decisions
  needed
- cursor and review coverage fields that must not move automatically

The packet should not include final local skill wording or patches.
Repository architecture review owns placement, naming, migration, and repo
shape. Any resulting single-skill content still routes to `skill-creator`.

## Full-Source / Mixed-Input Intake Plans

For whole-repository review, broad integration, or cross-collection intake,
create a scoped temporary `PLAN.md` before local edits. The plan is not
architecture truth and must not outlive closeout unless the user asks to keep
it.

Use the smallest owner:

- root `PLAN.md` for cross-surface sources, mixed inputs, or manifest
  decisions
- skill-local or owner-local `PLAN.md` when one owner clearly owns the pass
- no plan for a small digest that can close in the response

The plan should include:

- scope, source/input id, type, branch, cursor, and current HEAD when applicable
- source/input inventory and original-source URLs for curated indexes
- routing hypothesis and existing local skills to inspect first
- distiller handoff slices, approval gates, validation commands, and closeout
  fields
- a clear `skill-distiller` or specialized artifact-distiller handoff queue
  when evidence extraction is required
- receipt bundle classification after distiller receipts exist
- target-skill update packets when receipts converge on existing local skills
- a repository architecture packet when placement, naming, split, move, or
  ownership decisions are needed
- post-authoring conservation-review gates before final closeout when local
  authoring compresses upstream-derived receipt evidence

The plan should not include capability ledger rows, section / recipe parity
rows, compression reasoning, tool/resource conservation rows, final local skill
wording, or file patches. Those are owned by `skill-distiller` and
`skill-creator` respectively.

When the pass closes, move durable receipts into `upstreams.yaml` and remove
the completed plan unless the user asks otherwise.
