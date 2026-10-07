# Origami Studio Research Report

## Research Scope

This report records Origami Studio facts for the `interaction-design` research
corpus. It is facts-first app research and does not define the final local
Interaction Design Schema or UI Design Schema.

Origami is studied as a patch/signal graph prototyping system: how it models
layers, patches, ports, connections, components, signals, animation, logic, and
runtime-like bindings.

## Product Positioning

Origami Studio is a visual prototyping tool built around patch graphs. Its
primary value for this research is not screen-flow navigation; it is signal
flow, patch composition, input/output ports, layer property binding, continuous
interaction, and reusable component boundaries.

Origami is a specialized interaction-logic and runtime-binding donor. It is not
the primary authority for product requirements, business logic, or high-level
app information architecture.

## Mature Workflow Shape

A mature Origami workflow usually looks like:

1. Create or import layers.
2. Add patches for interaction, animation, logic, data, device, or rendering
   behavior.
3. Connect patch output ports to input ports with cables.
4. Bind patch values to layer properties.
5. Group patches and layers into reusable components.
6. Publish component inputs and outputs.
7. Preview the prototype and tune signal behavior.

The mature shape is a graph of signals and transformations, not a linear list
of pages or screens.

## Evidence Inventory

Official evidence:

- Origami docs: https://origami.design/documentation/
- Releases/download page: https://origami.design/releases
- JavaScript Patch API:
  https://origami.design/documentation/concepts/scriptingapi

Local artifact/probe inventory, not source references:

- Local official artifacts:
  `references/research/artifacts/origami/`
- App-bundle examples/templates/manifests:
  `references/research/artifacts/origami/app-bundle/`

The app-bundle artifact directory includes official examples such as interaction
touch/drag/scroll/keyboard/hover/pinch/swipe, navigation transition/grid/side,
animation states/conditions/scrubbing/time, logic condition/switch/counter/math,
loop patterns, layers, and components.

## Schema Facts

Field-level facts to preserve for later schema work:

- Surface/context: document/composition and layer tree.
- Actor: layer, patch, component, input port, output port, or published port.
- Patch graph: patches connected by cables / connections.
- Signal: value flowing through ports and connections.
- Input: interaction patches for touch, drag, hover, keyboard, pinch, scroll,
  and swipe.
- Logic: condition, switch, math, counter, loop, option, random, and transform
  patch categories.
- Animation: time, delay, repeating, trail, scrubbing, and animation-state
  patch categories.
- Runtime binding: components expose published inputs/outputs; ports are useful
  evidence for runtime-binding schema fields.

## File / API / Artifact Model

Observed and documented object classes:

- document
- layer
- patch
- input port
- output port
- connection / cable
- signal value
- patch group
- component
- published component input
- published component output
- layer property binding
- interaction patch
- animation patch
- logic patch
- data/API patch
- device/input patch
- template and example manifests

Research interpretation:

- Patches are behavior/effect nodes.
- Ports are typed connection points.
- Connections carry values.
- Components are reusable boundaries around patch/layer structures.
- Layer bindings make graph output visible.

## Interaction Model

Origami's interaction model is graph/signal oriented:

- user or system input enters through interaction patches
- patch outputs emit changing signal values
- cables connect outputs to inputs
- logic patches transform or gate values
- animation patches smooth, interpolate, or time values
- data/API patches can represent external values
- layer/property bindings project signal values into visible prototype changes

This differs from Figma-style `trigger + action` or Flinto-style
`screen + link + transition`.

Origami is especially useful for:

- continuous interactions
- drag/scroll/pinch/hover/touch signals
- signal transformation
- runtime binding
- component input/output contracts
- graph-based cause/effect chains

It is less useful as a direct source for product IA, acceptance criteria,
business rules, or canonical product flows.

## UI Layer Model

Origami's UI layer is layer-and-binding based:

- layers are visual objects
- layer properties can be driven by patch outputs
- components can contain layers and patches
- templates can represent platform or device surfaces
- preview renders the resulting graph-driven prototype

Origami has UI layer evidence, but it is not a design-system schema like Figma
or Sketch. It is more useful for the relationship between visual objects and
runtime signal bindings.

## State / Variable / Logic Model

Origami state and logic are expressed through graph values:

- ports carry values
- logic patches compute conditions and branches
- switch/state-like patches can hold or select state
- loop patches repeat or aggregate values
- data/API patches represent external runtime inputs
- components publish inputs/outputs to define reusable interfaces

The important fact is that behavior can be modeled as a dataflow graph instead
of only as discrete screen transitions.

## Motion / Animation Model

Origami is strong for runtime-like animation behavior:

- time-based animation patches
- delay/repeating/scrubbing/trail patterns
- transition and navigation examples
- physics/continuous value transformations
- property-level animation through layer bindings

This is useful for later motion/runtime modeling, especially where gesture or
scroll position continuously drives visual state.

## Preview / Runtime / Handoff Model

Origami handoff is prototype-preview oriented:

- the `.origami` document contains layers and patch graphs
- app-bundle examples and templates demonstrate reusable graph patterns
- preview evaluates signal flow and renders layer bindings
- JavaScript patches provide a scripting/API extension point

Origami does not provide the same production runtime handoff as Rive `.riv`.
Its value is the authoring model for graph-based interaction behavior.

## Confirmed / Inferred / Unknown

Confirmed:

- Official docs cover patches, ports, components, and scripting APIs.
- Local official app-bundle examples and templates are available.
- Official examples cover interaction, navigation, layer, logic, loop,
  component, and animation categories.

Inferred:

- Patch graph concepts map cleanly to local candidate fields for runtime
  binding, signal flow, component ports, and continuous interaction.

Unknown:

- Complete serialized `.origami` field coverage has not been promoted into this
  report.
- Exact stability of internal app-bundle example serialization is not evaluated
  as a public schema contract.

## Useful Later

Potentially useful for local schema work:

- `patch_graph`
- `node`
- `input_port`
- `output_port`
- `connection`
- `signal`
- `component_input`
- `component_output`
- `runtime_binding`
- `layer_property_binding`
- continuous input modeling
- graph evidence for separating trigger/action from signal-flow response

These facts should be synthesized later. They should not be copied directly as
the local interaction model.

## Do Not Absorb

- Do not make patch graphs the default product behavior model.
- Do not require low-level signal wiring for ordinary product flows.
- Do not treat Origami editor graph layout as local schema.
- Do not use Origami layer bindings as product source of truth.
- Do not let runtime/signal details replace requirements traceability.
