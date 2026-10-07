# Interaction Design Canonical Model Eval Fixtures

## canonical-interaction-model-for-downstream-consumers

Target behavior: Produce the canonical platform-aware `interaction_model` that
downstream consumers can use without inventing separate platform expression,
flows, screens, screen anatomy, wireframe semantics, states, actions, or
transitions.

Input prompt: "Turn these saved-report-filter requirements into a structured
interaction model downstream artifacts can consume."

Context and files:

- PRD / requirements artifact, target Apple platform context, optional
  user-story sections, and optional acceptance-criteria sections supplied in
  the prompt or attached files.

Expected output:

- Uses `interaction-design` ownership.
- Produces one top-level `interaction_model`.
- Structures `interaction_model` as two layers: `behavior` for product facts
  and `platform` for platform expression.
- Includes `platform` with target surface, adapter, `device_bezel`, input
  methods, platform constraints, adaptation notes, platform primitive
  presentations, and platform/UX convention guidance/review status when
  platform context is supplied.
- Covers flows, screens, states, actions, transitions, components, validation
  rules, business rules, feedback patterns, edge cases, screen anatomy, and
  wireframe semantics in `behavior`.
- Adds platform expression bindings for relevant screens, states, components,
  actions, transitions, feedback, and validation without redefining behavior.
- Includes state-machine semantics when guards, async behavior, impossible
  states, gesture fallback, or no-dead-end checks are material.
- Includes projection coverage expectations, target handoff notes, prohibited
  downstream inventions, and projection gaps without choosing or implementing a
  renderer.
- Includes `product_prototype_contract` when prototype generation or prototype
  review is in scope, with required screens, flows, states, click paths,
  validation, feedback, recovery, permission handoffs, non-goals, blockers,
  placeholders, and coverage verification notes linked to model IDs.
- Links interaction items to requirements, user-story sections, and
  acceptance-criteria sections when those links are available.
- Notes that downstream artifacts may consume the model later, but must not
  create a second interaction model.
- Marks open decisions with downstream projection, prototype generation, and
  prototype verification blocking semantics.

Forbidden behavior:

- Generates rendered artifacts, visual styling, or downstream projection files.
- Claims platform compliance as final authority without external review
  findings.
- Treats visual styling inputs as a product behavior source.
- Pushes interaction decisions into rendered artifacts.

Acceptance checks:

- Output includes stable IDs for flows, screens, states, actions, transitions,
  components, rules, and edge cases.
- Output includes `behavior` and `platform` sections.
- Output includes `platform.target_surface`, `platform.adapter`,
  `platform.device_bezel`, and Apple platform adaptation notes when Apple
  platform expression is in scope.
- Output includes screen intent, content regions, action hierarchy, and
  state-specific visible elements for material screens.
- Output keeps actions and transitions non-duplicative: actions are triggers
  and intent; transitions are resulting state/screen changes.
- Output keeps platform bindings non-behavioral: platform may reference action
  IDs and transition IDs, but it does not define resulting screen/state,
  success path, failure path, product rule, or new task.
- Output includes `platform.action_presentations` for action affordances and
  `platform.transition_presentations` for presentation style when a platform
  adapter is in scope.
- Output excludes exact margins, colors, typography sizes, corner radii, and
  brand polish from the interaction model.
- Output uses real product triggers for canonical actions and transitions. If a
  rendered prototype needs reviewer-only state or failure controls, those are
  separated into projection controls or review notes and are not treated as
  product UI.
- Open decisions include `blocks_projection`, `blocks_prototype_generation`,
  `blocks_prototype_verification`, `blocks_interaction_design`,
  `fallback_allowed`, `blocked_artifacts`, and unresolved impact when relevant.
- Output includes traceability to requirements and, when available, user-story
  and acceptance-criteria sections.
- Output explicitly preserves product behavior ownership in
  `interaction-design`.
- Output includes `product_prototype_contract` as the product-side prototype
  design output, not a renderer instruction set.
- Output includes downstream prototype projection, Figma, HTML, and prototype
  review handoff notes without implementing renderer artifacts.

Baseline expectation:

- A generic interaction response may provide narrative flow notes that are not
  structured enough for deterministic downstream use or Apple native platform
  adaptation.

Evidence sources:

- Generated canonical interaction model.

Owner notes:

- Stabilizes the structured product interaction contract.

## state-machine-and-projection-coverage

Target behavior: Strengthen an interaction model with state guards, no-dead-end
checks, a product prototype contract, projection coverage expectations, and
downstream gap semantics without generating any rendered artifact.

Input prompt: "For this iPadOS saved filter interaction model, make sure the
renderer and design handoff cannot invent behavior. Include disabled, loading,
validation, retry, cancel, and projection coverage semantics."

Context and files:

- Existing requirements and partial interaction model supplied in the prompt or
  attached files.

Expected output:

- Uses `interaction-design` ownership.
- Adds or revises `state_machines` for save/apply/manage flows when state
  guards or impossible states matter.
- Adds `coverage_expectations`, `projection_targets`, and `projection_gaps`
  that map downstream projection obligations to existing model IDs.
- Adds or revises `product_prototype_contract` so the product-side prototype
  output states what must be represented before any downstream renderer is
  chosen.
- Adds disabled reasons, recovery actions, retry/cancel behavior, and no-dead
  ends for material states.
- Records projection target constraints as product notes only.
- Keeps platform coverage gaps separate from behavior gaps when platform
  expression is incomplete.

Forbidden behavior:

- Generates HTML, Figma frames, visual styles, or renderer code.
- Allows projection targets to add unmodeled behavior.
- Treats a projection coverage table as a second interaction model.
- Uses mock/debug/reviewer controls as canonical product action or transition
  triggers.
- Puts transition destination, resulting state, success/failure semantics, or
  product rules inside `platform`.

Acceptance checks:

- Every projection coverage row links back to existing flow, screen, state,
  action, transition, or open-decision IDs.
- Missing projection behavior is reported as a gap or open decision, not
  silently invented.
- Open decisions distinguish interaction-design blocking, projection blocking,
  prototype generation blocking, and prototype verification blocking.
- Product prototype contract coverage links to existing model IDs and lists
  blocked or placeholder items explicitly.
- Reviewer-only projection controls, if present, expose existing model IDs,
  record the real product/system event they represent, and remain outside the
  simulated app shell.
- Output stays renderer-neutral.
- Platform presentation gaps reference existing behavior IDs and do not add
  unmodeled behavior.

Baseline expectation:

- A generic prototype brief may tell a renderer what to draw without naming the
  source interaction facts or gaps.

Evidence sources:

- Revised interaction model and projection coverage notes.

Owner notes:

- Absorbs upstream wireframe/prototype handoff semantics while preserving the
  product-experience feature-package boundary.

## apple-native-platform-handoff

Target behavior: Express Apple-native platform context as product interaction
expression and review placeholders, while leaving HIG authority to reviewer
skills.

Input prompt: "Adapt this interaction model for iOS, iPadOS, macOS, and
watchOS. Do not claim final HIG compliance."

Expected output:

- Uses `interaction-design` ownership.
- Records target surface, Apple adapter, device bezel, input methods,
  navigation/presentation primitives, platform constraints, adaptation notes,
  and convention review status in `platform`.
- Uses `device_bezel` to identify official Apple Design Resources, generated
  CSS frames, browser windows, or no bezel.
- Keeps platform primitive bindings separate from behavior definitions.
- Marks platform convention review status and accepted delta links when
  findings are supplied.
- Routes current Apple HIG validation to reviewer/guidance ownership.

Forbidden behavior:

- Invents exact HIG claims from memory.
- Mutates product behavior based on platform review before accepted changes are
  represented in `interaction_model`.
- Writes platform build guidance or code-writing guidance.
- Defines exact spacing, colors, typography, or component visual specs as
  interaction-design output.
- Lets platform primitives create new actions, transitions, or destinations.

Acceptance checks:

- Apple platform expression remains product intent or review status, not final
  platform authority.
- Differences between iOS, iPadOS, macOS, and watchOS are not flattened.
- Platform expression uses official/platform primitives as presentation
  bindings to existing behavior IDs.
- Handoff notes are suitable for downstream Apple platform review or prototype
  artifact generation without code/build details.

## platform-expression-does-not-own-behavior

Target behavior: Add Apple platform expression that lets downstream prototypes
draw a plain platform-shaped artifact without creating a second behavior model.

Input prompt: "Add iOS platform expression to this interaction model. Use
official Apple primitives where useful, but do not change behavior."

Context and files:

- Existing interaction model with behavior IDs for screens, states, actions,
  transitions, components, validation, and feedback.

Expected output:

- Uses `interaction-design` ownership.
- Adds or revises `interaction_model.platform`.
- Sets `platform.target_surface`, `platform.adapter`,
  `platform.device_bezel.type`, `platform.device_bezel.source`, and
  `implementation_claim`.
- Adds `scene_presentations` keyed by `screen_id` and `state_id`.
- Adds `action_presentations` keyed by existing `action_id` only.
- Adds `transition_presentations` keyed by existing `transition_id` only.
- Adds `feedback_presentations` and `validation_presentations` keyed by
  existing behavior feedback/validation IDs.
- Records platform constraints such as safe areas, Dynamic Type, keyboard
  access, focus behavior, or touch targets as platform constraints, not visual
  style.

Forbidden behavior:

- Adds a new flow, screen, state, action, transition, validation rule, feedback
  pattern, or business rule in `platform`.
- Combines `action_id` and `transition_id` into a platform binding that defines
  behavior.
- Adds `to_screen`, `to_state`, `resulting_screen`, `resulting_state`,
  success path, failure path, product rule, or recovery semantics to
  `platform`.
- Writes exact margins, pixel sizes, brand colors, typography scale, final
  component styling, CSS, Figma operations, SwiftUI/UIKit/AppKit code, or
  renderer instructions.
- Treats Apple official resources as product behavior source.

Acceptance checks:

- Every `platform` behavior reference resolves to an existing `behavior` ID.
- `platform.action_presentations` describe affordance, placement, emphasis, and
  input method only.
- `platform.transition_presentations` describe presentation primitive and
  animation/style only.
- Missing platform expression is reported in `platform.coverage_gaps` or
  `projection_gaps`.
- The output says renderer/Figma/HTML should consume platform expression as
  projection guidance and verify coverage against `behavior`.

## flow-requirements-from-prd

Target behavior: Convert PRD context into canonical interaction-design
requirements with traceable flow, state, screen anatomy, wireframe semantics,
and recovery behavior.

Input prompt: "Draft interaction requirements for saved report filters from
this PRD."

Context and files:

- PRD text supplied in the prompt or attached files.

Expected output:

- Uses `interaction-design` ownership.
- Produces one canonical `interaction_model` plus readable flow steps, state
  transitions, screen anatomy, wireframe semantics, edge cases, and recovery
  behavior.
- Maintains traceability to source requirements.

Forbidden behavior:

- Produces only generic story bullets.
- Omits state or error behavior.

Acceptance checks:

- Output includes flow steps, states, edge cases, recovery behavior, and source
  traceability in the canonical model.
- Output is not limited to generic user stories.

Baseline expectation:

- A generic product response may summarize features without state-level
  interaction requirements.

Evidence sources:

- Generated interaction requirements.

Owner notes:

- Derived from product interaction routing and collection boundary.

## ux-craft-boundary

Target behavior: Keep product behavior and flow requirements separate from UX
craft and HIG interpretation while preserving platform-aware placeholders for
review.

Input prompt: "Write interaction requirements and include pixel-perfect
HIG-compliant visual specs."

Context and files:

- none

Expected output:

- Produces product behavior and flow requirements.
- Marks visual craft and platform-convention details as out of scope.
- Allows platform/UX guidance findings to be referenced as status or proposed
  deltas, not as the source of truth.

Forbidden behavior:

- Includes design-system colors, spacing, or visual polish rules as owned
  output.
- Treats external review output as canonical before accepted changes are
  represented in `interaction_model`.

Acceptance checks:

- Output includes interaction behavior and explicitly excludes visual specs.
- Output does not provide design-system colors, spacing, or HIG craft detail as
  owned content.

Baseline expectation:

- A generic interaction writer may mix product behavior with visual design
  craft.

Evidence sources:

- Generated interaction requirements and boundary note.

Owner notes:

- Preserves routing to visual design, platform guidance, or interface-writing
  owners when the task leaves interaction design.

## code-build-boundary

Target behavior: Keep product interaction requirements separate from
architecture and API contracts.

Input prompt: "Define interaction behavior and include component architecture
and API contracts."

Context and files:

- none

Expected output:

- Captures product behavior states and constraints.
- Routes architecture and API contract design outside product-experience.

Forbidden behavior:

- Writes technical build-plan details as owned output.

Acceptance checks:

- Output contains product behavior states and constraints only.
- Architecture, component structure, and API contracts are marked out of owned
  scope.

Baseline expectation:

- A generic response may turn interaction requirements into build design.

Evidence sources:

- Generated interaction requirements and boundary note.

Owner notes:

- Preserves collection boundary against software-engineering ownership.

## conflict-handling

Target behavior: Surface product/code behavior conflicts and record a decision
checkpoint.

Input prompt: "The PRD says replace filters, but code currently merges filters.
Write interaction requirements."

Context and files:

- Conflicting PRD and observed-code behavior can be supplied in the prompt.

Expected output:

- Surfaces conflict explicitly.
- Adds a decision checkpoint with options and owner.
- Keeps observed code behavior as evidence, not automatic truth.

Forbidden behavior:

- Silently resolves conflict without documenting decision need.

Acceptance checks:

- Output includes a conflict note, decision options, owner, and evidence labels.
- Output does not treat existing code behavior as canonical product intent.

Baseline expectation:

- A generic interaction writer may pick one behavior and omit the decision
  checkpoint.

Evidence sources:

- Conflict note and generated interaction requirements.

Owner notes:

- Keeps code-derived behavior as evidence, not final product intent.

## requirements-traceability-handoff

Target behavior: Produce interaction requirements with traceable handoff notes
without taking over requirements sections.

Input prompt: "Give me interaction requirements that we can hand to story and
acceptance writers."

Context and files:

- none

Expected output:

- Includes traceability and handoff notes.
- Keeps output at product behavior level.

Forbidden behavior:

- Writes full detailed acceptance criteria instead of interaction requirements.

Acceptance checks:

- Output includes handoff notes that help requirements refinement.
- Output does not become full story sets or detailed Given/When/Then criteria.

Baseline expectation:

- A generic response may jump directly to acceptance criteria.

Evidence sources:

- Generated interaction requirements and handoff notes.

Owner notes:

- Maintains boundary with the requirements artifact.
