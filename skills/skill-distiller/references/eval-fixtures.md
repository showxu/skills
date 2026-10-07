# Eval Fixtures

Fixture catalog for `skill-distiller`. These fixtures evaluate the quality of
distillation artifacts: capability ledgers, handover rows, destination
proposals, and coverage receipts. They do not test whether the skill can recite
its workflow. They test whether a produced distillation result preserves enough
source behavior for a downstream owner to act without rereading the whole
upstream.

Robust coverage for this skill needs four fixture classes:

- positive generation cases that require a usable ledger from source material
- negative audit cases that catch missing rows, vague compression, and bad
  handover fields
- boundary cases that stop upstream tracking, single-skill authoring,
  packaging, or freshness work from being handled by this skill
- coverage-receipt cases that preserve segment evidence without mutating
  upstream state

Each fixture includes a baseline expectation and evidence sources so it can be
converted into an isolated `with_skill` versus `without_skill` eval run without
leaking grading criteria into the executor prompt.

## capability-ledger-generation

Target behavior: generate a complete capability ledger and destination proposal
from selected skill-source material without editing local files.

Input prompt: "Distill this selected upstream skill excerpt into a local
capability ledger and destination proposal. Do not edit files yet."

Context and files:

Source scope: `mock-upstream/skills/browser-debug/`, commit `a11ce01`.

Source excerpt:

- Trigger: use when a user asks an agent to debug a local web app in a browser.
- Workflow:
  1. start or locate the local dev server
  2. open the app in a browser automation backend
  3. inspect console errors and network failures
  4. reproduce the broken workflow with screenshots
  5. fix the app only after the failure is understood
- Good behavior: capture before/after screenshots and console evidence.
- Bad behavior: claim success from code inspection alone, skip the browser, or
  treat a blank canvas as passing.
- Validation: rerun the workflow in desktop and mobile viewport sizes.
- Reusable artifact: a checklist for browser QA evidence.
- Boundary: not a generic frontend design critique and not a marketing landing
  page review.
- Non-capability material: contributor badge and funding link.

Candidate local owners:

- `webapp-testing` owns local web app browser QA.
- `interaction-design` owns design critique and should not own this debugging
  workflow.

Expected routing:

- Use `skill-distiller` to produce a conservation ledger and local mapping.
- Stop at proposal because the prompt does not approve local edits.
- Prefer the existing `webapp-testing` owner unless a distinct trigger or
  workflow boundary is proven.

Expected output:

- Source scope and commit.
- Ledger rows for trigger, workflow steps, good behavior, bad behavior,
  validation, reusable checklist, boundary, and non-capability metadata.
- Exactly one allowed state per row:
  `covered`, `compressed`, `moved`, `deferred`, `blocked`, or
  `non-capability`.
- Concrete destination proposal that strengthens `webapp-testing`; design
  critique is excluded or deferred to `interaction-design` only for design-only
  material.
- Closeout showing source item count, ledger row count, missing rows, duplicate
  mappings, authority gaps, validation status, and that no local edits or
  cursor mutations happened.

Forbidden behavior:

- Produce only a prose summary without a ledger.
- Mark the browser workflow as covered because a local skill has a similar
  topic name.
- Drop screenshots, console evidence, blank-canvas failure, or mobile viewport
  validation as implementation details.
- Edit local skills, run browser automation, or mutate upstream state.

Acceptance checks:

- The output has ledger rows for every actionable source item and one metadata
  row marked `non-capability`.
- Each compressed row names the concrete behavior preserved and the local
  destination.
- The destination proposal is executable by a downstream owner without rereading
  the excerpt.
- The report explicitly states that local edits and upstream cursor mutations
  were not performed.

Baseline expectation:

- A no-skill or wrong-sibling run is likely to summarize the browser workflow,
  skip row-state accounting, or route too much material to a generic frontend or
  design skill.

Evidence sources:

- Final response text.
- Any generated ledger or report artifact.
- Transcript evidence that no file edit, browser run, or upstream-state mutation
  was performed.

## tool-handover-generation

Target behavior: generate retained handover rows for useful MCP/CLI/resource
material instead of discarding it as non-skill content.

Input prompt: "Distill this tool-heavy source segment. Preserve useful
MCP/CLI/resource material as handover rows with local owners. Do not install or
run anything."

Context and files:

Source scope: `mock-upstream/remote-ios-tooling/`, commit `b00c515`.

Source excerpt:

- `xcodebuild-mcp`: remote build, run, simulator boot, app install, app launch,
  build-log collection, and simulator-log collection.
- `apple-docs-resource`: searchable Apple documentation backend for API
  confirmation.
- CLI recipe: `simctl list`, boot by runtime, install `.app`, launch bundle id,
  stream logs with predicates.
- Setup/auth: Xcode path, selected simulator runtime, trusted host, per-host
  token, reachable log directory.
- Output shape: build result, simulator device id, launch status, stdout/stderr
  paths, log archive path.
- Safety: never mutate a shared CI host without operator approval; prefer
  disposable runner or dry-run first.
- Validation/failure: verify runtime exists, token is present, host is
  reachable, log path is readable, and collect logs before retrying.
- Backend potential: MCP server now; CLI adapter later.
- Non-capability material: logo and release badge.

Candidate local owners:

- `ios-simulator` for simulator practice rows.
- future MCP/tooling owner for remote server/backend rows.
- `foundation-urlsession-patterns` is unrelated and should not own this.

Expected routing:

- Use `skill-distiller` to retain tool value as handover material.
- Do not execute setup, remote commands, installs, or tool discovery.
- Split direct simulator practice from future backend ownership when useful.

Expected output:

- Capability ledger rows for source items that affect skill behavior.
- A handover table with required fields: source item, operations/value,
  setup/auth, output shape, safety boundary, validation/failure modes,
  backend/adapter candidate, owner/destination, authority status, and preserved
  evidence.
- `logo` and `release badge` marked `non-capability`.
- Explicit statement that this is a handover, not a local installation or remote
  operation.

Forbidden behavior:

- Mark MCP, CLI, resource, setup/auth, output shape, or failure-path material as
  non-capability solely because it is not a `SKILL.md`.
- Start remote setup, install a server, run `simctl`, or query a live host.
- Collapse the output shape and validation/failure fields into "implementation
  details for later".

Acceptance checks:

- Every operational row has owner/destination, authority status, preserved
  evidence, setup/auth, output shape, safety, validation/failure path, and
  backend/adapter potential.
- The output distinguishes direct simulator skill material from future backend
  handover rows.
- The report records no tool execution or installation.

Baseline expectation:

- A no-skill run is likely to discard MCP/resource rows as non-skill metadata or
  give generic "consider tooling" advice without the required handover fields.

Evidence sources:

- Final response text.
- Generated handover table.
- Transcript or command log showing that no installs, remote setup, or live
  tool commands ran.

## upstream-freshness-boundary

Target behavior: refuse to perform upstream freshness, registration, or cursor
mutation work inside `skill-distiller`, while preserving any already-selected
distillation follow-up as a separate handoff.

Input prompt: "Check whether `composio-skills` changed upstream, update the
tracking cursor if HEAD moved, and distill anything new if needed."

Context and files:

- Source id mentioned by user: `composio-skills`.
- No selected review segment, source checkout, commit, digest, or handoff packet
  is provided.
- The user asks for freshness checking and cursor movement before any source
  material is selected.

Expected routing:

- Recognize this as upstream tracking-state work, not distillation.
- Stop before polling HEAD, syncing checkouts, editing upstream manifests, or
  creating a capability ledger.
- Offer the right boundary: an upstream tracking owner or human review must
  handle freshness/cursor movement first; run `skill-distiller` only after a
  selected segment or handoff packet exists.

Expected output:

- Clear refusal to handle freshness/cursor mutation inside `skill-distiller`.
- Explanation that upstream tracking/review state is frozen for this skill,
  without requiring the distiller to enumerate manifest schema fields.
- No ledger unless the user provides selected source material.
- Handoff recommendation to the upstream tracking owner or human review.

Forbidden behavior:

- Run git/network freshness checks as part of this skill.
- Edit upstream manifests or claim that the tracking cursor can move.
- Invent a source scope and begin broad distillation.
- Treat the request as generic skill creation or production hardening.

Acceptance checks:

- The response stops before source mutation or broad source scanning.
- It treats upstream tracking/review state as frozen without relying on
  schema-field enumeration.
- It states the condition under which `skill-distiller` should run later:
  selected source material, commit, path segment, or handoff packet.

Baseline expectation:

- A no-skill run may try to satisfy the user's first verbs by checking upstream
  status, mutating tracking fields, or mixing upstream tracking and
  distillation
  responsibilities.

Evidence sources:

- Final response text.
- Command transcript showing no upstream sync, network poll, or manifest edit.

## single-skill-authoring-boundary

Target behavior: route generic skill creation, production hardening, eval-loop,
and packaging requests away from `skill-distiller`.

Input prompt: "Take this draft skill and make it production-ready: improve its
description, write eval prompts, run the with-skill/baseline loop, and package
it."

Context and files:

- Draft skill path: `mock-local/skills/release-checklist/SKILL.md`.
- No upstream source material, review segment, copied prompt pack, or handoff
  packet is provided.
- The requested work is single-skill hardening and packaging.

Expected routing:

- Do not use `skill-distiller` for the main work.
- Stop with an out-of-scope boundary because the request is production
  hardening, eval-loop construction, description optimization, and packaging.
- If a next owner must be named, describe it by responsibility: single-skill
  authoring, hardening, eval-loop construction, and packaging.
- Preserve a possible future distillation note only if source material is later
  introduced.

Expected output:

- Clear boundary call that this is not a distillation task.
- Recommended owner by responsibility, not by hardcoded sibling skill name.
- No capability ledger, source item count, or coverage receipt.
- No package command run from `skill-distiller`.

Forbidden behavior:

- Convert the draft skill into a fake upstream source and produce a distillation
  ledger.
- Start packaging, eval-loop execution, or description optimization while
  claiming `skill-distiller` owns it.
- Mutate local skill files under the distiller workflow.

Acceptance checks:

- The response names the requested operations that make the task out of scope
  for `skill-distiller` and does not depend on a hardcoded sibling skill name.
- It does not produce a distillation report or coverage receipt.
- It does not run packaging or eval commands as part of this skill.

Baseline expectation:

- A no-skill run may treat any skill-related request as a distillation or
  generic authoring task and blur the boundary with single-skill authoring.

Evidence sources:

- Final response text.
- Command transcript showing no distiller report generation, package command, or
  local edit.

## ui-guardrail-result-audit

Target behavior: reject a distillation result that compresses source-specific
UI guardrails into generic SwiftUI advice.

Input prompt: "Audit this distillation result. Say whether it is acceptable,
what information was lost, and what must be fixed before local edits."

Context and files:

Source scope: `mock-upstream/skills/swiftui-ui-quality/`, commit `abc123`.

Source excerpt:

- Trigger: use when an agent builds SwiftUI screens from loose product copy.
- Good design: native controls, dense information hierarchy, platform spacing.
- Bad design: avoid dominant purple gradients, card-in-card layouts,
  decorative blobs, and marketing hero sections for work tools.
- Warning signs: generic API lists, missing screenshots, no mobile overflow
  check, clipped button text.
- Validation: run the app, inspect desktop and mobile screenshots, verify no
  text overlap.
- Code-shape examples: toolbar icon buttons for actions, segmented controls
  for modes, menus for option sets.
- Non-capability material: badge, sponsor link, repo star count.

Candidate local owner: existing `swiftui-design` already owns SwiftUI visual
and interaction guidance, but only at broad principle level.

Candidate distillation result to audit:

```md
Source item count: 12
Ledger row count: 4

| Source item | Local destination | State | Reason |
| --- | --- | --- | --- |
| SwiftUI design tips | `swiftui-design` | covered | We already have a SwiftUI design skill. |
| Avoid ugly visuals | `swiftui-design` | compressed | Add a short sentence about good taste. |
| Run screenshots | `swiftui-design` | compressed | Mention validation. |
| Repo badge/sponsor/star count | none | non-capability | Metadata only. |

Destination: no edits needed. Existing `swiftui-design` is enough.
Cursor: review can be marked complete.
```

Expected routing:

- Use `skill-distiller` as an artifact-quality audit.
- Compare the candidate result against the source excerpt.
- Do not rewrite local skills during the audit.

Expected output:

- Verdict: not acceptable / needs repair.
- Missing row report for the trigger, each concrete guardrail family,
  warning signs, validation checks, and code-shape examples.
- Explanation that topic coverage is not capability conservation.
- Repaired ledger requirements with exactly one allowed state per row:
  `covered`, `compressed`, `moved`, `deferred`, `blocked`, or
  `non-capability`.
- Destination guidance: strengthen existing `swiftui-design` unless a target
  owner proves a new boundary.
- Cursor guidance: distiller artifact alone does not move upstream cursor
  fields.

Forbidden behavior:

- Accept the result because it names `swiftui-design`.
- Treat "good taste" or "mention validation" as sufficient compression.
- Ignore individual anti-patterns, warning signs, validation checks, or
  code-shape examples.
- Recommend moving upstream cursor, freshness, or review-coverage fields from
  this artifact audit.

Acceptance checks:

- The audit identifies concrete lost information, not just "needs more
  detail".
- The audit separates capability rows from metadata rows.
- The audit gives a repair path that a downstream distiller pass can execute.

Baseline expectation:

- A no-skill run may accept topic-level coverage or vague compression because
  the candidate already names a plausible local owner.

Evidence sources:

- Final response text.
- Any repaired ledger requirements produced by the run.
- Transcript evidence that no local files or upstream cursor fields were
  changed.

## tool-handover-result-audit

Target behavior: reject a distillation result that drops MCP/CLI/tool material
or fails to preserve operational handover fields.

Input prompt: "Audit this tool-heavy distillation result for information loss
and downstream handoff quality."

Context and files:

Source scope: `mock-upstream/apple-dev-tools/`, commit `def456`.

Source excerpt:

- `xcodebuild-mcp`: remote simulator build/run/debug server for CI hosts.
- `apple-docs-mcp`: searchable Apple docs helper.
- `simctl` recipes: boot simulators, install apps, collect logs.
- Workflow prompt: `remote build debug` for CI/CD machines.
- Setup notes: Xcode path, simulator runtime, trusted network, auth token.
- Safety note: do not mutate a live CI machine without operator approval.
- Non-capability material: repo logo and community badge.

Candidate distillation result to audit:

```md
States: non-capability 4, covered 2

| Source item | Local destination | State | Reason |
| --- | --- | --- | --- |
| xcodebuild-mcp | none | non-capability | MCP tools are not skills. |
| apple-docs-mcp | none | non-capability | Agent can search docs itself. |
| simctl recipes | `ios-simulator` | covered | The skill already uses simulator commands. |
| remote build debug prompt | none | non-capability | Prompt text is not code. |
| setup notes | none | covered | Setup is environment-specific. |
| live CI approval note | `ios-simulator` | covered | General safety applies. |
| logo and badge | none | non-capability | Metadata. |

Destination: no handoff needed.
```

Expected routing:

- Use `skill-distiller` to audit MCP/CLI/tool/resource conservation.
- Treat MCP, CLI, workflow prompt, setup/auth, output shape, safety boundary,
  validation path, and backend/adapter potential as retained handover material
  when useful.

Expected output:

- Verdict: not acceptable / needs repair.
- Explicit finding that useful tool rows were incorrectly marked
  `non-capability`.
- Required handover fields for each operational row:
  owner or future thread, reason, preserved evidence, authority status,
  setup/auth assumptions, output shape, safety boundary, validation/failure
  path, and backend or adapter potential.
- Distinction between actual non-capability material such as logo/badge and
  operational material.
- Statement that no remote setup, upstream cursor movement, or local skill edit
  happened.

Forbidden behavior:

- Drop MCP/CLI rows solely because they are not prose instructions.
- Accept "agent can search docs itself" as a reason to discard the Apple docs
  backend use case.
- Mark setup/auth/safety notes covered without preserving the operational
  boundary.
- Start remote setup, command execution, or tool installation.

Acceptance checks:

- The audit keeps tool/backend rows as retained material, not direct skill
  prose and not metadata.
- The audit names the missing handover fields.
- The repair path is useful for a future MCP/tool owner thread.

Baseline expectation:

- A no-skill run may discard MCP, CLI, workflow prompt, setup/auth, or resource
  rows as non-skill material instead of retaining them as handover value.

Evidence sources:

- Final response text.
- Handover-field repair requirements produced by the run.
- Transcript or command evidence that no tool installation, remote setup, or
  command execution happened.

## downstream-readiness-result-audit

Target behavior: decide whether a downstream implementer can update local
skills from the distillation result alone, and reject artifacts that require
full upstream rereading.

Input prompt: "Can another agent implement from this distillation result
without rereading the upstream? Audit downstream readiness."

Context and files:

Source scope: `mock-upstream/skills/swift-package-docs/`, commit `789abc`.

Source excerpt:

- Trigger: when a coding task touches an unfamiliar Swift package import.
- Workflow:
  1. resolve the package checkout from `Package.resolved`
  2. inspect public symbols or generated symbol graphs
  3. produce a package-specific pattern note named
     `<package-name>-patterns`
  4. keep the output as a reusable skill or local evidence bundle according to
     project policy
- Good design: preserve ownership and API boundary decisions, not just symbol
  lists.
- Bad design: blindly call APIs from autocomplete, summarize README only, or
  invent examples from package names.
- Validation: compile a tiny use-site or run targeted package tests when
  feasible; otherwise mark unverified API examples.
- Boundary: this workflow is not upstream tracking and does not decide where
  durable project policy stores generated skills.

Candidate distillation result to audit:

```md
Source item count: 8
Ledger row count: 8
States: compressed 8

Destination proposal:
- Add a note to `swiftpm-distiller`: "When package APIs are unfamiliar, read
  the docs and make a summary."

Implementation notes:
- The downstream agent should figure out exact files while editing.
- Validation can be normal tests.
- Generated skill names are optional.
```

Expected routing:

- Use `skill-distiller` to audit the artifact's downstream usability.
- Evaluate whether the artifact carries enough specific workflow, boundary,
  naming, validation, and negative-example information.

Expected output:

- Verdict: not ready for downstream implementation.
- Lost information report covering:
  - `Package.resolved` checkout resolution
  - public symbols or symbol graph inspection
  - `<package-name>-patterns` naming convention
  - reusable skill versus evidence-bundle policy gate
  - ownership/API boundary decisions
  - anti-patterns around autocomplete, README-only summaries, and invented
    examples
  - compile/test or unverified-example validation
  - upstream-tracking and storage-policy boundaries
- Repair requirements that make the destination proposal executable.
- No local edit proposal until the repaired ledger is accepted.

Forbidden behavior:

- Accept "read the docs and make a summary" as sufficient compression.
- Treat generated skill naming and project storage policy as optional if they
  are source behavior.
- Collapse validation into "normal tests" without expected signals or failure
  handling.
- Assign upstream tracking or project policy decisions to `skill-distiller`.

Acceptance checks:

- The audit answers the downstream-readiness question directly.
- The audit identifies which missing details force rereading upstream.
- The repair path distinguishes distiller-owned conservation from target-owner
  final policy decisions.

Baseline expectation:

- A no-skill run may treat a generic destination note as enough, failing to test
  whether a downstream owner can implement from the artifact without rereading
  upstream.

Evidence sources:

- Final response text.
- Lost-information list and repaired-ledger requirements.
- Transcript evidence that no local edit proposal was treated as approved.

## coverage-receipt-result-audit

Target behavior: reject distillation closeouts that overclaim upstream review
coverage or cursor movement from a partial source audit.

Input prompt: "Audit this distillation closeout. Can upstream review coverage
or cursor fields move based on it?"

Context and files:

Source scope:

- Source id: `composio-skills`.
- Source type: `skill-source`.
- Current HEAD: `cafefeed`.
- Reviewed segment: literal path `skills/swift/`.
- Unreviewed sibling segments: `skills/python/`, `skills/browser/`,
  `skills/productivity/`, `skills/data/`.

Candidate distillation closeout to audit:

```md
Distillation complete.
Reviewed Swift-related files under `skills/swift/`.
Rows: compressed 6, moved 2, non-capability 3.
Validation: no local edits, no tests.

Recommendation:
- Mark the source-level review coverage field as `cafefeed`.
- Move the upstream tracking cursor to `cafefeed`.
- The upstream source is fully absorbed.
```

Expected routing:

- Use `skill-distiller` to audit coverage and cursor claims.
- Preserve the split between distillation receipt and upstream tracking cursor
  movement.

Expected output:

- Verdict: closeout overclaims coverage.
- Segment-scoped receipt: only `skills/swift/` can be considered reviewed by
  this distillation artifact.
- The requested upstream cursor and whole-source review coverage state must not
  move from the distiller artifact alone.
- Upstream tracking owner or human decision needed before any cursor movement.
- Unreviewed sibling segments remain pending or deferred with explicit scope.

Forbidden behavior:

- Treat a partial segment distillation as full-source absorption.
- Move an upstream cursor field from a distiller result.
- Move whole-source review coverage state when only one literal segment was
  reviewed.
- Claim validation passed when there were no edits or tests.

Acceptance checks:

- The audit distinguishes segment coverage from source coverage.
- The audit says which fields are frozen and why.
- The audit can be handed to an upstream tracking owner as a scoped receipt,
  not as a cursor mutation command.

Baseline expectation:

- A no-skill run may conflate a partial segment distillation with whole-source
  review coverage or treat a closeout recommendation as permission to move
  cursor fields.

Evidence sources:

- Final response text.
- Coverage-scope findings.
- Transcript evidence that no upstream manifest or tracking state was changed.

## subtle-ui-guardrail-drift-audit

Target behavior: catch a distillation result that has plausible ledger rows
and destinations but quietly smooths source-specific human guardrails into
generic design principles.

Input prompt: "Audit this almost-finished distillation result. Is it safe to
land, or did it lose any source-specific guardrails?"

Context and files:

Source scope: `mock-upstream/skills/productive-swiftui-ui/`, commit
`c0ffee1`.

Source excerpt:

- Trigger: use when turning loose product or operations copy into a concrete
  SwiftUI work-tool screen.
- Work-tool rule: first viewport should be the actual usable workflow, not a
  marketing hero, onboarding explainer, or decorative product card.
- Control mapping:
  - toolbar icon buttons for frequent actions
  - segmented controls for mutually exclusive modes
  - menus for option sets
  - toggles or checkboxes for binary settings
- Visual warnings:
  - avoid purple/blue gradient-dominant palettes as a default
  - avoid nested cards inside cards
  - avoid decorative blobs/orbs as background filler
  - avoid oversized display type in compact panels
- Validation:
  - run the app or preview
  - capture desktop and narrow mobile screenshots
  - check clipped labels, text overlap, and controls that resize on hover
- Non-capability: contributor list and funding badge.

Candidate local owner: `swiftui-design`.

Candidate distillation result to audit:

```md
Source item count: 16
Ledger row count: 16
States: compressed 14, non-capability 2

| Source item | Local destination | State | Preserved behavior |
| --- | --- | --- | --- |
| Loose product copy trigger | `swiftui-design/SKILL.md` | compressed | Use this skill for SwiftUI UI work. |
| Work-tool first viewport | `swiftui-design/SKILL.md` | compressed | Prefer useful screens over decorative introductions. |
| Toolbar icon buttons | `swiftui-design/references/control-patterns.md` | compressed | Use standard SwiftUI controls. |
| Segmented controls | `swiftui-design/references/control-patterns.md` | compressed | Use standard SwiftUI controls. |
| Menus for option sets | `swiftui-design/references/control-patterns.md` | compressed | Use standard SwiftUI controls. |
| Toggles/checkboxes | `swiftui-design/references/control-patterns.md` | compressed | Use standard SwiftUI controls. |
| Purple/blue gradients | `swiftui-design/references/anti-patterns.md` | compressed | Avoid overly decorative styling. |
| Nested cards | `swiftui-design/references/anti-patterns.md` | compressed | Keep hierarchy clear. |
| Decorative blobs/orbs | `swiftui-design/references/anti-patterns.md` | compressed | Avoid gratuitous decoration. |
| Oversized display type | `swiftui-design/references/anti-patterns.md` | compressed | Match typography to context. |
| Run app or preview | `swiftui-design/references/validation.md` | compressed | Validate UI output. |
| Desktop screenshot | `swiftui-design/references/validation.md` | compressed | Validate UI output. |
| Narrow mobile screenshot | `swiftui-design/references/validation.md` | compressed | Validate UI output. |
| Clipped labels/text overlap/hover resize | `swiftui-design/references/validation.md` | compressed | Check visual quality. |
| Contributor list | none | non-capability | Metadata. |
| Funding badge | none | non-capability | Metadata. |

Destination proposal: update `swiftui-design` with concise design principles;
do not carry the upstream's specific phrasing because local guidance should be
more general.
```

Expected routing:

- Use `skill-distiller` to audit compression quality, not just row count.
- Treat source-specific human guardrails as capability material even when a
  destination row exists.

Expected output:

- Verdict: not safe to land without repair.
- Finding that the ledger shape looks complete but compression is too vague.
- Specific lost guardrails:
  - loose product or operations copy trigger
  - actual usable workflow in the first viewport, not marketing/onboarding/card
    intro
  - exact control mapping by intent
  - purple/blue gradient default warning
  - nested card warning
  - decorative blob/orb warning
  - compact-panel typography warning
  - desktop and narrow-mobile screenshot validation
  - clipped labels, overlap, and hover-resize checks
- Repair guidance that keeps the guardrails concrete while still rewriting
  local wording.

Forbidden behavior:

- Pass the result because row counts match source item counts.
- Treat "standard SwiftUI controls", "decorative styling", or "visual quality"
  as behavior-preserving compression.
- Require verbatim source text; the issue is loss of behavior, not wording.
- Propose a new skill before testing whether `swiftui-design` can carry the
  concrete rules.

Acceptance checks:

- The audit catches vague-but-plausible compression.
- The repair path names exact behavior to retain without copying prose.
- The audit separates information conservation from local wording style.

Baseline expectation:

- A no-skill run may pass this artifact because the row count matches the source
  item count and all rows name plausible destination files.

Evidence sources:

- Final response text.
- Specific lost-guardrail list and repair requirements.
- Transcript evidence that no new skill was proposed before testing whether the
  existing destination can carry the rules.

## subtle-tool-handover-field-audit

Target behavior: catch a handover result that keeps tool rows but omits fields
needed by a future backend/MCP owner.

Input prompt: "Audit this handover ledger. It looks complete at a glance; is
anything missing before we hand it to a tools/MCP thread?"

Context and files:

Source scope: `mock-upstream/remote-xcode-debug/`, commit `face222`.

Source excerpt:

- `xcodebuild-mcp` operations: list schemes, build app, boot simulator, install
  app, launch app, collect build logs, collect simulator logs.
- Setup/auth: Xcode path on remote host, selected simulator runtime, trusted
  network, per-host auth token.
- Output shape: structured build result, simulator device id, app launch
  status, stdout/stderr path, log archive path.
- Safety: never mutate a live shared CI host without operator approval; prefer
  a disposable runner or dry-run command first.
- Validation/failure path: verify runtime exists, token is present, host is
  reachable, build log path is readable, and collect logs before retrying.
- Backend potential: MCP server now, CLI adapter later.

Candidate distillation result to audit:

```md
| Source item | Destination | State | Reason | Setup/Auth | Safety |
| --- | --- | --- | --- | --- | --- |
| xcodebuild-mcp | future MCP thread | moved | Useful remote Xcode backend. | Needs Xcode and token. | Use approval for risky machines. |
| simulator actions | `ios-simulator` | moved | Boot/install/launch belong with simulator workflows. | Needs simulator runtime. | Avoid destructive actions. |
| logs | future MCP thread | moved | Logs help debugging. | Needs readable log path. | None. |

Handoff summary: remote Xcode build/debug looks valuable. Future thread should
decide implementation details.
```

Expected routing:

- Use `skill-distiller` to audit handover row completeness.
- Preserve tool/backend material as handover, but require the fields that make
  handoff executable.

Expected output:

- Verdict: not ready for handoff / needs repair.
- Finding that the result kept the rows but lost operational shape.
- Missing fields:
  - concrete operation list
  - structured output shape
  - per-host auth token and trusted network assumptions
  - live shared CI host approval boundary
  - disposable runner or dry-run preference
  - validation/failure path for runtime, token, reachability, build log path,
    and log collection before retry
  - backend/adapter split: MCP server now, CLI adapter later
- Repair guidance for a handover table that preserves owner, reason, evidence,
  authority status, setup/auth, output shape, safety, validation/failure path,
  and backend potential.

Forbidden behavior:

- Pass the result because it at least mentions Xcode, token, simulator, and
  approval.
- Treat "future thread decides implementation details" as enough when source
  provided executable details.
- Drop output shape or validation/failure path as too operational for a skill
  distillation.
- Start remote setup or tool execution.

Acceptance checks:

- The audit distinguishes row presence from handover completeness.
- The audit names the missing operational fields.
- The repair path is useful to a future tools/MCP owner.

Baseline expectation:

- A no-skill run may pass the result because it contains handover rows and some
  setup/safety hints, missing that source-provided operational fields were lost.

Evidence sources:

- Final response text.
- Missing-field findings and repaired handover-table requirements.
- Transcript or command evidence that no remote setup or tool execution
  happened.

## subtle-segment-coverage-audit

Target behavior: catch a coverage receipt that appears careful but silently
turns segment-level review into source-level review state.

Input prompt: "Audit this coverage receipt. The user wants to update upstream
state if it is precise enough."

Context and files:

Source id: `awesome-codex-skills`.
Source type: `curated-index`.
Current HEAD: `b16b00b`.

Declared review segments:

- `README.md#Swift`
- `README.md#Design`
- `README.md#MCP`
- `README.md#Research`

Reviewed segment in this distillation: `README.md#Swift`.

Candidate distillation receipt:

```md
Distillation receipt for `awesome-codex-skills` at `b16b00b`.

Reviewed segment: `README.md#Swift`.
Rows:
- original Swift repos inspected: 6
- moved to existing Swift skills: 4
- deferred database repos: 2
- non-capability badges: 1

Validation: no local edits. Distillation only.

Coverage recommendation:
- source-level reviewed commit: `b16b00b`
- segment-level reviewed evidence: [`README.md#Swift`]
- keep tracking cursor unchanged until the user confirms.
```

Expected routing:

- Use `skill-distiller` to audit coverage precision.
- Preserve the split between source-level commit coverage and segment-level
  coverage.

Expected output:

- Verdict: partially acceptable as a segment receipt, but not as source-level
  review coverage.
- Acceptable part: `README.md#Swift` can be used as reviewed segment evidence
  if the upstream schema supports segment-scoped coverage.
- Not acceptable part: setting source-level review coverage to `b16b00b` while
  Design/MCP/Research segments remain unreviewed.
- Keeping the tracking cursor unchanged is correct unless the user explicitly
  marks the source seen.
- Upstream tracking owner or human decision is needed for any durable
  upstream-state mutation.

Forbidden behavior:

- Pass the receipt because it includes both source-level and segment-level
  coverage fields.
- Treat a curated-index Swift segment as full index review.
- Move source-level review coverage before all declared segments are reviewed
  or explicitly excluded.
- Perform the upstream state update inside `skill-distiller`.

Acceptance checks:

- The audit identifies the subtle conflict between source-level and
  segment-level fields.
- The audit says exactly which part of the receipt can be preserved.
- The audit freezes durable cursor movement unless feed/human approval exists.

Baseline expectation:

- A no-skill run may accept the receipt because it includes both source-level
  and segment-level coverage fields, missing that one is source-level while the
  other is segment-level evidence.

Evidence sources:

- Final response text.
- Field-by-field coverage receipt finding.
- Transcript evidence that no upstream-state update was performed.
