---
name: interaction-design
description: >-
  Draft, revise, or review interaction design for product workflows: canonical
  interaction_model artifacts, platform expression, flows, screens, screen
  anatomy, wireframe semantics, states, actions, transitions, validation,
  feedback, recovery, permission and system-mediated handoffs, edge cases,
  product prototype contract, prototype projection notes, UX interaction
  quality for existing screenshots, prototypes, wireframes, or product
  surfaces, and explicit local Flinto prototype-tool cache/state recovery. Use
  for product behavior interaction design, product prototype definition,
  interaction-quality review after discovery or requirements context exists,
  and Flinto local-state cleanup only when explicitly requested. Do not use for
  full PRDs, high-fidelity visual design, final platform-convention authority,
  polished UX writing, rendered prototype generation, live design-tool edits,
  code output, code/build planning, platform API mechanics, or general app
  cleanup.
---

# Interaction Design

## Purpose

Use this skill to define, revise, or review how a user and the system move
through a product workflow. It owns interaction behavior at the workflow level:
what the user can do, what the system does in response, what state the product
enters, how users recover, and what the product prototype must preserve.

The primary source artifact is a canonical `interaction_model` when structured
behavior is needed. The model has two owned layers:

- `behavior`: product interaction facts, including flows, screens, states,
  actions, transitions, validation, feedback, recovery, edge cases, and open
  decisions.
- `platform`: platform expression bindings, including target surface, adapter,
  device bezel, scene/state/component/action/transition/feedback presentations,
  constraints, and projection notes.

Existing screenshots, prototypes, wireframes, and product surfaces are review
projections or evidence unless the user explicitly accepts their behavior back
into `behavior`. Rendered artifacts must not create a second interaction
model.

This skill owns the product prototype contract: the flows, screens, states,
actions, transitions, coverage expectations, projection targets, gaps, and
blocked decisions that a Figma, HTML, or review prototype must represent.
Downstream artifact skills render that contract; they do not define product
behavior.

This skill is product-and-design workflow ownership, not a traditional
department boundary. It covers product-owned behavior contracts and UX
interaction quality, while keeping visual design polish, final platform
convention authority, polished copy, renderer execution, and code/build
mechanics in their owning lanes.

## When To Use

- The user asks for interaction design, flow requirements, product behavior,
  state behavior, screen anatomy, wireframe semantics, or an
  `interaction_model`.
- A PRD or requirements artifact needs a platform-aware interaction layer
  before prototype artifact generation or prototype review.
- The user asks what a product prototype should show, cover, omit, block, or
  validate.
- A screenshot, prototype, wireframe, product surface, or structured
  interaction artifact needs interaction-quality review.
- Interaction-model research needs local research artifacts from public
  design/prototyping resources, such as Rive runtime `.riv` files.
- The user explicitly asks to clear, reset, or troubleshoot local Flinto cache,
  Application Support, or prototype-tool state.
- A user task is blocked by account state, data state, permissions, external
  settings, OS authorization, or another system-mediated handoff.
- A downstream prototype owner needs stable source data for flows, states,
  actions, transitions, feedback, recovery, open decisions, and coverage.
- An Apple native, web, desktop, or cross-platform app needs interaction intent
  before platform-convention review or build work.

## When Not To Use

- Full discovery, PRD, feature spec, user-story, acceptance-criteria, roadmap,
  or market strategy work as the primary output.
- High-fidelity visual design, design-system tokens, spacing, colors,
  typography, icon design, illustration, or visual polish.
- Final HIG, Material, web, or platform-convention authority as the primary
  output; use the relevant platform guidance/review lane when final platform
  conformance matters.
- Polished product-facing copy, microcopy, empty-state prose, alert wording, or
  terminology as the primary output; use the interface writing owner.
- HTML/CSS/React, SwiftUI/AppKit, UIKit, Android, backend, API, component
  architecture, code output, build, test, or QA automation work.
- Concrete rendered prototype generation, Figma MCP operations, live design-tool
  edits, or app rendering.
- Platform API details, System Settings URL schemes, TCC database behavior,
  pasteboard/drag provider mechanics, entitlement files, signing, or native
  permission build details; route macOS TCC mechanics to
  `macos-tcc-permissions-patterns` when that skill is available.
- General app uninstallers, broad cache cleaners, system cleanup, or local
  data deletion for apps other than Flinto unless another dedicated skill or
  user-provided script owns that workflow.
- Store, launch, ASO, paid acquisition, SEO, or market messaging.

## Inputs To Inspect

- Product goal, audience, task context, success criteria, and risk level.
- Product discovery and requirements artifacts when available.
- Existing screenshots, prototypes, wireframes, product surfaces, design
  handoff notes, or structured interaction artifacts.
- Target platform expression: target surface, adapter, device bezel, input methods,
  presentation/navigation constraints, accessibility constraints, and known
  system surfaces.
- Data states: loading, empty, partial, populated, validation, disabled,
  submitting, processing, error, offline, conflict, permission denied, success.
- Role, account, plan, entitlement, and system-permission constraints.
- System-mediated permission gates, external settings handoffs, authorization
  subjects, blocked states, fallback behavior, and recovery expectations.
- External build constraints only when they change user-visible interaction
  choices or prototype feasibility.

## Workflow

1. Confirm the interaction scope: feature, journey slice, existing artifact
   review, permission handoff, or state transition set.
2. Identify actors, entry points, exits, exclusions, success criteria, and the
   primary user task.
3. If the task needs source behavior, draft or revise one canonical
   `interaction_model` using `references/canonical-model-template.md`.
4. Capture platform expression separately from product behavior: target
   surface, platform adapter, device bezel, platform primitives, input methods,
   constraints, adaptation notes, and platform review status.
5. Model flows, screens, screen anatomy, wireframe semantics, states, actions,
   transitions, components, validation, business rules, feedback, edge cases,
   loading/empty/error/disabled behavior, and recovery.
6. For permission-gated or system-mediated tasks, capture the platform,
   required permission, authorization subject, blocked state, user-visible
   handoff action, system response, granted/denied/cancelled transitions,
   fallback, recovery, and re-entry behavior.
7. For existing artifacts, review navigation clarity, control intent, feedback,
   density, accessibility risks, no-dead-end behavior, and whether the artifact
   preserves the source interaction model.
8. Validate traceability to requirements, user stories, acceptance criteria, or
   source evidence when those inputs are available.
9. Record open decisions with blocking semantics for interaction design,
   downstream projection, prototype artifact generation, or prototype
   verification.
10. Define the product prototype contract and projection coverage expectations
   without choosing or implementing a renderer.
11. Separate product behavior decisions, interaction-quality findings,
   platform-convention review needs, copy placeholders, and external build
   constraints.
12. For research/resource-capture tasks, collect only the requested public
    research artifacts, record source URLs and hashes, and keep them separate
    from canonical product behavior.
13. For explicit Flinto local-state cleanup, read
    `references/flinto-state-cleanup.md`, run
    `scripts/flinto-cli` in dry-run mode first, execute only when
    requested or confirmed, and report scope, process handling, removed paths,
    protected residuals, and permission errors.

## Reference Files

- `references/canonical-model-template.md`: structured interaction model
  template for source artifacts.
- `references/canonical-model-example.md`: completed interaction model example.
- `references/permission-handoffs.md`: blocked-state and system-permission
  handoff patterns, including macOS TCC-style drag authorization.
- `references/interaction-models.md`: compact flow, state, control,
  navigation, and feedback patterns for review work.
- `references/review-rubric.md`: interaction-quality review checklist.
- `references/product-source-ledger.md`: provenance for absorbed product
  interaction-model behavior.
- `references/canonical-model-eval-fixtures.md`: durable behavior fixtures for
  model generation and boundary checks.
- `references/resource-capture.md`: research-artifact capture rules, including
  the Rive public `.riv` runtime capture helper.
- `references/research/README.md`: formal app-level research corpus for
  interaction and UI-layer schema work. Use it for schema research tasks, not
  ordinary interaction-model drafting.
- `references/flinto-state-cleanup.md`: local Flinto cache, Application
  Support, and container-state cleanup script usage and safety rules.

Read references only when the task needs that depth.

## Decision Rules

- Start from the user's task, expected outcome, and current artifact evidence.
- Keep one canonical `interaction_model` when source behavior is needed, with
  product facts in `behavior` and platform expression in `platform`.
- Treat rendered prototypes, screenshots, and design frames as projections or
  evidence unless explicitly accepted as source truth.
- Describe behavior in observable product terms, not build terms.
- Stable IDs are required when downstream projections, requirements, or
  prototype coverage will reference flows, screens, states, actions,
  transitions, components, rules, or edge cases.
- Actions describe user/system triggers and product intent. Transitions
  describe resulting state or screen changes.
- Platform expression may reference behavior IDs but must not define or
  recombine behavior. `platform` cannot add flows, screens, states, actions, or
  transitions that are absent from `behavior`.
- Do not put `resulting_screen`, `resulting_state`, `to_screen`, `to_state`, or
  product success/failure semantics in platform presentation bindings. Those
  belong in `behavior.transitions`.
- `platform.action_presentations` describe how existing actions are exposed as
  affordances or controls; they must not include transition results.
- `platform.transition_presentations` describe how existing transitions are
  presented on the platform; they must only reference transition IDs already
  defined in `behavior.transitions`.
- Apple official resources, HIG primitives, system fonts, SF Symbols, product
  bezels, safe area constraints, and platform navigation/presentation patterns
  belong in `platform`, not in `behavior`.
- Do not define final margins, pixel spacing, brand colors, typography scales,
  corner radii, or polished visual treatment. Route those to design/style
  artifacts such as `design.md`, visual design, or frontend/Figma artifact
  skills.
- Keep canonical triggers real. Use user actions, system events, API outcomes,
  permission outcomes, timers, or platform events in `actions` and
  `transitions`; do not use prototype-only controls such as "mock failure
  toggle", "debug switch", or "reviewer selects failure" as product triggers.
- If a prototype needs controls that let reviewers jump to loading, error,
  unavailable, success, or edge states, model them separately as
  `prototype_projection_controls` or reviewer notes. These controls expose
  existing model IDs and must sit outside the simulated app shell or be clearly
  marked as reviewer-only; they do not create product behavior.
- Use state machines when guards, impossible states, async behavior,
  gesture/undo/cancel semantics, or no-dead-end checks materially affect the
  product behavior.
- Treat permission onboarding as interaction design when it blocks a user task.
  Model the required permission, authorization subject, blocked state, handoff
  action, system response, success/denial/cancellation transitions, fallback,
  recovery, and task re-entry.
- Model permission handoffs per platform. A macOS TCC-style flow may involve
  System Settings, an app/helper identity, and a manual trust list; an iOS
  family flow may involve a system prompt or Settings deep link; web and other
  desktop platforms have different recovery surfaces.
- For macOS drag-to-authorize onboarding like the screenshot pattern, capture
  the interaction as: blocked task -> direct system-settings handoff ->
  visible draggable authorization object -> target-system-surface guidance ->
  authorization result -> task re-entry. Keep URL schemes, drag item providers,
  Accessibility automation, and TCC mechanics in `macos-tcc-permissions-patterns`
  or other external build constraint notes.
- Make system status, next action, and consequence visible before the user
  commits.
- Provide undo, retry, cancel, back, dismiss, preview, confirmation, staged
  commit, or fallback for risky, expensive, destructive, public, permissioned,
  or hard-to-reverse actions.
- Platform guidance findings can influence the model only after accepted
  behavior changes are represented in the model.
- Copy recommendations are functional placeholders unless the task asks for
  polished interface writing.
- Do not silently resolve source conflicts. Record the decision, options,
  owner, blocking impact, and fallback if available.
- Treat captured design/prototype resources as research artifacts. They can
  inform donor research or platform expression, but they do not become product
  behavior source of truth.
- Treat Flinto local-state cleanup as a narrowly scoped prototype-tool recovery
  exception. It does not define product behavior, does not edit a live design
  tool document, and must not become a general macOS cleanup workflow.
- For Flinto cleanup, default to dry-run, restrict deletion to explicit
  Flinto-named paths under the user's `~/Library` or the Flinto app container,
  quit Flinto before live deletion, and never delete `/Applications/Flinto.app`,
  user project files, or exported artifacts.
- If macOS leaves
  `~/Library/Containers/com.flinto.Flinto/.com.apple.containermanagerd.metadata.plist`
  after an all-scope reset, report it as an OS-protected container-manager
  residual when all other container data has been removed.
- Do not invent research findings or platform rules. Label assumptions and
  route final platform conformance to the relevant guidance/review owner.

## Validation Rules

- Output has either one canonical `interaction_model`, an interaction review
  tied to a supplied artifact, or a clearly scoped delta to an existing model.
- Source behavior covers material flows, screens, screen anatomy, wireframe
  semantics, states, actions, transitions, components, validation rules,
  business rules, feedback patterns, edge cases, and recovery.
- `behavior` contains product facts. `platform` contains only platform
  expression bindings that reference behavior IDs.
- Every `platform` reference to a screen, state, component, action, transition,
  validation, feedback, or edge case resolves to an ID in `behavior`.
- `platform` does not define transition destinations, resulting states,
  success/failure semantics, product rules, or new user tasks.
- `platform.device_bezel` records the device frame source when a projection
  should use an official Apple resource, generated CSS frame, browser window,
  or no bezel.
- `platform` excludes final visual styling values such as exact margins,
  colors, typography sizes, and corner radii unless they are referenced only as
  external design/style artifacts.
- When prototype generation or review is in scope, output includes a
  `product_prototype_contract` or equivalent section that states required
  screens, flows, click paths, states, validation/feedback, recovery paths,
  permission handoffs, explicit non-goals, blockers, and coverage verification
  notes.
- Requirements, user-story, acceptance-criteria, or evidence traceability is
  explicit when those sources are available.
- Platform-aware work captures target surface, adapter, device bezel, input
  methods, navigation/presentation primitive bindings, constraints, adaptation
  notes, and review status in `platform`.
- Permission-gated tasks identify platform, permission, authorization subject,
  blocked/granted/denied/cancelled states, handoff action, fallback, recovery,
  and re-entry behavior.
- Loading, empty, disabled, validation error, permission denied, submitting,
  processing, cancellation, retry, fallback, and success states are covered
  when relevant.
- Navigation gives the user a way forward, back, out, or into a defined
  fallback.
- Prototype projection notes derive from the interaction model and do not
  create a second source of truth.
- Prototype projection controls, when present, are explicitly separated from
  app UI and from canonical `actions`/`transitions`; they expose modeled states
  for review and coverage only.
- Findings distinguish product behavior decisions from interaction-quality
  refinements, platform-review needs, copy placeholders, and external build
  constraints.
- Flinto cleanup output reports script scope, dry-run or execute mode, Flinto
  process handling, removed/skipped paths, protected residuals, and permission
  errors; live cleanup does not remove the application bundle or project files.
- Output excludes high-fidelity visual specs, renderer code, component
  architecture, platform API mechanics, and live design-tool operations.

## Output Format

Use local repository conventions when available. Otherwise, for source
artifacts prefer:

````text
Interaction Design: <feature>

Scope:
- ...

Canonical interaction_model:
```yaml
interaction_model:
  version: "1"
  feature: ...
  behavior:
    flows: []
    screens: []
    states: []
    actions: []
    transitions: []
  platform:
    target_surface: ...
    adapter: ...
    device_bezel:
      type: ...
```

Flow / state summary:
- ...

Permission and system handoffs:
- ...

Projection coverage:
- ...

Product prototype contract:
- ...

Traceability:
- ...

Open decisions:
- ...
````

For artifact reviews, prefer:

```text
Interaction Review

Artifact reviewed:
- ...

Primary task:
- ...

Findings:
- Severity: issue, impact, recommendation

Flow / states:
- ...

Product behavior deltas:
- ...

Handoff notes:
- ...

Open questions:
- ...
```

## Failure / Uncertainty Handling

- If the user task is unclear, infer the most likely task from the artifact and
  label the assumption.
- If the artifact is missing, ask for the smallest useful input: product goal,
  requirements, screenshot, prototype, wireframe, target platform, or success
  criterion.
- If platform behavior may have changed or final platform conformance matters,
  verify through the relevant platform guidance/review owner before treating it
  as authoritative.
- If a permission handoff depends on build feasibility, model the desired
  user-visible behavior and mark external build constraints for the engineering
  owner.
- If the task asks for a rendered prototype, provide interaction source data or
  the product prototype contract, then route rendering to the appropriate
  artifact owner.
- If external build constraints conflict with ideal interaction, propose the
  smallest behavior-preserving refinement that keeps clarity and recovery.
- If Flinto cleanup hits macOS-protected container metadata, verify whether
  only the protected metadata file remains and report the residual instead of
  treating it as remaining Flinto user data.
