# dotLottie / LottieFiles State Machine Research Report

## Research Scope

This report records dotLottie and LottieFiles state-machine facts for the
`interaction-design` research corpus. It is facts-first and does not define the
final local Interaction Design Schema or UI Design Schema.

dotLottie is studied as an open package/spec system for animation playback and
state-machine-driven runtime behavior.

## Product Positioning

dotLottie is an open package format for Lottie animations. It packages one or
more animations with manifests, assets, themes, metadata, and runtime
configuration.

For this research, dotLottie is important because it offers a formal, open
state-machine/package reference. Unlike private app formats, it can be cited as
a public spec authority for state machines, states, transitions, guards,
inputs/events, and playback actions.

dotLottie is not a general product-flow tool and not a full UI layout system.

## Mature Workflow Shape

A mature dotLottie workflow centers on:

1. Prepare one or more Lottie animations.
2. Package animations, assets, themes, and metadata into a `.lottie` package.
3. Define manifest-level configuration.
4. Define state machines where interactive playback is needed.
5. Define states, transitions, guards, inputs/events, and actions.
6. Load the package in a runtime.
7. Drive animation playback through runtime input and state-machine behavior.

The workflow is closer to animation runtime packaging than to product
requirements, screen design, or app information architecture.

## Evidence Inventory

Official evidence:

- dotLottie v2 spec: https://dotlottie.io/spec/2.0/
- dotLottie docs root: https://dotlottie.io/
- LottieFiles / dotLottie player ecosystem:
  https://lottiefiles.com/

## Schema Facts

Field-level facts to preserve for later schema work:

- Package: dotLottie package with manifest, animations, themes, assets, and
  state-machine definitions.
- Surface/runtime target: animation reference within the package.
- State machine: explicit state-machine object.
- State: named state in the machine.
- Transition: state-to-state transition.
- Condition/guard: guard or condition attached to a transition.
- Input/event: state-machine inputs and interaction events.
- Action/response: playback action or state-machine action.
- Runtime/projection: player/runtime consumes package and state-machine data.

## File / API / Artifact Model

Formal package concepts include:

- dotLottie package
- manifest
- animation entries
- assets
- themes
- metadata
- state machines
- states
- transitions
- guards / conditions
- inputs / events
- actions
- playback actions

Research interpretation:

- The package is an artifact container.
- The manifest is a package-level descriptor.
- Animations are playback resources.
- State machines define runtime behavior over animation resources.
- Guards and conditions control transition eligibility.
- Actions drive playback or runtime effects.

## Interaction Model

dotLottie's interaction model is state-machine oriented:

- A state machine owns states.
- Transitions connect states.
- Guards/conditions determine whether transitions can fire.
- Inputs/events are transition drivers.
- Actions are runtime/playback effects.
- Animation playback is the visible result of state-machine behavior.

This is useful because it cleanly separates:

- state
- transition
- guard/condition
- input/event
- action/effect

It does not provide a rich product-flow model such as user goals, scenarios,
requirements traceability, business rules, or recovery policy.

## UI Layer Model

dotLottie's UI layer is animation-asset oriented.

It has:

- animation surfaces
- packaged assets
- themes
- playback contexts
- runtime integration points

It does not model:

- screens
- navigation hierarchy
- forms
- app layout regions
- component systems
- native platform primitives

For local research, dotLottie should inform animation/runtime projection fields,
not product screen or UI-layout fields.

## State / Variable / Logic Model

dotLottie is strong for formal state-machine grammar:

- states
- transitions
- guards
- conditions
- inputs/events
- actions
- playback behavior

It is weaker for:

- business validation
- permission flows
- data modeling
- product requirements
- traceability to PRD or acceptance criteria

The useful distinction is that state-machine logic can be formal without being
complete product logic.

## Motion / Runtime / Handoff Model

dotLottie is primarily a runtime/package handoff system:

- package animation assets
- load package in a player/runtime
- drive playback through state-machine behavior
- use open package/spec semantics for portability

This makes it one of the cleanest references for a projection artifact that is
runtime-readable but not a product source of truth.

## Confirmed / Inferred / Unknown

Confirmed:

- dotLottie v2 is a public, formal package/spec reference.
- State-machine concepts are explicitly part of the formal model.
- dotLottie is open enough to serve as stronger evidence than private binary
  prototype formats for state-machine terminology.

Inferred:

- Its guard/action/input terminology can anchor local state-machine field names,
  but product-level semantics must be added outside dotLottie.

Unknown:

- Runtime-specific edge behavior for every dotLottie player implementation.
- Whether future dotLottie revisions will expand interaction semantics beyond
  animation playback.

## Useful Later

Potentially useful for local schema work:

- formal `state_machine` container
- `state`
- `transition`
- `guard`
- `condition`
- `input`
- `event`
- `action`
- `playback_action`
- open spec evidence grading
- package-vs-source distinction for projection artifacts

These facts should be synthesized later with Figma, Flinto, ProtoPie, Rive,
Origami, Axure, and other app reports before becoming local schema.

## Do Not Absorb

- Do not treat animation package structure as full product behavior.
- Do not treat playback actions as business logic.
- Do not copy Lottie-specific animation assumptions into UI-layer schema.
- Do not use dotLottie as evidence for screen navigation, app IA, or native
  platform expression.
- Do not let runtime animation artifacts become product sources of truth.
