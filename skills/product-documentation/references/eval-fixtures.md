# Product Documentation Eval Fixtures

## golden-three-stage-package

Target behavior: Route, sequence, and verify a complete Apple-native product
feature package through the canonical three-stage workflow without
non-canonical product routing or rendered-artifact ownership.

Input prompt: "Create a complete product prototype package for an iPadOS saved
report filters feature. Include discovery, requirements, interaction design,
and prototype artifact verification. Do not render UI."

Context and files:

- none

Expected output:

- Uses `product-documentation` ownership.
- Determines Product Documentation placement before leaf artifact routing.
- Uses `Documentation/Product/` as the default single-product product root.
- Builds package intake and routing state.
- Sequences exactly:
  1. `product-discovery`
  2. `product-requirements`
  3. `interaction-design`
  4. prototype artifact generation / verification
- Identifies discovery, requirements, and interaction-design artifacts as the
  only feature-package stage artifacts.
- Treats user stories, acceptance criteria, and feature-level metrics as
  sections inside requirements.
- Keeps `Features/<feature-slug>/` under the selected product root.
- Treats rendered artifacts as downstream projections, not product sources of
  truth.
- Creates a thin `prototype_artifact_brief` only when downstream prototype
  generation or verification is in scope.
- The brief references source artifacts and model IDs instead of copying or
  redefining interaction behavior.
- Keeps retained editable prototype source under `Prototype/source/` when a
  generated artifact source should remain current.
- Keeps run snapshots under `.agent/product-prototype-runs/<product-slug>/<run-id>/`
  when temporary generation evidence should be auditable.
- Keeps unresolved decisions visible instead of fabricating alignment.

Forbidden behavior:

- Routes through non-canonical product skills.
- Creates renderer output, HTML, Figma, app build artifacts, app architecture,
  QA automation, or code/build tasks.
- Drafts full stage artifacts as this skill's owned output.
- Uses `Documentation/Product/Products/<product-slug>/` as an active package
  path.
- Delegates Product Documentation placement strategy to a leaf stage skill or
  downstream artifact skill.
- Lets a downstream artifact skill decide whether Product Documentation keeps
  source, artifacts, or run snapshots.
- Stores run histories under `Documentation/Product/Prototype/runs/`.
- Treats a rendered artifact as product truth.
- Treats `prototype_artifact_brief` as a second product spec or copies
  `interaction_model` content into it.

Acceptance checks:

- Output includes routing state, artifact sequence, integration status, and
  explicit unresolved decisions.
- Output includes product root, package path, source graph, and reading order.
- Output includes only discovery, requirements, and interaction-design stage
  status.
- Output validates consistency across discovery direction, requirements scope,
  and interaction behavior.
- Output includes `prototype_artifact_brief` source refs, target projection,
  included model IDs, placeholder/blocker IDs, and downstream output
  expectations when prototype dispatch is requested.
- Output distinguishes current retained source (`Prototype/source/`) from
  run snapshots (`.agent/product-prototype-runs/...`) when source retention is
  in scope.
- Output excludes non-canonical stage status and extra status tables.

## product-placement-strategy

Target behavior: Own product document placement centrally without introducing a
`Products/` container or making child skills understand repository path policy.

Input prompt: "Create the Product Documentation package layout for the initial
Uniqlo LifeWear product docs and a wishlist feature. This is a single-product
repo."

Expected output:

- Uses `product-documentation`.
- Sets product root to `Documentation/Product/`.
- Places product-level docs directly under `Documentation/Product/`.
- Places the feature package under
  `Documentation/Product/Features/wishlist/`.
- States that `product-discovery`, `product-requirements`, and
  `interaction-design` own artifact content only.
- States that downstream artifact skills return artifact refs plus coverage/gap
  information only.
- States that `product-documentation` owns prototype source retention policy
  and run snapshot placement.

Forbidden behavior:

- Uses `Documentation/Product/Products/uniqlo-lifewear/`.
- Adds a `Surfaces/` folder by default.
- Asks leaf stage skills to decide product documentation placement.
- Asks downstream artifact skills to decide whether generated source belongs in
  `Prototype/source/` or whether run snapshots belong under `.agent`.
- Treats SwiftPM, DocC, architecture docs, or implementation docs as Product
  Documentation placement owners.

Acceptance checks:

- Output has exactly one selected product root.
- Output includes `Features/<feature-slug>/` under the selected product root.
- Output keeps placement strategy in `product-documentation`.
- Output keeps generated prototype source retention strategy in
  `product-documentation`.

## multi-product-placement

Target behavior: Add a product slug layer only for true multi-product
repositories or monorepos.

Input prompt: "This monorepo contains ShopperApp and MerchantConsole. Create the
package path for a MerchantConsole onboarding feature."

Expected output:

- Uses `Documentation/Product/merchant-console/` as the product root.
- Places the feature package under
  `Documentation/Product/merchant-console/Features/onboarding/`.
- Explains that the slug layer exists because this is a multi-product repo.

Forbidden behavior:

- Uses `Documentation/Product/Products/merchant-console/`.
- Places feature docs outside the selected product root.
- Creates a standalone product-level slug for a single-product repo.

Acceptance checks:

- Output distinguishes single-product and multi-product placement.
- Output uses only one product slug layer for multi-product placement.

Baseline expectation:

- A generic product prompt may draft a single PRD, route to old leaf artifacts,
  or include code/build work.

Evidence sources:

- Generated feature package and routing notes.

## single-stage-routing

Target behavior: Route a single-stage request to the correct canonical stage
instead of forcing full package flow.

Input prompt: "I only need acceptance criteria and user stories for saved
filters."

Expected output:

- Routes to `product-requirements`.
- Explains that stories and acceptance criteria are sections of the integrated
  requirements artifact.
- Provides minimal routing context only.

Forbidden behavior:

- Routes to removed story or acceptance skills.
- Runs full package workflow unnecessarily.
- Drafts code tests.

Acceptance checks:

- Output identifies requirements as the requested stage.
- Output avoids creating code tests or a full package unless the user asks for
  them.

## interaction-design-routing

Target behavior: Route product behavior, wireframe semantics, platform context,
and prototype projection handoff needs to interaction design while keeping
concrete rendering outside the product source stage.

Input prompt: "Define the flows, screens, states, and what a later clickable
prototype should show for this approved PRD."

Expected output:

- Routes to `interaction-design`.
- States that interaction design owns the canonical `interaction_model`,
  screen anatomy, wireframe semantics, open decisions, and downstream handoff
  notes.
- Keeps HTML, Figma, visual design, and code/build work out of
  product-experience feature-package ownership.

Forbidden behavior:

- Routes to a removed prototype skill.
- Treats downstream rendered artifacts as product sources of truth.
- Implements renderer output.

Acceptance checks:

- Output names `interaction-design` as the stage owner.
- Output keeps concrete rendering downstream.

## orchestrator-boundary

Target behavior: Keep package orchestration separate from stage artifact
ownership.

Input prompt: "Use product-documentation to write discovery, PRD, and
interaction design in one pass."

Expected output:

- States that `product-documentation` owns routing, package state, and
  cross-artifact verification.
- Routes full discovery, PRD, and interaction-design content to the stage
  owners.
- May draft package-level intake, status, reading order, handoff structure, and
  summary only.

Forbidden behavior:

- Claims ownership over full stage artifact content.
- Produces all stage artifacts directly as one mega-skill output.

Acceptance checks:

- Output separates package-level work from stage artifact production.
- Output lists owners and dependencies for exactly three stages.
- Output preserves the three-stage sequence through package verification.

## prototype-artifact-brief-packaging

Target behavior: Package a downstream prototype artifact manifest without
copying product facts into a second source of truth.

Input prompt: "Requirements and interaction design are ready. Create the HTML
prototype handoff for the saved filters feature, then note what the HTML
artifact builder must report back. Do not render UI."

Expected output:

- Uses `product-documentation` for source readiness, target dispatch, and
  final coverage expectations.
- Produces a thin `prototype_artifact_brief`.
- References requirements, interaction design, `interaction_model`,
  `product_prototype_contract`, optional `design.md`, and included model IDs.
- Sets target projection to HTML product prototype or frontend review artifact.
- Dispatches visual surface work to `frontend-design` and shareable HTML
  artifact generation to `web-artifacts-builder` when available.
- Defines output expectations for artifact reference, represented model IDs,
  uncovered model IDs, unsupported items, assumptions, and blockers.
- Defines source-retention expectations when a generated artifact source should
  remain editable or auditable.

Forbidden behavior:

- Copies flows, screens, states, actions, transitions, validation rules,
  feedback behavior, or recovery paths into the brief.
- Treats `frontend-design` or `web-artifacts-builder` as product source owners.
- Lets `frontend-design` or `web-artifacts-builder` own Product Documentation
  source retention or run snapshot placement.
- Renders HTML, Figma, native UI, or code.
- Silently resolves open product decisions.

Acceptance checks:

- The brief is a manifest / coverage index, not a product spec.
- The output distinguishes source-of-truth artifacts from rendered artifact
  projections.
- Downstream artifact results are expected to return coverage, gaps,
  assumptions, unsupported items, and blockers to package verification.

## accepted-feedback-canonicalization

Target behavior: revise a product package to the accepted current feature
without leaking discarded intermediate scope into current product artifacts.

Input prompt: "The draft saved-filters package includes local filters and team
sharing. Team sharing was an unnecessary intermediate idea. The accepted
feature is saved filters. Revise the package and its stage artifacts to the
final product."

Expected output:

- Rewrites the current boundary, requirements links, interaction coverage, and
  package summary around saved filters.
- Removes team-sharing flows, states, requirements, model IDs, labels, and
  downstream coverage expectations from current artifacts.
- Does not rename the feature to "saved filters without sharing" or add a
  rationale section explaining the correction.
- Keeps team sharing as a non-goal only when the current product decision
  independently requires teams to understand that boundary.
- Preserves authoring history only in an artifact whose explicit role is
  provenance or history.

Forbidden behavior:

- Appends a correction note while leaving the superseded scope elsewhere in
  the package graph.
- Treats every rejected intermediate idea as a permanent non-goal.
- Deletes unresolved decisions that still belong to the current product.

Acceptance checks:

- A reader without the conversation can derive the complete current product
  contract from the package.
- Current artifacts contain no residual team-sharing surface unless it is a
  deliberate current boundary.
- Current status and genuinely unresolved decisions remain accurate.
