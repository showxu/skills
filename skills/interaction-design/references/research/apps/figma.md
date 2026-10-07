# Figma Research Report

## Product Positioning

Figma is the mainstream collaborative design, UI-system, and prototype
platform. For this research, Figma is both:

- a UI-layer reference for files, pages, frames, nodes, components, variants,
  variables, styles, auto layout, constraints, and visual assets
- an interaction reference for prototype reactions, triggers, actions,
  navigation, overlays, scroll-to behavior, component changes, variables,
  conditional actions, and transition presentation

Figma is not the product behavior source for this repository. It is a mature
reference system whose public REST and Plugin API contracts can inform the
local interaction and UI-layer schemas.

## Mature Workflow Shape

Figma's mature workflow is canvas-first, collaborative, and component-driven:

1. Designers organize work into files, pages, sections, frames, and component
   libraries.
2. UI surfaces are built from nodes, groups, auto-layout frames, components,
   component sets, instances, variants, styles, variables, and assets.
3. Prototype behavior is attached to nodes through `reactions`.
4. A reaction combines a trigger with one or more actions.
5. Actions can navigate, swap, show overlays, scroll to nodes, change variants,
   set variables, set variable modes, run conditional branches, or control
   media.
6. Transitions describe how navigation or state changes are presented in the
   prototype preview.
7. Developer handoff and automation happen through Inspect/Dev Mode, REST API,
   Plugin API, MCP, Code Connect, exports, and third-party tooling.

The workflow is strong at design-system composition and prototype presentation.
It is weaker at product-level semantics such as business rules, recovery policy,
requirements traceability, and open-decision blocking semantics.

## Evidence Inventory

Official schema authority:

- Figma developer docs: https://developers.figma.com/docs/
- REST API docs: https://developers.figma.com/docs/rest-api/
- REST file endpoints: https://developers.figma.com/docs/rest-api/file-endpoints/
- REST file node types: https://developers.figma.com/docs/rest-api/file-node-types
- REST component/style types:
  https://developers.figma.com/docs/rest-api/component-types/
- Plugin API docs: https://developers.figma.com/docs/plugins/
- Plugin `Reaction` API:
  https://developers.figma.com/docs/plugins/api/Reaction/
- Plugin `Trigger` API:
  https://developers.figma.com/docs/plugins/api/Trigger/
- Plugin `Action` API:
  https://www.figma.com/plugin-docs/api/Action/
- Plugin `Transition` API:
  https://developers.figma.com/docs/plugins/api/Transition/
- Plugin node `reactions` property:
  https://developers.figma.com/docs/plugins/api/properties/nodes-reactions/
- Plugin `ComponentProperties` API:
  https://developers.figma.com/docs/plugins/api/ComponentProperties/
- Figma MCP server guide:
  https://github.com/figma/mcp-server-guide
- Figma MCP Help Center guide:
  https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server

Local artifact/probe inventory, not source references:

- Local `.fig` artifact:
  `references/research/artifacts/figma/local-export/ios-ipados-26-community.fig`

Evidence priority:

1. Official REST and Plugin API docs are schema authority.
2. Local `.fig` package probes are private-format evidence only.
3. Figma MCP is a file/tooling helper, not schema authority.

## Schema Facts

Field-level facts to preserve for later schema work:

- Surface / UI tree: `File`, `Document`, `Canvas`, `Section`, `Frame`,
  `Group`, `Node`, `Component`, `ComponentSet`, `Instance`, variables, styles,
  and export settings.
- Actor: a supported node can own prototype behavior through `node.reactions`.
- Trigger: click/tap, hover, press, drag, mouse enter/leave/down/up, timeout,
  key/gamepad input, media hit, and media end.
- Action: back, close, open URL, media control, set variable, set variable
  mode, conditional action blocks, and node actions.
- Node action: `NAVIGATE`, `SWAP`, `OVERLAY`, `SCROLL_TO`, and `CHANGE_TO`.
- Transition / presentation: instant, dissolve, smart animate, scroll animate,
  move, push, slide, direction, duration, easing, cubic bezier, and spring.
- State / variable: component variants, component properties, variables,
  variable modes, conditional actions, overlay visibility, scroll position,
  media runtime state, and interactive component reset behavior.
- Local artifact facts: `.fig` export is a ZIP package with `canvas.fig`,
  `thumbnail.png`, `meta.json`, and image assets; the probed binary dictionary
  exposes field-name signals such as `NavigationType`, `TransitionInfo`,
  `TransitionType`, `PrototypeDevice`, `prototypeInteractions`,
  `OverlayPositionType`, and `scrollDirection`.

## File / API / Artifact Model

Official public structure:

- `File`: file key, document tree, components, component sets, styles,
  variables, branches, versions, metadata, and exports
- `Document`: root node of the file tree
- `Canvas`: page-level surface under the document
- `Node`: typed canvas object with ID, name, type, visibility, layout,
  children, geometry, fills, strokes, effects, constraints, component data, and
  prototype interaction fields
- `Frame`: screen, container, or component surface; may have layout,
  constraints, scroll behavior, prototype interaction fields, and children
- `Section`: organizational canvas grouping
- `Group` / `TransformGroup`: grouped node structure
- `Component`: reusable component source
- `ComponentSet`: variant family
- `Instance`: component usage with overrides and component properties
- `Variables` / `VariableCollections`: typed values, modes, aliases, and
  bindings
- `Styles`: reusable paint, text, effect, and grid styles
- `ExportSettings`: asset output metadata
- `PrototypeDevice` and flow start points: preview context and prototype entry
  points

REST node types expose visual and layout fields such as bounds, transforms,
constraints, fills, strokes, effects, export settings, styles, and component
metadata. They also expose legacy or compatibility prototype fields such as
`transitionNodeID`, `transitionDuration`, and `transitionEasing`.

Plugin API exposes richer current prototype behavior through `node.reactions`.

Local `.fig` export facts:

- the local `.fig` export is a ZIP package with `canvas.fig`, `meta.json`,
  `thumbnail.png`, and image assets
- `canvas.fig` contains private binary canvas data
- a decompressed stream exposed field-name/type signals such as
  `NavigationType`, `TransitionInfo`, `TransitionType`, `PrototypeDevice`,
  `prototypeInteractions`, `OverlayPositionType`, `scrollDirection`,
  `layoutSize`, and constraint names
- this confirms broad package shape and vocabulary alignment but does not make
  the private file format a stable contract

## Interaction Model

Figma's public interaction model is reaction-based:

```text
Reaction = Trigger + Action[]
```

Confirmed concepts:

- `node.reactions` attaches prototype behavior to supported node types.
- `Reaction.trigger` describes how behavior starts.
- `Reaction.actions` describes what happens after the trigger.
- The older singular `action` field is deprecated in favor of `actions[]`.
- A valid set reaction requires a trigger and a non-empty action list.

Trigger model:

- click / tap-style trigger
- hover
- press
- drag
- mouse enter / mouse leave
- mouse down / mouse up
- timeout / delay
- keyboard / gamepad input
- media hit
- media end

Action model:

- back
- close
- open URL
- media control
- set variable
- set variable mode
- conditional action blocks
- node action

Node action navigation/presentation model:

- `NAVIGATE`: move to another frame or node destination
- `SWAP`: replace current surface
- `OVERLAY`: present overlay content
- `SCROLL_TO`: scroll to a target node
- `CHANGE_TO`: change an interactive component or variant target

Action fields can include destination IDs, transitions, preserve-scroll flags,
overlay relative position, reset video position, reset scroll position, and
reset interactive component behavior.

## UI Layer Model

Figma is a strong UI-layer reference. Relevant confirmed UI-layer concepts:

- file, document, canvas/page, section, frame, group, node
- component, component set, instance
- variants and component properties
- text, vector, image, shape, slice, connector, and table-like nodes
- auto layout, layout grow, layout align, constraints, absolute bounds,
  render bounds, transforms, scroll behavior
- styles for paint, text, effects, and grids
- variables and variable bindings
- fills, strokes, stroke caps/joins/dashes, effects, opacity, blend mode
- masks and boolean operations
- export settings and asset references

UI-layer objects become product behavior only when connected to accepted
product facts or prototype interactions. A frame or component hierarchy alone
is not a product behavior contract.

## State / Variable / Logic Model

Figma state is distributed across several systems:

- component variants and `CHANGE_TO` actions
- component properties and instance overrides
- variables, variable collections, modes, aliases, and bindings
- set-variable actions
- set-variable-mode actions
- conditional action blocks
- overlay visibility
- scroll position
- media runtime state
- interactive component reset behavior

Figma's variable and conditional model is useful for UI/prototype state, but it
does not replace product requirements, business rules, permissions, recovery
policy, or acceptance criteria.

## Motion / Runtime / Handoff Model

Figma transition presentation includes:

- instant transitions
- dissolve
- smart animate and match-layer behavior
- scroll animate
- move, push, and slide variants
- direction
- duration
- easing
- cubic bezier
- spring behavior

Runtime and handoff facts:

- Prototype preview is a rendered projection of design and interaction data.
- REST and Plugin APIs expose structured design/prototype data.
- MCP can read or update files and support code/design workflows, but MCP
  output is a tooling artifact, not the schema authority for this research.
- Dev Mode, Inspect, exports, Code Connect, and plugins support handoff, but
  they do not make implementation output the product source of truth.

## Confirmed / Inferred / Unknown

Confirmed:

- The public Plugin API exposes `Reaction`, `Trigger`, `Action`,
  `Navigation`, `Transition`, node `reactions`, `ComponentProperties`, and
  variables.
- REST file/node docs expose the file tree, node types, visual properties,
  component/style metadata, and prototype compatibility fields.
- The local `.fig` export is a ZIP package with private binary canvas data.
- Figma MCP is available as tooling but should not be treated as the schema
  authority.

Inferred:

- Private `.fig` field names align with public prototype/layout concepts, but
  values and complete semantics were not parsed.
- Complex Figma prototypes can be mapped into local trigger/action/transition
  vocabulary, but product-level traceability must be added locally.

Unknown:

- Same-file REST JSON for the local iOS/iPadOS 26 file was not retrieved.
- Exhaustive coverage of every REST node field is outside this app report.
- Full bidirectional importer/exporter compatibility is not proven.

## Useful Later

- `Reaction = trigger + actions[]` as a strong interaction object pattern
- multi-action reactions
- explicit trigger/action/transition separation
- navigation primitives: navigate, swap, overlay, scroll-to, change-to
- overlay presentation fields and reset/preserve flags
- variable, mode, and conditional-action taxonomy
- component/property/variant model for UI state and UI-layer parameters
- UI-layer object model: file/page/frame/node/component/variant/style/asset
- transition fields for projection-level motion
- separation between design file data, prototype preview, and implementation
  handoff

## Do Not Absorb

- private `.fig` binary fields as a stable local schema
- MCP output as schema authority
- Figma node tree as product behavior by default
- visual geometry, styles, or token values into the behavior DSL
- Figma implementation handoff as product truth
- Figma-specific field names where a local cross-tool concept is clearer
