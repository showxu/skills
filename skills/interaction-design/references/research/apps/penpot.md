# Penpot Research Report

## Product Positioning

Penpot is an open-source design and prototyping platform for design and code
collaboration. It is valuable as an open design/prototype platform reference
because its product model is documented through public help docs and its source
repository is inspectable.

For this research round, Penpot is a secondary reference for open design-file,
board/shape, flow, overlay, and web-standards-aligned UI layer concepts. It is
not the strongest donor for advanced interaction logic, state machines, or
runtime animation.

## Mature Workflow Shape

Penpot workflows center on:

- creating files with pages, boards, layers, groups, shapes, text, components,
  and libraries
- using boards as screen-like surfaces for design and prototype preview
- adding interactions in Prototype mode by connecting layers, groups, shapes,
  or boards to destination boards
- defining one or more prototype flows through starting boards
- previewing and sharing prototypes in View mode
- organizing UI layout with Flex Layout and Grid Layout concepts that align
  with CSS Flexbox and CSS Grid
- using design tokens/styles for visual properties
- using plugins, exports, inspect/dev tools, and source-available deployment

## Evidence Inventory

- Official help center: https://help.penpot.app/
- Prototyping docs:
  https://help.penpot.app/user-guide/prototyping-testing/prototyping/
- View mode docs:
  https://help.penpot.app/user-guide/prototyping-testing/testing-view-mode/
- Workspace basics:
  https://help.penpot.app/user-guide/workspace-basics/
- Flexible layouts:
  https://help.penpot.app/user-guide/flexible-layouts/
- Design tokens:
  https://help.penpot.app/user-guide/design-systems/design-tokens/
- Plugin FAQ, including flow and interaction API references:
  https://help.penpot.app/plugins/faq/
- Public source repository: https://github.com/penpot/penpot

Historical input from the earlier root research pass exists, but this report
uses the official docs and public source as the factual authority.

## Schema Facts

Field-level facts to preserve for later schema work:

- File structure: file, page, board, shape, component, design token, export, and
  open package/source concepts.
- Surface: board or page-level canvas.
- Actor: shape, component, or interactive element.
- Prototype flow: flow and interaction concepts.
- Action/transition: prototype interaction can connect surfaces or alter
  presentation.
- UI-layer: shapes, components, tokens, exports, plugin/source model.
- Source availability: public source can be inspected for exact model details in
  a future adapter round.

## File / API / Artifact Model

Observed model areas from docs/source positioning:

- File
- Page
- Board
- Shape
- Layer
- Group
- Component
- Library
- Design token / style
- Prototype flow
- Interaction
- Plugin
- Export
- Inspect/dev handoff
- Public source repository

## Interaction Model

Penpot's documented prototype model is board-centric:

- Boards act as screens in prototypes.
- Interactions are created by selecting a triggering layer, shape, group, or
  board and connecting it to a destination board.
- A prototype connection has visible anatomy: hotspot/origin, connector wire,
  destination, interaction trigger, interaction action, interaction animation,
  and flow indicator.
- A flow is defined by a starting board. Multiple flows can exist in one page
  and can be selected in View mode.
- View mode plays interactions and supports navigation between boards.

Documented triggers:

- On click / tap.
- Mouse enter.
- Mouse leave.
- After delay, set at boards.

Documented actions:

- Navigate to.
- Open overlay.
- Toggle overlay.
- Close overlay.
- Previous screen.
- Open URL.

Overlay behavior includes:

- preset overlay positioning
- manual overlay positioning
- positioning relative to the triggering element
- close when clicking outside
- background overlay

Penpot is useful as an open baseline for surface/flow/overlay/navigation
semantics. It is less specialized than ProtoPie, Flinto, Axure, Rive, or Figma
for advanced trigger logic, runtime variables, gestures, state machines, and
micro-interaction semantics.

## UI Layer Model

Penpot is strong for open design UI structure and web-aligned layout:

- pages, boards, layers, groups, shapes, text, and components
- libraries and reusable components
- Flex Layout based on CSS Flexbox concepts
- Grid Layout based on CSS Grid concepts
- static and absolute positioning inside flexible layouts
- layout properties such as direction, align, justify, gap, padding, margin,
  sizing, rows, columns, areas, and z-index
- design tokens that can apply to properties such as color, dimensions,
  spacing, border radius, stroke width, typography, and other design values
- inspect/dev tools for measurements, properties, asset export, and code

This makes Penpot useful for a future UI layer schema, especially where the
local model needs web-standard layout vocabulary without depending on Figma's
private file format.

## State / Variable / Logic Model

Current official docs reviewed in this pass show weaker high-fidelity logic
than Axure, ProtoPie, UXPin, Rive, or dotLottie.

Confirmed state-like concepts:

- overlay open/closed presentation
- previous-screen navigation stack behavior
- delayed board transition
- fixed elements during scroll
- flow starting points

Not confirmed as strong interaction logic in this pass:

- prototype variables
- expression language
- guarded conditions
- rich component state machines
- data binding as prototype behavior

Treat Penpot state/logic as background unless a direct source-code review or
current API probe proves richer behavior.

## Motion / Runtime / Handoff Model

Penpot's documented prototype animations are transition-oriented:

- Dissolve, with easing and duration.
- Slide, with in/out direction, easing, duration, and offset effect.
- Push, with direction, easing, and duration.

Preview/runtime facts:

- View mode plays interactions.
- Prototype links can be shared.
- View mode shows boards and their contents; content outside a board is not
  shown.
- Fixed-scroll elements can be used for headers, navbars, and floating
  buttons.

Penpot is more important as an open design/prototype structure reference than
as a runtime animation or state-machine system.

## Confirmed / Inferred / Unknown

Confirmed:

- Penpot is a source-available/open-source design and prototype platform.
- Boards can act as prototype screens.
- Prototype interactions connect triggering layers/shapes/groups/boards to
  destination boards.
- Documented triggers include click/tap, mouse enter, mouse leave, and delay.
- Documented actions include navigation, overlay open/toggle/close, previous
  screen, and URL open.
- Documented animations include dissolve, slide, and push with timing options.
- Flex and Grid Layout are explicitly tied to CSS Flexbox and CSS Grid.
- Design tokens can be applied to visual properties and imported/exported.
- Plugin docs reference APIs for creating flows and adding/removing
  interactions.

Inferred:

- Penpot can anchor future open file/API model research if a local schema needs
  an inspectable alternative to private design file formats.
- Penpot's UI layer vocabulary can help normalize web-standard layout fields.

Unknown:

- exact internal source-level schema for interactions and flows
- full plugin API type shapes for `Flow` and `Interaction`
- whether current source has richer prototype logic than the reviewed docs
- import/export serialization details for interaction data

## Useful Later

- open source reference for files, pages, boards, layers, shapes, components,
  libraries, flows, and interactions
- board/surface and flow-start semantics
- overlay action semantics and overlay positioning fields
- web-standard Flex/Grid UI layer fields
- design token application to UI properties
- plugin/export/inspect model for future tooling

## Do Not Absorb

- Penpot implementation-specific internal data structures without direct
  source review.
- UI layout, token, or inspect fields as product behavior.
- Penpot's weaker interaction features as canonical when stronger interaction
  donors provide clearer semantics.
- Self-hosting, deployment, or product operations concepts into the interaction
  schema.
- Generated code or inspect output as source-of-truth interaction behavior.
