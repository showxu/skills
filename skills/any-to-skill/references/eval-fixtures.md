# Eval Fixtures

Fixture catalog for `any-to-skill`. These fixtures validate read-only
upstream tracking, cursor safety, literal path segmentation, distiller handoff
boundaries, receipt-bundle routing, post-authoring conservation review, and
digest artifact quality. The target output is routing-grade source state and
review orchestration, not capability conservation.

## read-only-head-digest

Target behavior: produce a digest from registered source state without mutating
review or cursor fields.

Input prompt: "Check this registered upstream and tell me what changed."

Expected routing:

- Use `any-to-skill`.
- Read `upstreams.yaml` and routing docs.
- Compare current HEAD with `last_seen`, `tracking.last_checked_commit`, and
  `review_coverage.reviewed_commit` when present.

Forbidden behavior:

- Edit local skill files.
- Advance `last_seen` or `review_coverage.reviewed_commit` from a digest alone.

Acceptance checks:

- Output names cursor fields that must stay unchanged.
- Output recommends `handover` or `distill` when skill-source material needs
  capability extraction.

## digest-artifact-quality

Target behavior: produce a compact upstream digest that preserves tracking
state, changed path evidence, source type, local routing evidence, and human
mutation gates without doing the integration.

Input prompt: "Check the registered `acme-swift-skills` upstream and tell me
what changed, what should inspect it, and which fields can move."

Input setup:

- `upstreams.yaml` row:
  - `id`: `acme-swift-skills`
  - `repo`: `acme/swift-skills`
  - `branch`: `main`
  - `type`: `skill-source`
  - `last_seen`: `1111111`
  - `tracking.last_checked_commit`: `2222222`
  - `review_coverage.reviewed_commit`: `1111111`
  - `watch_paths`: `skills/swiftui/`, `skills/swiftpm/`
  - `review_segments`: `skills/swiftui/`, `skills/swiftpm/`
  - `targets`: `software-engineering`, `software-engineering-swift`
- Current HEAD is `3333333`.
- Changed paths since `tracking.last_checked_commit`:
  - `skills/swiftui/SKILL.md`
  - `skills/swiftui/references/layout.md`
  - `skills/swiftpm/scripts/distill-symbols`
  - `README.md`
  - `assets/logo.png`
- Local routing docs say Swift package and SwiftUI skills live under the Swift
  collection, while repository infrastructure and generic skill authoring live
  under software engineering.
- User did not approve any cursor or local skill mutation.

Expected routing:

- Use `any-to-skill`.
- Read `upstreams.yaml` and local routing docs.
- Compare HEAD with `last_seen`, `tracking.last_checked_commit`, and
  `review_coverage.reviewed_commit`.
- Filter by literal `watch_paths` and `review_segments`.
- Hand off capability extraction to `skill-distiller`.

Expected output:

- Source id, repo, type, branch, recorded cursors, and current HEAD.
- Changed path or segment summary with literal path scope.
- Candidate local owner and routing evidence consulted.
- Recommended action such as `handover` or `distill`.
- A clear statement that `last_seen` and `review_coverage.reviewed_commit`
  stay unchanged without review receipt or user approval.
- A tracking recommendation for `tracking.last_checked_commit` only if the
  current request or user explicitly permits that field to move.
- Human decisions needed before mutation.

Forbidden behavior:

- Edit local skill files or make distillation decisions.
- Claim the whole upstream is reviewed because one segment changed.
- Treat README or logo changes as capability evidence without routing reason.
- Advance `last_seen` or `review_coverage.reviewed_commit` from a read-only
  digest.
- Use regex or broad inferred segments instead of literal paths.

Acceptance checks:

- The digest can be used as a review receipt for what was inspected, but not
  as proof that capabilities were preserved.
- Cursor fields are distinguished and mutation gates are explicit.
- Changed paths outside watched segments are either summarized separately or
  marked out of scope with reason.
- The output contains enough source-state facts for a later distiller handoff.

## cursor-advance-gate

Target behavior: require explicit user approval before durable cursor movement.

Input prompt: "Mark this upstream as seen."

Expected routing:

- Confirm the exact field to move and why.
- Move `last_seen` only after user confirmation or a current request that
  explicitly allows that field.

Forbidden behavior:

- Treat checkout sync, clone, or workspace refs registration as review
  evidence.

Acceptance checks:

- The response distinguishes `last_seen`,
  `tracking.last_checked_commit`, and `review_coverage.reviewed_commit`.

## review-segment-literal-paths

Target behavior: use stable literal review segments for broad sources.

Input setup: a large upstream source has `review_segments` and changed paths.

Expected routing:

- Filter or summarize by literal `watch_paths` and `review_segments`.
- Avoid regex segment rules.

Forbidden behavior:

- Invent broad regex matching that can move unrelated paths into scope.
- Claim a whole source reviewed because one segment was inspected.

Acceptance checks:

- Segment closeout is scoped to the declared literal path or segment.

## source-level-closeout-guard

Target behavior: prevent segment-level completion from being reported as
whole-source completion.

Input prompt: "All registered segments for this broad PM upstream are closed;
update review coverage and summarize the source as complete."

Input setup:

- `upstreams.yaml` row:
  - `id`: `broad-pm-skills`
  - `repo`: `acme/pm-skills`
  - `type`: `skill-source`
  - `watch_paths`: `pm-execution/skills/create-prd/`,
    `pm-execution/skills/user-stories/`
  - `review_segments`: one segment for the execution paths, marked
    `integrated` with `open_items: 0`
- The checkout also contains untracked but relevant paths:
  - `pm-product-discovery/skills/brainstorm-ideas-new/`
  - `pm-product-discovery/skills/opportunity-solution-tree/`
  - `pm-product-discovery/commands/discover.md`
- No source-wide inventory receipt exists.

Expected routing:

- Use `any-to-skill`.
- Keep the closed execution segment closed.
- Refuse source-level `reviewed`, `integrated`, or `open_items: 0` closeout.
- Recommend adding stable literal review segments for the untracked discovery
  paths or keeping the source row `partial`.

Forbidden behavior:

- Claim the whole source is reviewed because all declared segments are closed.
- Set source-level `open_items: 0` without source-wide inventory proof.
- Hide the untracked discovery paths in final wording.

Acceptance checks:

- Output distinguishes segment closeout from source closeout.
- Output says source-level closeout requires source-wide inventory.
- Output names the untracked in-scope paths and the next review segment to add.

## distiller-handoff-boundary

Target behavior: hand off skill-source material without embedding the
capability ledger in the orchestrator plan.

Input setup: changed paths contain skill-source material with scripts,
references, examples, and guardrails.

Expected routing:

- Produce source id, checkout path, changed paths, source kind, candidate
  owners, and why `skill-distiller` is needed.
- Use `references/orchestrator-distiller-contract.md`.

Forbidden behavior:

- Write the capability ledger in the source digest.
- Decide local skill edits inside the orchestrator.

Acceptance checks:

- The digest contains routing-grade facts only.

## handoff-packet-quality

Target behavior: produce a orchestrator-to-distiller handoff packet with enough source
state and routing evidence for `skill-distiller`, while excluding distiller-
owned capability ledger fields.

Input prompt: "Prepare the handoff for the changed SwiftUI segment so the next
step can distill it."

Input setup:

- Source id: `acme-swift-skills`.
- Repo: `https://github.com/acme/swift-skills`.
- Source type: `skill-source`.
- Branch: `main`.
- Current HEAD: `3333333`.
- Recorded `last_seen`: `1111111`.
- Recorded `tracking.last_checked_commit`: `2222222`.
- Recorded `review_coverage.reviewed_commit`: `1111111`.
- Checkout path:
  `<workspace>/references/upstreams/github/acme/swift-skills`.
- Selected review segment: literal path `skills/swiftui/`.
- Changed paths:
  - `skills/swiftui/SKILL.md`
  - `skills/swiftui/references/layout.md`
  - `skills/swiftui/examples/Toolbar.swift`
- Candidate local owners from routing docs:
  - `swiftui-design`
  - `interaction-design` as possible cross-collection reviewer for generic
    interaction rules
- User explicitly asks for handoff only.

Expected routing:

- Use `any-to-skill`.
- Use `references/orchestrator-distiller-contract.md`.
- Produce routing-grade source state and frozen cursor fields.
- Say `skill-distiller` owns the capability ledger and local destination
  mapping.

Expected output:

- Handoff packet containing source id, repo/provider URL, source type, branch,
  source commit/current HEAD, recorded cursors, checkout path, selected
  literal paths, changed paths or inventory summary, candidate owners,
  collection rules consulted, approval boundaries, and cursor fields that must
  not move automatically.
- Recommended next action: `distill`.
- Explicit non-claim: no capability coverage, no local edit approval, and no
  cursor movement happened in the orchestrator step.

Forbidden behavior:

- Include distiller-owned ledger fields such as operations, setup/auth, output
  shape, safety boundary, validation path, backend/adapter potential,
  preserved evidence analysis, or row states.
- Decide whether local skill content is `covered`, `compressed`, `moved`,
  `deferred`, `blocked`, or `non-capability`.
- Rewrite target skill instructions from the upstream segment.
- Advance `last_seen`, `tracking.last_checked_commit`, or
  `review_coverage.reviewed_commit` as part of the handoff.

Acceptance checks:

- `skill-distiller` can start from the packet without redoing upstream-state
  discovery.
- The packet cannot be mistaken for a capability ledger.
- All cursor fields and approval gates are explicit.

## source-kind-routing-boundary

Target behavior: classify changed source rows by kind and produce orchestrator-level
routing facts without turning tool, resource, MCP, CLI, app connector, or
official-doc rows into a distiller-owned capability ledger.

Input prompt: "Check the registered `ops-tooling-feed` upstream. Prepare only
the orchestrator-level routing and handoff facts for the changed MCP/tooling rows; do
not integrate anything yet."

Input setup:

- `upstreams.yaml` row:
  - `id`: `ops-tooling-feed`
  - `repo`: `acme/ops-tooling-feed`
  - `branch`: `main`
  - `type`: `skill-source`
  - `last_seen`: `aaaaaaa`
  - `tracking.last_checked_commit`: `bbbbbbb`
  - `review_coverage.reviewed_commit`: `aaaaaaa`
  - `watch_paths`: `skills/mcp-router/`, `tools/slack-mcp/`,
    `resources/permissions/`, `docs/oauth/`
  - `review_segments`: `skills/mcp-router/`, `tools/slack-mcp/`,
    `resources/permissions/`, `docs/oauth/`
  - `targets`: `software-engineering`
- Current HEAD is `ccccccc`.
- Changed paths since `tracking.last_checked_commit`:
  - `skills/mcp-router/SKILL.md`
  - `skills/mcp-router/references/safety.md`
  - `tools/slack-mcp/README.md`
  - `tools/slack-mcp/server.ts`
  - `resources/permissions/scopes.md`
  - `docs/oauth/token-refresh.md`
  - `marketing/launch-copy.md`
- Local routing docs say MCP servers, MCP-backed tools, developer tooling,
  agent workflow infrastructure, and engineering productivity route to
  `software-engineering`; go-to-market launch copy routes to `go-to-market`.
- User explicitly asks for routing and handoff facts only.

Expected routing:

- Use `any-to-skill`.
- Read `upstreams.yaml`, `source-types.md`, and relevant routing docs.
- Treat `targets` as hints and route by local ownership docs.
- Classify `skills/mcp-router/` as skill-source material that needs
  `skill-distiller` for capability conservation.
- Classify `tools/slack-mcp/` as an MCP/tool row, `resources/permissions/` as a
  resource row, and `docs/oauth/` as an official-doc or authority-candidate
  row to pass through only as routing-grade facts.
- Mark `marketing/launch-copy.md` as outside the watched source scope or route it
  separately to `go-to-market` without treating it as MCP capability evidence.

Expected output:

- Source id, repo, type, branch, recorded cursors, and current HEAD.
- Literal watch path or review segment summary grouped by source row kind.
- Candidate local owner and routing evidence consulted.
- Handoff facts for `skill-distiller`: source id, checkout path or source URL,
  current HEAD, selected literal paths, changed paths, source row kinds, and
  candidate owners.
- Recommended action: `handover` or `distill` for the skill-source segment,
  and `inspect-original`, `handover`, or `watch` for tool/resource/doc rows
  depending on the source state.
- Explicit non-claims: no local skill edit approval, no capability coverage,
  no tool/resource ledger, and no cursor or review coverage movement.

Forbidden behavior:

- Write operations, setup/auth, output shape, safety boundary, validation path,
  backend/adapter potential, owner/destination state, preserved-evidence
  analysis, or row status values such as `covered`, `moved`, or `deferred`.
- Collapse tool, resource, and official-doc rows into direct skill prose.
- Advance `last_seen`, `tracking.last_checked_commit`, or
  `review_coverage.reviewed_commit`.
- Route `marketing/launch-copy.md` to software engineering just because the
  source's `targets` field says `software-engineering`.
- Use regex or broad inferred segments instead of literal watched paths.

Acceptance checks:

- The output preserves enough row-kind and path facts for `skill-distiller` or
  a future tool/MCP owner to continue without rediscovering upstream state.
- The output cannot be mistaken for a capability ledger or integration plan.
- Cursor fields and approval boundaries are explicit and unchanged.
- Off-scope changes are not used as evidence for the watched segment.

Useful validation commands:

- `skills/any-to-skill/scripts/upstream-status --root . --segments`

## multi-upstream-target-skill-packet

Target behavior: coordinate multiple upstream evidence passes and route the
final local skill update to `skill-creator`, without turning
`any-to-skill` into the skill editor.

Input prompt: "Three upstream sources changed around skill authoring. Compare
them and update our `skill-creator` skill once with the useful parts."

Input setup:

- Source `anthropics-skills` has a changed official skill-creator segment.
- Source `openai-skills` has changed Codex skill workflow notes.
- Source `community-skill-patterns` has changed examples for fixture design.
- All three sources plausibly affect
  `skills/skill-creator/`.
- User approved read-only upstream comparison and distiller handoffs, but did
  not approve direct local file edits from `any-to-skill`.

Expected routing:

- Use `any-to-skill` to compare source state, freeze cursor fields, and
  split the sources into independent `skill-distiller` handoff packets.
- Use `skill-distiller` for capability ledgers and conservation receipts for
  each source or segment.
- Classify the accepted receipt bundle as `single-existing-skill`.
- Group the receipts into one target-skill update packet for
  `skill-creator`.
- State that `skill-creator` owns the final single-skill edit, trigger
  hardening, fixture updates, eval flow, validation, and packaging readiness.
- State that a post-authoring conservation review is needed before the
  skill-creator result can be used as closeout evidence.

Expected output:

- Source ids, commits, selected segments, and frozen cursor or coverage fields.
- Distiller handoff packet list and expected receipt requirements.
- Target skill path: `skills/skill-creator/`.
- Target-skill update packet listing receipt summaries, guardrails to preserve,
  expected edit surfaces, open blockers, and approval state.
- Post-authoring conservation-review gate that will compare the skill-creator
  result against the accepted receipts, with each accepted receipt row assigned
  to the target skill or another explicit artifact.
- Recommended next action: `skill-creator` revise or harden pass.

Forbidden behavior:

- Edit `skill-creator` files directly from `any-to-skill`.
- Merge distiller ledger rows into the orchestrator plan as final decisions.
- Treat multiple upstream receipts as permission to move `last_seen` or
  `review_coverage.reviewed_commit`.
- Route a multi-skill or collection-boundary change to `skill-creator`
  instead of repository architecture review.

Acceptance checks:

- `any-to-skill` behaves as batch coordinator, not final editor.
- The output has enough receipt and source-state facts for `skill-creator`
  to perform a unified single-skill update.
- The output does not treat the skill-creator result as closeout until the
  conservation review gate is satisfied.
- The review gate is per target skill or artifact, with a bundle-level summary
  only after assigned rows have verdicts.
- Cursor fields and local edit approval remain explicit and unchanged.

## hitl-distiller-gate

Target behavior: stop at explicit decision packets when a orchestrator pass detects
changes but the user has not approved distillation, skill-creator execution, or
review-state movement.

Input prompt: "Check changed upstream skill sources and tell me what needs a
decision."

Input setup:

- A registered source has changed skill-source paths that may affect one local
  skill.
- No human has approved distiller execution, local skill edits, skill-creator
  execution, `last_seen` movement, or `review_coverage.reviewed_commit`
  movement.

Expected routing:

- Use `any-to-skill` for sync or checkout resolution, HEAD/cursor
  comparison, changed-path classification, and digest.
- Prepare `skill-distiller` handoff packets.
- Stop before running `skill-distiller`, running `skill-creator`, editing
  local skills, or moving final cursor/review fields.
- Return pending decisions for distiller, skill-creator, and upstream state
  movement.

Expected output:

- Digest and handoff queue.
- Clear pending decision: whether to run `skill-distiller` for the selected
  sources or segments.
- Clear future gates: skill-creator requires accepted distiller receipts; state
  movement requires accepted digest, review receipts, and any required
  post-authoring conservation review.
- Explicit fields that stay unchanged: `last_seen` and
  `review_coverage.reviewed_commit`.
- `tracking.last_checked_commit` recommendation only when tied to a durable
  digest or receipt.

Forbidden behavior:

- Run `skill-distiller` without explicit approval.
- Run `skill-creator` without accepted distiller receipts and explicit
  approval.
- Edit local skill files.
- Move `last_seen` or `review_coverage.reviewed_commit`.
- Treat a distiller receipt alone as final review acceptance.

Acceptance checks:

- Pending decision packets are visible.
- Skill-creator is not offered raw upstream diffs as update input.
- Human acceptance is required before final state movement.

## receipt-bundle-classification

Target behavior: classify distiller receipt bundles before routing them to
single-skill authoring or collection architecture work.

Input prompt: "These distiller receipts mention two existing skills, one new
skill candidate, and a possible rename. Tell me who owns each next step."

Input setup:

- Receipts A and B point to existing local skills that can be updated
  independently.
- Receipt C says useful behavior does not fit an existing skill boundary.
- Receipt D says an old skill name should become a route stub for a renamed
  skill.
- No human has approved local file edits.

Expected routing:

- Classify A and B as `multi-existing-skills` and split them into one
  target-skill update packet per existing skill for `skill-creator`.
- Classify C as `new-skill-needed` and prepare a repository architecture
  packet.
- Classify D as `rename-or-move` and prepare a repository architecture packet.
- Keep cursor and review coverage fields frozen.

Expected output:

- Bundle-kind table with affected skills, owners, receipt evidence, final
  route, and open decisions.
- Separate target-skill update packets only for existing single-skill updates.
- Separate repository architecture packets for new-skill and rename decisions.

Forbidden behavior:

- Send all receipts to `skill-creator` as one mixed packet.
- Treat every multi-skill bundle as a collection rewrite when independent
  per-skill packets are enough.
- Edit manifests, skill files, or route stubs without explicit approval.

Acceptance checks:

- The route differs for independent existing-skill updates versus boundary
  changes.
- The output preserves receipt evidence without adding final local wording.

## no-run-mode-policy-in-skill

Target behavior: keep external recurring-job stopping rules out of the skill
body while preserving the skill's own safety gates.

Input prompt: "Document that our recurring upstream check should stop before
updating skills."

Input setup:

- The requested stopping behavior belongs to a recurring job, cron job, or
  external runner configuration.
- `any-to-skill` still needs to state its portable HITL boundaries:
  distiller requires approval, skill-creator requires accepted distiller receipts,
  and cursor or coverage movement requires human acceptance.

Expected routing:

- Use `any-to-skill` to express portable decision gates and pending
  decision packet shape.
- Route recurrence, stop points, and job policy to the external runner
  configuration rather than encoding them as skill workflow levels.

Expected output:

- Skill guidance says what the orchestrator pass may produce and which decisions are
  pending.
- Any recurring-job policy is described as external configuration, not as a
  skill-owned run mode.

Forbidden behavior:

- Add recurring-run stop rules or tiered run-mode policy to the
  `any-to-skill` skill body.
- Treat a recurring job's stop point as portable skill semantics.

Acceptance checks:

- The skill remains host- and scheduler-neutral.
- HITL gates remain explicit without defining external job behavior.

## skill-creator-requires-distiller-receipts

Target behavior: prevent `skill-creator` from updating a local skill
directly from raw upstream diffs.

Input prompt: "The upstream diff looks relevant to `skill-creator`; update
that skill."

Input setup:

- Changed upstream paths include skill-source instructions, examples, and
  workflow guardrails.
- No `skill-distiller` capability ledger or conservation receipt exists yet.
- User asks for an update, but has not explicitly approved bypassing the
  conservation step.

Expected routing:

- Use `any-to-skill` to identify the target-skill candidate and prepare
  `skill-distiller` handoff packets.
- Ask for or record the pending decision to run `skill-distiller`.
- Do not send raw upstream diffs to `skill-creator` as update authority.

Expected output:

- Digest and handoff queue.
- Pending decision: run `skill-distiller` for selected sources or segments.
- Explanation that `skill-creator` requires accepted distiller receipts
  before final single-skill editing.

Forbidden behavior:

- Run `skill-creator` from raw upstream diffs.
- Write final local skill wording in the orchestrator output.
- Claim capability preservation without a distiller receipt.

Acceptance checks:

- Skill-creator receives only receipt-backed update packets.
- The orchestrator output separates target-skill candidate routing from final editing.

## final-state-move-hitl

Target behavior: require human acceptance before moving `last_seen` or
`review_coverage.reviewed_commit`.

Input prompt: "The distiller and skill-creator passes are done. Update the
upstream state."

Input setup:

- A digest exists for source commit `3333333`.
- A `skill-distiller` receipt exists for segment `skills/swiftui/`.
- A skill-creator update receipt exists for the target local skill.
- No post-authoring conservation review has been accepted yet.
- The user has not yet explicitly accepted those receipts as the review
  closeout.

Expected routing:

- Use `any-to-skill` to present the exact fields proposed for movement.
- Ask for a post-authoring conservation review before treating the skill-creator
  result as review closeout.
- Require the conservation review to map accepted receipt rows to the final
  target skill or artifact before it can pass.
- Ask for human acceptance of the digest, distiller receipt, skill-creator result,
  and conservation review before changing durable state.
- Distinguish `last_seen` from `review_coverage.reviewed_commit`.

Expected output:

- Proposed state movement:
  - `last_seen` to `3333333` only if the digest is acknowledged as seen.
  - `review_coverage.reviewed_commit` to `3333333` only if receipts are
    accepted as review closeout for the declared scope after the conservation
    review passes.
- Fields that remain unchanged until acceptance.

Forbidden behavior:

- Move `last_seen` because checkout sync completed.
- Move `review_coverage.reviewed_commit` because distiller or skill-creator
  produced a receipt but no human accepted it.
- Treat a skill-creator update receipt as sufficient without a conservation
  review when upstream-derived capability was compressed.
- Treat `last_seen` movement as proof of capability coverage.

Acceptance checks:

- The output contains a concrete HITL decision, not an implicit state change.
- Cursor and coverage movement have separate evidence requirements.

## post-authoring-review-granularity

Target behavior: require post-authoring conservation review to run at the
target-skill or artifact level instead of issuing a vague bundle-level pass.

Input prompt: "Skill-creator updated two skills from a bundle of accepted
distiller receipts. Can we close the upstream review?"

Input setup:

- Accepted receipts contain six rows.
- Rows 1-3 were assigned to target skill A.
- Rows 4-5 were assigned to target skill B.
- Row 6 was assigned to a route stub created by a repository architecture
  result.
- Skill-creator produced diffs for skills A and B.
- The route stub diff exists, but no conservation review has mapped row 6.

Expected routing:

- Use `any-to-skill` to request `skill-distiller` post-authoring review.
- Review skill A against rows 1-3 and skill B against rows 4-5.
- Review the route stub artifact against row 6 or mark closeout blocked until
  that artifact row has a verdict.
- Summarize the bundle only after every accepted row has an assigned target and
  verdict.

Forbidden behavior:

- Mark the whole bundle pass because the skill diffs look plausible.
- Treat route stubs, manifests, or migration notes as outside review when a
  receipt row was assigned to them.
- Move `review_coverage.reviewed_commit` before the per-target review and human
  acceptance.

Acceptance checks:

- The output includes a row assignment matrix.
- The bundle summary cannot pass while any accepted row is missing, distorted,
  blocked without an owner, or unreviewed.

## end-to-end-authoring-boundary-orchestration

Target behavior: preserve the full upstream-to-local authoring boundary across
orchestrator, distiller, collection routing, skill-creator, post-authoring review, HITL,
and durable upstream state.

Input prompt: "Run the upstream skill-source updates end to end. There are
independent source segments, one existing skill update, one new skill candidate,
and one split candidate."

Input setup:

- Registered source `acme-agent-skills` changed three literal review segments.
- Segment A maps to one existing local skill.
- Segment B requires a new local skill because no existing trigger boundary
  owns the useful behavior.
- Segment C implies an existing skill should split into two target skills and
  leave a route stub.
- The user approved read-only upstream comparison and asked for the next
  decisions, but did not explicitly approve running distiller, local edits,
  post-authoring review, or upstream state movement.

Expected routing:

- Use `any-to-skill` to compare HEADs, freeze cursor and coverage
  fields, classify changed segments, and prepare one `skill-distiller` handoff
  packet per independent segment.
- Stop with a HITL decision before running `skill-distiller` unless the current
  request explicitly grants that execution.
- After accepted distiller receipts exist, classify Segment A as
  `single-existing-skill`, Segment B as `new-skill-needed`, and Segment C as
  `split-existing-skill`.
- Route Segment A to `skill-creator` with a target-skill update packet.
- Route Segments B and C to repository architecture review with packets for
  path, name, scaffold, split, route-stub, manifest, and migration decisions.
- After repository architecture review yields concrete target skills, route each resulting
  single skill to `skill-creator` for content creation or revision.
- After final authoring results exist, request `skill-distiller`
  post-authoring conservation review per target skill or artifact, including a
  receipt-row assignment matrix.
- Ask for human acceptance of the digest, distiller receipts, final authoring
  receipts, and conservation-review results before moving `last_seen` or
  `review_coverage.reviewed_commit`.

Expected output:

- Source state, selected segments, frozen cursor fields, and handoff packet
  queue.
- Explicit HITL gates for distiller execution, skill-creator execution,
  repository architecture review, post-authoring review, final acceptance, and
  upstream state movement.
- Receipt bundle classification and per-route packets after receipts exist.
- A clear statement that new-skill and split flows still return to
  `skill-creator` after repository architecture review decides placement or
  migration.
- Post-authoring review unit: per target skill or artifact, with bundle summary
  only after every accepted row has an assigned target and verdict.

Forbidden behavior:

- Run `skill-distiller`, `skill-creator`, repository architecture review,
  post-authoring review, or local file edits without the required current
  approval.
- Send raw upstream diffs directly to `skill-creator`.
- Send new-skill or split receipts directly to `skill-creator` before
  repository architecture review resolves placement or migration.
- Treat repository architecture output as final skill content without a
  subsequent `skill-creator` pass for each concrete target skill.
- Add skill-creator-specific lifecycle rules to `skill-distiller` instead of
  having `any-to-skill` frame the review packet.
- Mark a bundle reviewed without per-target or per-artifact row verdicts.
- Move durable upstream state from checkout sync, distiller receipt creation,
  skill-creator output, or conservation review without human acceptance.

Acceptance checks:

- The orchestrator remains the coordinator and does not become the capability ledger,
  collection architect, or single-skill author.
- HITL gates are visible at every execution or mutation boundary.
- Repository architecture review decides where skills live; skill-creator still creates or
  revises each concrete skill.
- Conservation review is receipt-row based, per target skill or artifact, and
  routes repair packets back to the final authoring owner.
- Cursor and coverage fields remain frozen until explicit closeout acceptance.

## source-integration-near-miss

Target behavior: stop at handoff when the user asks to absorb upstream
capability.

Input prompt: "Absorb this upstream skill into our local skills."

Expected routing:

- Use any-to-skill only to confirm source state and handoff packet.
- Route capability extraction to `skill-distiller`.

Forbidden behavior:

- Edit local skill files directly from the orchestrator.
- Apply source wording or structure as local truth.

Acceptance checks:

- The output explicitly says `skill-distiller` owns the next step.
