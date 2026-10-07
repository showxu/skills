# Principle Research Report

## Research Scope

This report records Principle facts for the `interaction-design` research
corpus. It is facts-first app research and does not define the final local
Interaction Design Schema or UI Design Schema.

Principle is studied as a motion/timeline/driver prototyping app. It is useful
for how a mature app represents animated transitions, artboard flows, layer
properties, scroll/drag drivers, preview, and share/export behavior.

## Product Positioning

Principle is a macOS prototyping tool focused on animated UI flows. It is most
valuable as a motion and timeline donor, not as a primary product-logic or
business-rule schema authority.

Its product shape is closer to "make static screens feel interactive and
animated" than "define complete application behavior." It complements Figma,
Sketch, and Flinto by emphasizing timelines, property animation, and drivers.

## Mature Workflow Shape

A mature Principle workflow usually looks like:

1. Import or create artboards and layers.
2. Connect artboards using events and transitions.
3. Animate layer properties between states or artboards.
4. Use drivers to bind scroll, drag, or input progress to property changes.
5. Use components for reusable animated pieces.
6. Preview the prototype in the Principle viewer.
7. Share or export a prototype artifact for review.

This workflow is useful for motion design and interaction preview, but it is
not a complete product source-of-truth system.

## Evidence Inventory

Official evidence:

- Principle docs: https://principle.app/docs.html
- Product page: https://principle.app/
- Gallery: https://principleformac.com/gallery.html
- Official download:
  https://www.principle.app/download/Principle.zip

Local artifact/probe inventory, not source references:

- Local app-bundle evidence:
  `references/research/artifacts/principle/app-bundle/`
- App-bundle files:
  - `web_principle.html`
  - `compatibility.json`
  - `SketchImport_2025.js`
  - `ref.boop`

No official `.prd` authoring sample was found locally in this round.

## Schema Facts

Field-level facts to preserve for later schema work:

- Document structure: document, artboard, layer, component, preview/share
  artifact.
- Actor: layer or component.
- Event: user or timeline event.
- Transition: screen/artboard transition.
- Animation: timeline, property animation, and key motion values.
- Driver: driver links interaction progress to animation values.
- Gesture/motion: drag interaction, scrollable layer, and screen-flow motion.
- Runtime/export: web export/runtime resources and import compatibility data are
  available in the app bundle.
- Artifact fact: no `.prd` authoring sample was found in this round.

## File / API / Artifact Model

Publicly useful concepts:

- document
- artboard
- layer
- event
- transition
- driver
- animation
- timeline
- property animation
- drag interaction
- scroll interaction
- component
- preview
- share/export artifact

Known artifact limitation:

- The `.prd` authoring format is not publicly specified in this research.
- Local app-bundle inspection found export/import/runtime resources but no
  authoring `.prd` sample.
- Therefore `.prd` field-level claims must remain blocked/deferred.

## Interaction Model

Principle's interaction model is motion-flow oriented:

- artboards are prototype surfaces
- layers are motion targets and interactive objects
- events trigger transitions or animations
- transitions connect artboards or visual states
- drivers map drag/scroll/input progress to property changes
- components provide reusable interaction/motion structures

Compared with Figma or Sketch, Principle places more emphasis on motion
behavior and less emphasis on a broad file/API ecosystem.

Compared with Flinto, Principle is useful for timeline and driver concepts but
is currently weaker as a locally probed private-file schema donor because no
`.prd` sample is available.

## UI Layer Model

Principle's UI layer is artboard/layer based:

- artboards define prototype surfaces
- layers define visual elements and animation targets
- imported Sketch/Figma-style designs can become prototype layers
- components can wrap reusable animated structures

This is sufficient for motion targets and screen-level preview, but not the
best evidence source for design tokens, variables, component variants, or full
UI design-system schema.

## State / Variable / Logic Model

Principle state is mostly visual and motion-derived:

- current artboard or component state
- drag/scroll progress
- driver value
- animated property values
- layer visibility or property state
- transition progress

Principle is weaker for:

- general formulas
- business logic
- rich variables
- conditions and cases
- form validation
- traceability to product requirements

For local research, it should not be treated as a product-logic donor.

## Motion / Animation Model

Principle is strongest here.

Useful motion facts:

- timelines
- property animation
- artboard-to-artboard animation
- driver-controlled motion
- drag-driven transitions
- scroll-driven property changes
- component-level animation reuse
- preview/share playback

Principle supports the idea that motion can be modeled as a first-class layer
between behavior intent and rendered prototype output.

## Preview / Runtime / Handoff Model

Principle is review/prototype oriented:

- preview allows interactive playback
- exported/share artifacts allow review outside the authoring canvas
- app-bundle files include web/export and Sketch import resources

It is not evidence for production implementation architecture. It is also not a
source-of-truth product model.

## Confirmed / Inferred / Unknown

Confirmed:

- Official docs cover events, transitions, animations, drivers, components,
  draggable and scrollable layers, preview, and export behavior.
- The local app bundle contains web/export and Sketch import resources.
- No `.prd` authoring sample was found in the downloaded app bundle.

Inferred:

- `.prd` likely stores artboards, layers, events, transitions, drivers, and
  animations, but field-level structure is not confirmed.

Unknown:

- `.prd` serialized field names.
- `.prd` enum values and internal object graph.
- Current field-level representation of drivers, timelines, components, and
  transitions.

## Useful Later

Potentially useful for local schema work:

- `timeline`
- `driver`
- `property_animation`
- `drag_progress`
- `scroll_progress`
- `motion_transition`
- `artboard_flow`
- motion intent separated from final visual styling
- review artifact versus source-of-truth distinction

These facts should be synthesized later with Figma, Sketch, Flinto, Origami,
Rive, and other app reports.

## Do Not Absorb

- Do not infer `.prd` fields without sample evidence.
- Do not make motion timelines core product behavior.
- Do not treat Principle preview/share output as product source of truth.
- Do not copy Principle timeline UI as local schema.
- Do not use Principle as a primary business-logic, condition, or validation
  donor.
