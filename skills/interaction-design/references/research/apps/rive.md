# Rive Research Report

## Research Scope

This report records Rive facts for the `interaction-design` research corpus. It
does not define the local Interaction Design Schema or UI Design Schema and does
not change the active skill contract.

Rive is studied as an app/runtime system: what it is for, how mature work is
created, what public APIs and artifacts expose, and which facts may later inform
state-machine, runtime-binding, and interactive-animation fields.

## Product Positioning

Rive is an interactive animation and runtime state-machine platform. Its
strongest research value is runtime-grade interactivity: artboards, animations,
state machines, typed inputs, listeners, events, data binding, and host runtime
integration.

Rive is not a full product screen-flow tool. It is better understood as an
interactive visual runtime that can be embedded inside apps, games, websites,
and native interfaces.

## Mature Workflow Shape

A mature Rive workflow usually looks like:

1. Create one or more artboards.
2. Draw or import vector/object layers.
3. Create animation timelines.
4. Build one or more state machines.
5. Add boolean, number, and trigger inputs.
6. Define states, transitions, conditions, and listeners.
7. Optionally bind view-model or data-binding values.
8. Preview the interaction inside Rive.
9. Export `.riv` for runtime playback.
10. Use a host runtime to set inputs, listen for events, and render the
    animation.

Rive also supports editor backup/source export as `.rev`, but this round does
not have a local `.rev` artifact. That is not blocking for runtime state-machine
research because `.riv` is the runtime contract used by Rive runtimes.

## Evidence Inventory

Official and source evidence:

- Rive docs root: https://rive.app/docs/
- Runtime format docs:
  https://rive.app/docs/runtimes/advanced-topic/format
- Runtime export docs:
  https://rive.app/docs/editor/exporting/exporting-for-runtime
- Backup export docs:
  https://rive.app/docs/editor/exporting/exporting-for-backup
- State machine listener docs:
  https://rive.app/docs/editor/state-machine/listeners
- Runtime source: https://github.com/rive-app/rive-runtime

Local artifact/probe inventory, not source references:

- Runtime artifact: `references/research/artifacts/rive/vehicles.riv`
- Public runtime artifacts:
  `references/research/artifacts/rive/local-probe/*.riv`
- Runtime artifact manifest:
  `references/research/artifacts/rive/local-probe/download-manifest.json`

## Schema Facts

Field-level facts to preserve for later schema work:

- Runtime artifact: `.riv`.
- Editor/source artifact: `.rev` exists as backup/source export, but no local
  `.rev` sample is available in this round.
- Surface: artboard.
- Actor: visual/object layer or listener target.
- Animation: animation timeline or playback unit.
- State machine: named state machine with states and transitions.
- State: animation state or state-machine node.
- Transition: connection between state-machine states.
- Condition: transition condition.
- Input: boolean input, number input, and trigger input.
- Runtime binding: host runtime loads a file, selects artboard/state machine,
  sets inputs, and listens for events.
- Event: listener/event concepts connect runtime animation back to host logic.

## Local Public Runtime Artifacts

The public `.riv` artifact set contains runtime files from Rive Community and
Marketplace pages. These are browser-player runtime assets, not editable `.rev`
source files.

Covered artifact themes:

- minimal state-machine sample
- arcade on/off state machine
- power button state machine
- swipe/drop card gesture interaction
- avatar creator
- dark-mode switch
- switch/toggle variants
- multi-expression mascot
- additional character/wave interaction

The artifact manifest records source URL, local path, byte size, and SHA-256 for
each file. Local probing confirmed the `RIVE` magic header, which distinguishes
the artifacts from HTML error pages or download placeholders.

## File / API / Artifact Model

Important artifact classes:

- `.riv`: runtime export loaded by Rive runtimes. This is the confirmed artifact
  type for this round.
- `.rev`: editor backup/source export. This is useful for future editor-source
  research, but it is not required for v0 runtime/state-machine evidence.
- Rive runtime APIs: host APIs for loading a file, selecting artboards and state
  machines, setting inputs, and listening for events.
- Rive editor model: authoring concepts such as artboards, animations, state
  machines, data binding, and listeners. The authoring concepts are documented,
  but `.rev` serialization is not locally confirmed.

Runtime-oriented object model:

- file/runtime asset
- artboard
- animation
- state machine
- state
- transition
- input
- boolean input
- number input
- trigger input
- listener
- event
- view model / data binding
- runtime binding

## Interaction Model

Rive's interaction model is state-machine oriented.

Core facts:

- `Artboard` is the visual/runtime surface.
- `Animation` is a timeline or playback unit.
- `StateMachine` owns interactive runtime behavior.
- `State` represents a runtime animation or state-machine node.
- `Transition` connects states.
- Conditions determine whether a transition may fire.
- `Input` values drive the state machine from host code or user/runtime events.
- Boolean, number, and trigger inputs are first-class runtime controls.
- `Listener` and event concepts connect runtime events back to host logic.

For local Interaction Design Schema research, Rive is strongest where a product
behavior model needs to express:

- explicit state machines
- typed runtime inputs
- guarded transitions
- event emission
- runtime binding between host/product state and visual animation state

Rive is weaker for full product journeys, business rules, permissions, recovery
policy, form validation, and product traceability.

## UI Layer Model

Rive has a visual layer, but it is not a general app UI hierarchy in the same
sense as Figma, Sketch, Axure, or a native UI framework.

Rive UI-layer facts:

- artboards are visual containers
- vector/object layers form animated visual structure
- animations and state machines mutate visual properties
- listeners can target interactive visual areas
- view models and data binding can connect runtime data to visual output

Research boundary:

- Treat Rive visuals as interactive animation surfaces.
- Do not treat Rive artboards as canonical product screens by default.
- Do not treat Rive animation layers as product information architecture.
- Do not derive product behavior from animation internals unless the product
  source explicitly says the animation is the interaction surface.

## State / Variable / Logic Model

Confirmed state and logic concepts:

- named state machines
- states
- transitions
- transition conditions
- boolean inputs
- number inputs
- trigger inputs
- listeners
- events
- view model / data binding concepts

Research interpretation:

- Rive inputs are good evidence for a typed input model.
- Rive state machines are good evidence for separating state-machine mechanics
  from screen-flow navigation.
- Rive events are useful evidence for a runtime event/message model.
- Rive does not replace product requirements, business rules, or acceptance
  criteria.

## Motion / Animation Model

Rive is a primary motion/runtime donor.

Useful motion concepts:

- animation timelines
- animation states
- transitions between animation states
- input-driven state changes
- gesture/button/toggle micro-interactions in runtime artifacts
- runtime playback controlled by host state

The local schema should not copy Rive's animation internals as product behavior.
Instead, Rive supports the idea that product interaction can bind to a separate
runtime animation state machine.

## Preview / Runtime / Handoff Model

Rive's handoff is runtime-first:

- author in Rive
- export `.riv`
- load `.riv` in a host runtime
- choose artboard and state machine
- set input values
- handle events emitted by the animation

This is different from a static design handoff. Rive is valuable because the
runtime artifact is executable and host-controllable.

For local prototype research, `.riv` can be treated as a projection/runtime
artifact. It should not become the product source of truth.

## Confirmed / Inferred / Unknown

Confirmed:

- `.riv` runtime format and runtime APIs are officially documented.
- Public `.riv` artifacts were downloaded and locally validated.
- Rive exposes state-machine, input, listener, event, and runtime-binding
  concepts through docs and runtime APIs.
- Local app download inspection found no app-bundle samples; public runtime
  artifact capture is the useful evidence path for this round.

Inferred:

- `.rev` likely contains richer editor/source structure than `.riv`.
- `.rev` may help future editor/importer research, but the first-pass
  Interaction Design Schema does not need it.

Unknown:

- `.rev` serialized field names and editor-only metadata.
- Full editor data model beyond official docs and runtime-observable concepts.
- Edge behavior for all runtime implementations.

## Useful Later

Potentially useful for local schema work:

- `state_machine`
- `state`
- `transition`
- `condition`
- typed `input`
- `trigger_input`
- `boolean_input`
- `number_input`
- `listener`
- `event`
- `runtime_binding`
- `animation_binding`
- separation between product interaction state and animation runtime state

These are candidate facts only. They should be synthesized later with other app
reports before changing the active interaction model.

## Do Not Absorb

- Do not treat `.riv` as complete editor source.
- Do not infer `.rev` fields without a `.rev` sample or official source.
- Do not copy Rive animation internals into product behavior.
- Do not model every product screen as a Rive artboard.
- Do not treat Rive runtime events as product requirements.
- Do not make a Rive projection artifact a product source of truth.
